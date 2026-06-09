#!/bin/bash
# ============================================================================
# monitor.sh — 系统监控仪表盘
# 功能: CPU/内存/磁盘/网络/进程实时监控
# ============================================================================

set -euo pipefail

# --- 颜色 ---
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
CYAN='\033[0;36m'; BOLD='\033[1m'; RESET='\033[0m'

# --- 参数 ---
LIVE_MODE=false
INTERVAL=3

while [[ $# -gt 0 ]]; do
    case "$1" in
        --live) LIVE_MODE=true; shift ;;
        --interval|-i) INTERVAL="$2"; shift 2 ;;
        -h|--help) echo "用法: monitor.sh [--live] [--interval N]"; exit 0 ;;
        *) shift ;;
    esac
done

# --- 工具函数 ---
human_size() {
    local size="$1" units=("B" "K" "M" "G" "T") idx=0
    while ((size > 1024)) && ((idx < ${#units[@]} - 1)); do
        size=$((size / 1024)); ((idx++))
    done
    echo "${size}${units[$idx]}"
}

make_bar() {
    local pct="$1" width="${2:-30}"
    local filled=$((pct * width / 100))
    local empty=$((width - filled))
    local bar="" color="$GREEN"
    ((pct > 60)) && color="$YELLOW"
    ((pct > 85)) && color="$RED"
    for ((i = 0; i < filled; i++)); do bar+="█"; done
    for ((i = 0; i < empty; i++)); do bar+="░"; done
    printf "${color}%s${RESET}" "$bar"
}

# --- CPU 使用率（两次采样） ---
get_cpu_usage() {
    read -r _ u1 n1 s1 i1 w1 q1 sq1 st1 _ _ < /proc/stat
    local t1=$((u1+n1+s1+i1+w1+q1+sq1+st1))
    local b1=$((t1 - i1 - w1))
    sleep 0.5
    read -r _ u2 n2 s2 i2 w2 q2 sq2 st2 _ _ < /proc/stat
    local t2=$((u2+n2+s2+i2+w2+q2+sq2+st2))
    local b2=$((t2 - i2 - w2))
    local dt=$((t2 - t1)) db=$((b2 - b1))
    if ((dt > 0)); then
        echo "scale=1; $db * 100 / $dt" | bc
    else
        echo "0.0"
    fi
}

# --- 内存信息 ---
get_memory_info() {
    local total=0 available=0 swap_total=0 swap_free=0
    while IFS=': ' read -r key value _; do
        case "$key" in
            MemTotal)     total="$value" ;;
            MemAvailable) available="$value" ;;
            SwapTotal)    swap_total="$value" ;;
            SwapFree)     swap_free="$value" ;;
        esac
    done < /proc/meminfo
    local used=$((total - available))
    local pct=$((used * 100 / total))
    local swap_used=$((swap_total - swap_free))
    local swap_pct=0
    if ((swap_total > 0)); then swap_pct=$((swap_used * 100 / swap_total)); fi
    echo "${total} ${used} ${pct} ${swap_total} ${swap_used} ${swap_pct}"
}

# --- 磁盘信息 ---
get_disk_info() {
    df -hP 2>/dev/null | awk 'NR>1 && $1 !~ /^(tmpfs|devtmpfs|overlay)$/ {
        gsub(/%/, "", $5)
        printf "%-20s %8s %8s %8s %5s%% %s\n", $1, $2, $3, $4, $5, $6
    }'
}

# --- 网络信息 ---
get_network_info() {
    tail -n +3 /proc/net/dev | while read -r iface rx_bytes _ _ _ _ _ _ _ tx_bytes _; do
        iface=${iface%:}
        [[ "$iface" == "lo" ]] && continue
        printf "  %-10s RX: %-10s TX: %s\n" "$iface" "$(human_size "$rx_bytes")" "$(human_size "$tx_bytes")"
    done
}

# --- 负载 ---
get_load() {
    read -r l1 l5 l15 _ _ < /proc/loadavg
    echo "$l1 $l5 $l15"
}

# --- Top 进程 ---
get_top_processes() {
    ps aux --sort=-%cpu 2>/dev/null | head -6 | tail -5 | awk '{printf "  %-8s %-8s %5s%% %5s%%  %s\n", $1, $2, $3, $4, $11}'
}

# --- 进程计数 ---
count_processes() {
    ls -d /proc/[0-9]* 2>/dev/null | wc -l
}

# --- 渲染仪表盘 ---
render_dashboard() {
    local now; now=$(date '+%Y-%m-%d %H:%M:%S')
    local cpu_pct; cpu_pct=$(get_cpu_usage)
    read -r mem_total mem_used mem_pct swap_total swap_used swap_pct <<< "$(get_memory_info)"
    local load; load=$(get_load)
    local proc_count; proc_count=$(count_processes)

    local cpu_int=${cpu_pct%%.*}
    local cpu_bar; cpu_bar=$(make_bar "${cpu_int:-0}")
    local mem_bar; mem_bar=$(make_bar "$mem_pct")

    echo -e "${BOLD}┌─────────────────────────────────────────────────────────────┐${RESET}"
    echo -e "${BOLD}│${RESET}              ${CYAN}${BOLD}🖥 系统监控仪表盘${RESET}                          ${BOLD}│${RESET}"
    echo -e "${BOLD}│${RESET}              $now                             ${BOLD}│${RESET}"
    echo -e "${BOLD}├──────────────────────────────┬──────────────────────────────┤${RESET}"
    echo -e "${BOLD}│${RESET}  CPU 使用率: ${cpu_pct}%"
    echo -e "${BOLD}│${RESET}  [${cpu_bar}]"
    echo -e "${BOLD}│${RESET}"
    echo -e "${BOLD}│${RESET}  进程数: ${proc_count}    负载: ${load}"
    echo -e "${BOLD}├──────────────────────────────┴──────────────────────────────┤${RESET}"
    echo -e "${BOLD}│${RESET}  内存: $(human_size $((mem_used*1024))) / $(human_size $((mem_total*1024))) (${mem_pct}%)"
    echo -e "${BOLD}│${RESET}  [${mem_bar}]"
    echo -e "${BOLD}│${RESET}"
    if ((swap_total > 0)); then
        echo -e "${BOLD}│${RESET}  Swap: $(human_size $((swap_used*1024))) / $(human_size $((swap_total*1024))) (${swap_pct}%)"
    fi
    echo -e "${BOLD}├─────────────────────────────────────────────────────────────┤${RESET}"
    echo -e "${BOLD}│${RESET}  ${BOLD}磁盘使用:${RESET}"
    while IFS= read -r line; do
        local pct; pct=$(echo "$line" | awk '{gsub(/%/,"",$5); print $5}')
        local color="$GREEN"; ((pct > 80)) && color="$YELLOW"; ((pct > 90)) && color="$RED"
        local disk_bar; disk_bar=$(make_bar "$pct" 20)
        local mount; mount=$(echo "$line" | awk '{print $6}')
        printf "${BOLD}│${RESET}  %-20s [%s] %3s%%\n" "$mount" "$disk_bar" "$pct"
    done <<< "$(get_disk_info)"
    echo -e "${BOLD}├─────────────────────────────────────────────────────────────┤${RESET}"
    echo -e "${BOLD}│${RESET}  ${BOLD}网络:${RESET}"
    get_network_info
    echo -e "${BOLD}├─────────────────────────────────────────────────────────────┤${RESET}"
    echo -e "${BOLD}│${RESET}  ${BOLD}TOP 进程 (CPU):${RESET}"
    echo -e "${BOLD}│${RESET}  $(printf '%-8s %-8s %5s %5s  %s' 'USER' 'PID' '%CPU' '%MEM' 'COMMAND')"
    while IFS= read -r line; do
        echo -e "${BOLD}│${RESET}  $line"
    done <<< "$(get_top_processes)"
    echo -e "${BOLD}└─────────────────────────────────────────────────────────────┘${RESET}"
}

# --- 主逻辑 ---
if [[ "$LIVE_MODE" == true ]]; then
    tput civis
    trap 'tput cnorm; echo ""; exit 0' INT TERM
    while true; do
        tput home
        render_dashboard
        echo -e "\n  按 ${BOLD}Ctrl+C${RESET} 退出 | 刷新间隔: ${INTERVAL}s"
        sleep "$INTERVAL"
    done
else
    render_dashboard
fi
