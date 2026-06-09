#!/bin/bash
# =============================================================================
# organizer_advanced.sh — 文件整理器（高级版）
# 功能：按日期/大小整理、MD5去重、递归处理、撤销操作
# 用法：bash organizer_advanced.sh [选项] <目录>
# =============================================================================

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

# --- 配置 ---
MODE="type"    # type | date | size | dedup
DRY_RUN=false
VERBOSE=false
TARGET_DIR=""
LOG_FILE=""

declare -A EXT_MAP=(
    [jpg]="images" [jpeg]="images" [png]="images" [gif]="images"
    [bmp]="images" [svg]="images" [webp]="images"
    [pdf]="documents" [doc]="documents" [docx]="documents"
    [txt]="documents" [md]="documents" [csv]="documents"
    [xls]="documents" [xlsx]="documents" [ppt]="documents" [pptx]="documents"
    [mp4]="videos" [avi]="videos" [mkv]="videos" [mov]="videos"
    [mp3]="audio" [wav]="audio" [flac]="audio" [ogg]="audio"
    [zip]="archives" [tar]="archives" [gz]="archives"
    [rar]="archives" [7z]="archives"
    [sh]="code" [py]="code" [js]="code" [ts]="code"
    [html]="code" [css]="code" [json]="code"
)

show_help() {
    cat <<'EOF'
用法: organizer_advanced.sh [选项] <目录>

选项:
  --by-type    按文件类型整理（默认）
  --by-date    按日期整理（年/月结构）
  --by-size    按大小整理（small/medium/large）
  --dedup      查找并删除重复文件
  --undo       撤销上次操作
  --dry-run    预览模式
  -v           详细输出
  -h           帮助
EOF
}

log() {
    local ts
    ts=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[$ts] $*"
    [[ -n "$LOG_FILE" ]] && echo "[$ts] $*" >> "$LOG_FILE"
}

resolve_conflict() {
    local dest="$1"
    [[ ! -e "$dest" ]] && { echo "$dest"; return; }
    local dir name ext counter=1
    dir=$(dirname "$dest")
    name=$(basename "$dest"); name="${name%.*}"
    ext=$(basename "$dest"); ext="${ext##*.}"
    while true; do
        [[ "$name" == "$ext" ]] && dest="${dir}/${name}_${counter}" \
                                 || dest="${dir}/${name}_${counter}.${ext}"
        [[ ! -e "$dest" ]] && break
        counter=$((counter + 1))
    done
    echo "$dest"
}

# --- 按类型整理 ---
organize_by_type() {
    local filepath="$1"
    local filename
    filename=$(basename "$filepath")
    [[ "$filename" == .* || -d "$filepath" ]] && return

    local ext="${filename##*.}"
    ext="${ext,,}"
    local category="${EXT_MAP[$ext]:-others}"
    local dest_dir="${TARGET_DIR}/${category}"
    local dest
    dest=$(resolve_conflict "${dest_dir}/${filename}")

    if [[ "$DRY_RUN" == true ]]; then
        echo -e "  ${YELLOW}[预览]${NC} ${filename} → ${category}/"
    else
        mkdir -p "$dest_dir"
        echo "$filepath|$dest" >> "${LOG_FILE}.undo"
        mv "$filepath" "$dest"
        [[ "$VERBOSE" == true ]] && echo -e "  ${GREEN}[移动]${NC} ${filename} → ${category}/"
    fi
}

# --- 按日期整理 ---
organize_by_date() {
    local filepath="$1"
    local filename
    filename=$(basename "$filepath")
    [[ "$filename" == .* || -d "$filepath" ]] && return

    local mod_date
    mod_date=$(date -r "$filepath" '+%Y/%m' 2>/dev/null || stat -c '%y' "$filepath" 2>/dev/null | cut -c1-7 | tr '-' '/')
    local dest_dir="${TARGET_DIR}/${mod_date}"
    local dest
    dest=$(resolve_conflict "${dest_dir}/${filename}")

    if [[ "$DRY_RUN" == true ]]; then
        echo -e "  ${YELLOW}[预览]${NC} ${filename} → ${mod_date}/"
    else
        mkdir -p "$dest_dir"
        echo "$filepath|$dest" >> "${LOG_FILE}.undo"
        mv "$filepath" "$dest"
    fi
}

# --- 按大小整理 ---
organize_by_size() {
    local filepath="$1"
    local filename
    filename=$(basename "$filepath")
    [[ "$filename" == .* || -d "$filepath" ]] && return

    local size
    size=$(stat -c%s "$filepath" 2>/dev/null || stat -f%z "$filepath" 2>/dev/null || echo 0)
    local category
    if (( size < 102400 )); then        # < 100KB
        category="small"
    elif (( size < 10485760 )); then     # < 10MB
        category="medium"
    else
        category="large"
    fi

    local dest_dir="${TARGET_DIR}/${category}"
    local dest
    dest=$(resolve_conflict "${dest_dir}/${filename}")

    if [[ "$DRY_RUN" == true ]]; then
        echo -e "  ${YELLOW}[预览]${NC} ${filename} (${size}B) → ${category}/"
    else
        mkdir -p "$dest_dir"
        echo "$filepath|$dest" >> "${LOG_FILE}.undo"
        mv "$filepath" "$dest"
    fi
}

# --- 查重 ---
find_duplicates() {
    echo -e "${CYAN}扫描重复文件...${NC}"
    declare -A hash_map
    local dup_count=0

    while IFS= read -r -d '' filepath; do
        local hash
        hash=$(md5sum "$filepath" 2>/dev/null | cut -d' ' -f1)
        [[ -z "$hash" ]] && continue

        if [[ -n "${hash_map[$hash]+x}" ]]; then
            echo -e "  ${RED}[重复]${NC} ${filepath}"
            echo -e "         与 ${hash_map[$hash]} 相同"
            dup_count=$((dup_count + 1))

            if [[ "$DRY_RUN" == false ]]; then
                read -rp "  删除 ${filepath}? [y/N] " ans
                [[ "$ans" =~ ^[Yy] ]] && rm "$filepath" && echo "  已删除"
            fi
        else
            hash_map[$hash]="$filepath"
        fi
    done < <(find "$TARGET_DIR" -type f -print0)

    echo -e "\n找到 ${dup_count} 组重复文件"
}

# --- 撤销操作 ---
undo_last() {
    local undo_file="${LOG_FILE}.undo"
    if [[ ! -f "$undo_file" ]]; then
        echo -e "${RED}没有找到撤销日志${NC}"
        exit 1
    fi

    echo -e "${CYAN}撤销上次操作...${NC}"
    while IFS='|' read -r src dest; do
        if [[ -e "$dest" ]]; then
            mkdir -p "$(dirname "$src")"
            mv "$dest" "$src"
            echo -e "  ${GREEN}[恢复]${NC} $(basename "$dest") → $(dirname "$src")/"
        fi
    done < <(tac "$undo_file")

    rm "$undo_file"
    echo -e "${GREEN}撤销完成${NC}"
}

# --- 参数解析 ---
while [[ $# -gt 0 ]]; do
    case "$1" in
        --by-type)  MODE="type"; shift ;;
        --by-date)  MODE="date"; shift ;;
        --by-size)  MODE="size"; shift ;;
        --dedup)    MODE="dedup"; shift ;;
        --undo)     MODE="undo"; shift ;;
        --dry-run)  DRY_RUN=true; shift ;;
        -v)         VERBOSE=true; shift ;;
        -h|--help)  show_help; exit 0 ;;
        -*)         echo "未知选项: $1"; exit 1 ;;
        *)          TARGET_DIR="$1"; shift ;;
    esac
done

# --- 主程序 ---
main() {
    [[ -z "$TARGET_DIR" ]] && { show_help; exit 1; }

    # 撤销模式
    if [[ "$MODE" == "undo" ]]; then
        LOG_FILE="${TARGET_DIR}/.organizer_advanced.log"
        undo_last
        exit 0
    fi

    [[ ! -d "$TARGET_DIR" ]] && { echo -e "${RED}目录不存在: ${TARGET_DIR}${NC}"; exit 1; }

    LOG_FILE="${TARGET_DIR}/.organizer_advanced.log"

    echo -e "${CYAN}╔══════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║     文件整理器（高级版）v2.0         ║${NC}"
    echo -e "${CYAN}╚══════════════════════════════════════╝${NC}"
    echo ""
    echo -e "目录: ${TARGET_DIR}"
    echo -e "模式: ${MODE}"
    echo -e "预览: ${DRY_RUN}"
    echo ""

    # 查重模式
    if [[ "$MODE" == "dedup" ]]; then
        find_duplicates
        exit 0
    fi

    # 整理模式
    local count=0
    local process_func
    case "$MODE" in
        type) process_func="organize_by_type" ;;
        date) process_func="organize_by_date" ;;
        size) process_func="organize_by_size" ;;
    esac

    while IFS= read -r -d '' filepath; do
        $process_func "$filepath"
        count=$((count + 1))
    done < <(find "$TARGET_DIR" -maxdepth 1 -type f -print0)

    echo ""
    echo -e "${GREEN}完成！处理了 ${count} 个文件${NC}"
    if [[ "$DRY_RUN" == false ]]; then
        echo -e "日志: ${LOG_FILE}"
        echo -e "撤销: bash $0 --undo ${TARGET_DIR}"
    fi
}

main
