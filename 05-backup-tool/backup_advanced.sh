#!/bin/bash
# ============================================================================
# backup_advanced.sh — 高级备份脚本
# 功能: 配置文件、排除模式、校验验证、并行备份、文件锁
# ============================================================================

set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/lib.sh"

CONFIG_FILE=""
SOURCE_DIRS=()
DEST_DIR="/backup"
COMPRESS_TYPE="gzip"
KEEP_COUNT=7
BACKUP_MODE="incr"
EXCLUDES=()
NOTIFY_METHOD="log"
LOCK_FILE="/var/run/backup.lock"
VERIFY_BACKUP=false
TIMESTAMP=$(date '+%Y%m%d_%H%M%S')
TMPDIR=""
LOCK_FD=200

cleanup() {
    local exit_code=$?
    [[ -n "$TMPDIR" && -d "$TMPDIR" ]] && rm -rf "$TMPDIR"
    flock -u $LOCK_FD 2>/dev/null || true
    exit "$exit_code"
}
trap cleanup EXIT INT TERM

show_usage() {
    cat <<'EOF'
用法: backup_advanced.sh [选项]
  -f <文件>    配置文件
  -s <目录>    源目录（可多次使用）
  -d <目录>    目标目录
  -c <方式>    压缩: gzip|bzip2|xz|none
  -n <数量>    保留份数
  -V           备份后验证
  -v           详细输出
  -h           帮助
EOF
    exit 0
}

load_config() {
    local config="$1"
    [[ ! -f "$config" ]] && die "配置文件不存在: $config"
    log_info "加载配置: $config"
    while IFS='=' read -r key value; do
        [[ "$key" =~ ^[[:space:]]*# || -z "$key" ]] && continue
        key=$(echo "$key" | xargs); value=$(echo "$value" | xargs | tr -d '"' | tr -d "'")
        case "$key" in
            SOURCE_DIRS) read -ra SOURCE_DIRS <<< "$value" ;;
            DEST_DIR)      DEST_DIR="$value" ;;
            COMPRESS_TYPE) COMPRESS_TYPE="$value" ;;
            KEEP_COUNT)    KEEP_COUNT="$value" ;;
            BACKUP_MODE)   BACKUP_MODE="$value" ;;
        esac
    done < "$config"
}

backup_single() {
    local src="$1" dest="$2" exclude_file="$3"
    local name; name=$(basename "$src" | tr '/' '_')
    local snapshot="${dest}/.snapshot_${name}.snar"
    local type="incr"

    [[ "$BACKUP_MODE" == "full" || ! -f "$snapshot" ]] && { type="full"; rm -f "$snapshot"; }

    local ext
    case "$COMPRESS_TYPE" in gzip) ext=".tar.gz";; bzip2) ext=".tar.bz2";; xz) ext=".tar.xz";; *) ext=".tar";; esac
    local backup_file="${dest}/${name}_${type}_${TIMESTAMP}${ext}"

    log_info "备份: $src -> $backup_file ($type)"
    local start; start=$(date '+%s')

    local tar_cmd=(tar --listed-incremental="$snapshot")
    case "$COMPRESS_TYPE" in gzip) tar_cmd+=(-z);; bzip2) tar_cmd+=(-j);; xz) tar_cmd+=(-J);; esac
    [[ -f "$exclude_file" ]] && tar_cmd+=(-X "$exclude_file")
    tar_cmd+=(-cf "$backup_file" "$src")

    if "${tar_cmd[@]}" 2>/dev/null; then
        local elapsed=$(( $(date '+%s') - start ))
        local fsize; fsize=$(stat -c%s "$backup_file" 2>/dev/null || echo 0)
        log_info "完成: $(human_size "$fsize"), ${elapsed}s"

        [[ "$VERIFY_BACKUP" == true ]] && verify_backup "$backup_file"

        if command -v sha256sum &>/dev/null; then
            sha256sum "$backup_file" > "${backup_file}.sha256"
        fi
    else
        log_error "失败: $src"
        [[ -f "$backup_file" ]] && rm -f "$backup_file"
        return 1
    fi
}

verify_backup() {
    local file="$1"
    log_info "验证: $(basename "$file")"
    if tar -tf "$file" &>/dev/null; then
        local count; count=$(tar -tf "$file" | wc -l)
        log_info "验证通过: ${count} 个文件"
    else
        log_error "验证失败: 归档损坏"
        return 1
    fi
}

rotate_backups() {
    local dest="$1" name="$2" keep="$3"
    local backups=()
    while IFS= read -r -d '' f; do backups+=("$f"); done \
        < <(find "$dest" -maxdepth 1 -name "${name}_*" \( -name "*.tar.*" -o -name "*.tar" \) -print0 | sort -zr)
    local total=${#backups[@]}
    if ((total > keep)); then
        for ((i = keep; i < total; i++)); do
            log_info "轮转: $(basename "${backups[$i]}")"
            rm -f "${backups[$i]}" "${backups[$i]}.sha256" "${backups[$i]}.md5"
        done
    fi
}

send_notification() {
    local subject="$1" body="$2"
    case "$NOTIFY_METHOD" in
        log) log_info "通知: $subject - $body" ;;
        logger) logger -t "backup" "$subject: $body" ;;
    esac
}

acquire_lock() {
    exec $LOCK_FD>"$LOCK_FILE"
    flock -n $LOCK_FD || die "另一个实例在运行"
}

while getopts "f:s:d:c:n:Vvh" opt; do
    case "$opt" in
        f) CONFIG_FILE="$OPTARG" ;; s) SOURCE_DIRS+=("$OPTARG") ;;
        d) DEST_DIR="$OPTARG" ;;   c) COMPRESS_TYPE="$OPTARG" ;;
        n) KEEP_COUNT="$OPTARG" ;; V) VERIFY_BACKUP=true ;;
        v) VERBOSE=true ;;         h) show_usage ;;
        \?) die "无效选项: -$OPTARG" ;;
    esac
done
shift $((OPTIND - 1))

main() {
    [[ -n "$CONFIG_FILE" ]] && load_config "$CONFIG_FILE"
    [[ ${#SOURCE_DIRS[@]} -eq 0 ]] && die "未指定源目录"
    ensure_dir "$DEST_DIR"
    TMPDIR=$(mktemp -d)

    # 生成排除文件
    local exclude_file="${TMPDIR}/excludes.txt"
    if [[ ${#EXCLUDES[@]} -gt 0 ]]; then
        printf '%s\n' "${EXCLUDES[@]}" > "$exclude_file"
    fi

    acquire_lock
    log_info "高级备份开始: ${SOURCE_DIRS[*]} -> $DEST_DIR"

    local total_start; total_start=$(date '+%s')
    local pids=() names=() success=0 failed=0

    for src in "${SOURCE_DIRS[@]}"; do
        [[ ! -d "$src" ]] && { log_warn "跳过: $src"; ((failed++)); continue; }
        backup_single "$src" "$DEST_DIR" "$exclude_file" &
        pids+=($!)
        names+=("$(basename "$src")")
    done

    for i in "${!pids[@]}"; do
        if wait "${pids[$i]}"; then ((success++)); else ((failed++)); fi
    done

    for src in "${SOURCE_DIRS[@]}"; do
        rotate_backups "$DEST_DIR" "$(basename "$src" | tr '/' '_')" "$KEEP_COUNT"
    done

    local elapsed=$(( $(date '+%s') - total_start ))
    log_info "完成: 成功=${success} 失败=${failed} 耗时=${elapsed}秒"

    [[ $failed -gt 0 ]] && send_notification "[备份警告]" "失败: ${failed}" \
                         || send_notification "[备份完成]" "全部成功"
    [[ $failed -eq 0 ]]
}

main
