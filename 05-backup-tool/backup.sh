#!/bin/bash
# ============================================================================
# backup.sh — 基础备份脚本
# 支持全量/增量备份，getopts 参数解析，trap 清理
# ============================================================================

set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/lib.sh"

SOURCE_DIR=""
DEST_DIR=""
COMPRESS="gzip"
KEEP_COUNT=7
BACKUP_MODE="auto"
TIMESTAMP=$(date '+%Y%m%d_%H%M%S')
TMPDIR=""

cleanup() {
    local exit_code=$?
    [[ -n "$TMPDIR" && -d "$TMPDIR" ]] && rm -rf "$TMPDIR"
    exit "$exit_code"
}
trap cleanup EXIT
trap 'log_error "收到中断信号"; exit 130' INT TERM

show_usage() {
    cat <<'EOF'
用法: backup.sh [选项]
  -s <目录>   源目录（必需）
  -d <目录>   目标目录（必需）
  -c <方式>   压缩: gzip|bzip2|xz|none（默认: gzip）
  -n <数量>   保留份数（默认: 7）
  -m <模式>   模式: auto|full|incr（默认: auto）
  -v          详细输出
  -h          帮助
EOF
    exit 0
}

while getopts "s:d:c:n:m:vh" opt; do
    case "$opt" in
        s) SOURCE_DIR="$OPTARG" ;; d) DEST_DIR="$OPTARG" ;;
        c) COMPRESS="$OPTARG" ;;  n) KEEP_COUNT="$OPTARG" ;;
        m) BACKUP_MODE="$OPTARG" ;; v) VERBOSE=true ;;
        h) show_usage ;;
        \?) die "无效选项: -$OPTARG" ;;
        :)  die "选项 -$OPTARG 需要参数" ;;
    esac
done
shift $((OPTIND - 1))

[[ -z "$SOURCE_DIR" ]] && die "缺少 -s 源目录"
[[ -z "$DEST_DIR" ]] && die "缺少 -d 目标目录"
[[ ! -d "$SOURCE_DIR" ]] && die "源目录不存在: $SOURCE_DIR"

case "$COMPRESS" in gzip|bzip2|xz|none) ;; *) die "不支持的压缩: $COMPRESS" ;; esac
case "$BACKUP_MODE" in auto|full|incr) ;; *) die "不支持的模式: $BACKUP_MODE" ;; esac

ensure_dir "$DEST_DIR"
TMPDIR=$(mktemp -d)
LOG_FILE="${DEST_DIR}/backup.log"
check_command tar

get_compress_flag() { case "$1" in gzip) echo "-z";; bzip2) echo "-j";; xz) echo "-J";; none) echo "";; esac; }
get_compress_ext()  { case "$1" in gzip) echo ".tar.gz";; bzip2) echo ".tar.bz2";; xz) echo ".tar.xz";; none) echo ".tar";; esac; }

COMPRESS_FLAG=$(get_compress_flag "$COMPRESS")
COMPRESS_EXT=$(get_compress_ext "$COMPRESS")

do_backup() {
    local src="$1" dest="$2"
    local name; name=$(basename "$src" | tr '/' '_')
    local snapshot="${dest}/.snapshot_${name}.snar"
    local type="incr"

    if [[ "$BACKUP_MODE" == "full" ]] || { [[ "$BACKUP_MODE" != "incr" ]] && [[ ! -f "$snapshot" ]]; }; then
        type="full"
        [[ -f "$snapshot" ]] && rm -f "$snapshot"
    fi

    local backup_file="${dest}/${name}_${type}_${TIMESTAMP}${COMPRESS_EXT}"
    log_info "开始${type}备份: $src -> $backup_file"

    local start_time; start_time=$(date '+%s')
    local tar_cmd=(tar --listed-incremental="$snapshot")
    [[ -n "$COMPRESS_FLAG" ]] && tar_cmd+=($COMPRESS_FLAG)
    tar_cmd+=(-cf "$backup_file" "$src")

    if [[ "$VERBOSE" == true ]]; then
        "${tar_cmd[@]}"
    else
        "${tar_cmd[@]}" 2>/dev/null
    fi

    if [[ $? -eq 0 ]]; then
        local elapsed=$(( $(date '+%s') - start_time ))
        local fsize; fsize=$(stat -c%s "$backup_file" 2>/dev/null || echo 0)
        log_info "备份成功: $(human_size "$fsize"), ${elapsed}秒"
    else
        log_error "备份失败"
        [[ -f "$backup_file" ]] && rm -f "$backup_file"
        return 1
    fi
}

rotate_backups() {
    local dest="$1" name="$2" keep="$3"
    local backups=()
    while IFS= read -r -d '' f; do backups+=("$f"); done \
        < <(find "$dest" -maxdepth 1 -name "${name}_*" \( -name "*.tar.gz" -o -name "*.tar.bz2" -o -name "*.tar.xz" -o -name "*.tar" \) -print0 | sort -zr)
    local total=${#backups[@]}
    if ((total > keep)); then
        for ((i = keep; i < total; i++)); do
            log_info "轮转删除: $(basename "${backups[$i]}")"
            rm -f "${backups[$i]}" "${backups[$i]}.sha256"
        done
    fi
}

main() {
    log_info "========================================="
    log_info "备份开始: $SOURCE_DIR -> $DEST_DIR"
    log_info "压缩: $COMPRESS | 保留: $KEEP_COUNT | 模式: $BACKUP_MODE"
    log_info "========================================="

    do_backup "$SOURCE_DIR" "$DEST_DIR"

    local name; name=$(basename "$SOURCE_DIR" | tr '/' '_')
    rotate_backups "$DEST_DIR" "$name" "$KEEP_COUNT"

    log_info "备份完成!"
}

main
