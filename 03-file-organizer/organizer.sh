#!/bin/bash
# =============================================================================
# organizer.sh — 文件整理器（基础版）
# 功能：按文件扩展名分类整理文件
# 用法：bash organizer.sh [选项] <目录>
# 选项：--dry-run 预览模式, -v 详细输出, -h 帮助
# =============================================================================

set -euo pipefail

# --- 颜色 ---
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

# --- 配置 ---
DRY_RUN=false
VERBOSE=false
TARGET_DIR=""

# 分类映射：扩展名 -> 目录名
declare -A EXT_MAP=(
    # 图片
    [jpg]="images" [jpeg]="images" [png]="images" [gif]="images"
    [bmp]="images" [svg]="images" [webp]="images" [ico]="images"
    [tiff]="images" [raw]="images"
    # 文档
    [pdf]="documents" [doc]="documents" [docx]="documents"
    [txt]="documents" [md]="documents" [rtf]="documents"
    [xls]="documents" [xlsx]="documents" [csv]="documents"
    [ppt]="documents" [pptx]="documents" [odt]="documents"
    # 视频
    [mp4]="videos" [avi]="videos" [mkv]="videos" [mov]="videos"
    [wmv]="videos" [flv]="videos" [webm]="videos"
    # 音频
    [mp3]="audio" [wav]="audio" [flac]="audio" [aac]="audio"
    [ogg]="audio" [wma]="audio" [m4a]="audio"
    # 压缩包
    [zip]="archives" [tar]="archives" [gz]="archives"
    [bz2]="archives" [xz]="archives" [7z]="archives"
    [rar]="archives"
    # 代码
    [sh]="code" [py]="code" [js]="code" [ts]="code"
    [html]="code" [css]="code" [json]="code" [xml]="code"
    [c]="code" [cpp]="code" [java]="code" [go]="code"
    [rs]="code" [rb]="code" [php]="code"
)

# 日志文件
LOG_FILE=""
MOVED_COUNT=0
SKIPPED_COUNT=0

# --- 函数 ---

show_help() {
    cat <<'EOF'
用法: organizer.sh [选项] <目录>

按文件类型整理文件到分类目录中

选项:
  --dry-run    预览模式（不实际移动文件）
  -v           详细输出
  -h           显示帮助

分类规则:
  images/     jpg, png, gif, svg, webp ...
  documents/  pdf, doc, txt, md, csv ...
  videos/     mp4, avi, mkv, mov ...
  audio/      mp3, wav, flac, ogg ...
  archives/   zip, tar, gz, rar, 7z ...
  code/       sh, py, js, html, css ...
  others/     未匹配的文件
EOF
}

log() {
    local level="$1"; shift
    local msg="$*"
    local ts
    ts=$(date '+%H:%M:%S')
    echo "[$ts] [$level] $msg"
    [[ -n "$LOG_FILE" ]] && echo "[$ts] [$level] $msg" >> "$LOG_FILE"
}

# 获取文件分类目录
get_category() {
    local filename="$1"
    local ext="${filename##*.}"
    ext="${ext,,}"  # 转小写

    # 无扩展名
    if [[ "$ext" == "$filename" ]]; then
        echo "others"
        return
    fi

    echo "${EXT_MAP[$ext]:-others}"
}

# 处理文件名冲突（添加后缀）
resolve_conflict() {
    local dest="$1"
    if [[ ! -e "$dest" ]]; then
        echo "$dest"
        return
    fi

    local dir dirname basename name ext counter
    dir=$(dirname "$dest")
    basename=$(basename "$dest")
    name="${basename%.*}"
    ext="${basename##*.}"

    counter=1
    while true; do
        if [[ "$name" == "$ext" ]]; then
            dest="${dir}/${name}_${counter}"
        else
            dest="${dir}/${name}_${counter}.${ext}"
        fi
        [[ ! -e "$dest" ]] && break
        ((counter++))
    done
    echo "$dest"
}

# 整理单个文件
organize_file() {
    local filepath="$1"
    local filename
    filename=$(basename "$filepath")

    # 跳过隐藏文件和目录
    [[ "$filename" == .* ]] && return

    # 跳过目录
    [[ -d "$filepath" ]] && return

    local category
    category=$(get_category "$filename")
    local dest_dir="${TARGET_DIR}/${category}"
    local dest="${dest_dir}/${filename}"

    # 解决文件名冲突
    dest=$(resolve_conflict "$dest")

    if [[ "$DRY_RUN" == true ]]; then
        echo -e "  ${YELLOW}[预览]${NC} ${filename} → ${category}/"
        MOVED_COUNT=$((MOVED_COUNT + 1))
        return
    fi

    # 创建目标目录
    mkdir -p "$dest_dir"

    # 移动文件
    if mv "$filepath" "$dest" 2>/dev/null; then
        if [[ "$VERBOSE" == true ]]; then
            echo -e "  ${GREEN}[移动]${NC} ${filename} → ${category}/$(basename "$dest")"
        fi
        log "INFO" "移动: $filepath -> $dest"
        MOVED_COUNT=$((MOVED_COUNT + 1))
    else
        echo -e "  ${RED}[失败]${NC} 无法移动: ${filename}"
        log "ERROR" "移动失败: $filepath"
        SKIPPED_COUNT=$((SKIPPED_COUNT + 1))
    fi
}

# --- 参数解析 ---
while [[ $# -gt 0 ]]; do
    case "$1" in
        --dry-run) DRY_RUN=true; shift ;;
        -v)        VERBOSE=true; shift ;;
        -h|--help) show_help; exit 0 ;;
        -*)        echo "未知选项: $1"; show_help; exit 1 ;;
        *)         TARGET_DIR="$1"; shift ;;
    esac
done

# --- 主程序 ---
main() {
    if [[ -z "$TARGET_DIR" ]]; then
        echo -e "${RED}错误: 请指定目标目录${NC}"
        show_help
        exit 1
    fi

    if [[ ! -d "$TARGET_DIR" ]]; then
        echo -e "${RED}错误: 目录不存在: ${TARGET_DIR}${NC}"
        exit 1
    fi

    # 设置日志
    LOG_FILE="${TARGET_DIR}/.organizer.log"

    echo -e "${CYAN}╔══════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║        文件整理器 v1.0               ║${NC}"
    echo -e "${CYAN}╚══════════════════════════════════════╝${NC}"
    echo ""
    echo -e "目标目录: ${TARGET_DIR}"
    echo -e "模式: $([ "$DRY_RUN" == true ] && echo '预览' || echo '执行')"
    echo ""

    # 遍历目标目录中的文件
    local total=0
    for filepath in "$TARGET_DIR"/*; do
        [[ -e "$filepath" ]] || continue
        total=$((total + 1))
    done

    if (( total == 0 )); then
        echo -e "${YELLOW}目录为空，无需整理${NC}"
        exit 0
    fi

    echo -e "找到 ${total} 个项目，开始整理..."
    echo ""

    for filepath in "$TARGET_DIR"/*; do
        [[ -e "$filepath" ]] || continue
        organize_file "$filepath"
    done

    echo ""
    echo -e "${GREEN}整理完成！${NC}"
    echo -e "  已处理: ${MOVED_COUNT} 个文件"
    echo -e "  已跳过: ${SKIPPED_COUNT} 个文件"
    if [[ -n "$LOG_FILE" && "$DRY_RUN" == false ]]; then
        echo -e "  日志: ${LOG_FILE}"
    fi
}

main
