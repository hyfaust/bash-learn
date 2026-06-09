#!/bin/bash
# ============================================================================
# lib.sh — 共享函数库
# 使用: source "$(dirname "$0")/lib.sh"
# ============================================================================

readonly COLOR_RED='\033[0;31m'
readonly COLOR_YELLOW='\033[1;33m'
readonly COLOR_GREEN='\033[0;32m'
readonly COLOR_CYAN='\033[0;36m'
readonly COLOR_RESET='\033[0m'

[[ ! -t 1 ]] && USE_COLOR=false || USE_COLOR=true
LOG_FILE=""
VERBOSE=false

_log() {
    local level="$1"; shift
    local ts; ts=$(date '+%Y-%m-%d %H:%M:%S')
    local color="" reset=""
    if [[ "$USE_COLOR" == true ]]; then
        case "$level" in
            DEBUG) color="$COLOR_CYAN" ;; INFO)  color="$COLOR_GREEN" ;;
            WARN)  color="$COLOR_YELLOW" ;; ERROR) color="$COLOR_RED" ;;
        esac
        reset="$COLOR_RESET"
    fi
    local formatted="[$ts] [$level] $*"
    case "$level" in
        ERROR|WARN) printf "${color}%s${reset}\n" "$formatted" >&2 ;;
        *)          printf "${color}%s${reset}\n" "$formatted" ;;
    esac
    [[ -n "$LOG_FILE" ]] && echo "$formatted" >> "$LOG_FILE"
}

log_debug() { [[ "$VERBOSE" == true ]] && _log "DEBUG" "$@"; }
log_info()  { _log "INFO" "$@"; }
log_warn()  { _log "WARN" "$@"; }
log_error() { _log "ERROR" "$@"; }
die()       { log_error "$1"; exit "${2:-1}"; }

confirm() {
    local prompt="${1:-确认继续？}" default="${2:-n}" reply
    [[ "$default" == "y" ]] && prompt="$prompt [Y/n] " || prompt="$prompt [y/N] "
    read -rp "$prompt" reply; reply="${reply:-$default}"
    [[ "$reply" =~ ^[Yy]$ ]]
}

progress_bar() {
    local current="$1" total="$2" message="${3:-进度}" width=40
    local pct=$((current * 100 / total))
    local filled=$((current * width / total)) empty=$((width - filled))
    local bar=""
    for ((i = 0; i < filled; i++)); do bar+="█"; done
    for ((i = 0; i < empty; i++)); do bar+="░"; done
    printf "\r%s [%s] %3d%% (%d/%d)" "$message" "$bar" "$pct" "$current" "$total"
    [[ "$current" -eq "$total" ]] && echo ""
}

human_size() {
    local size="$1" units=("B" "K" "M" "G" "T") idx=0
    while ((size > 1024)) && ((idx < ${#units[@]} - 1)); do
        size=$((size / 1024)); ((idx++))
    done
    echo "${size}${units[$idx]}"
}

check_command() { command -v "$1" &>/dev/null || { log_error "命令 '$1' 未找到"; return 1; }; }
ensure_dir()    { [[ ! -d "$1" ]] && { mkdir -p "$1" || die "无法创建目录: $1"; }; }
timestamp()     { date '+%Y%m%d_%H%M%S'; }
