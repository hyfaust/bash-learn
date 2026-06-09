#!/bin/bash
# ============================================================================
# mini_tools.sh — 独立系统信息小工具集
# 用法: ./mini_tools.sh <工具名>
# ============================================================================

set -euo pipefail

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
CYAN='\033[0;36m'; BOLD='\033[1m'; RESET='\033[0m'

human_size() {
    local size="$1" units=("B" "K" "M" "G" "T") idx=0
    while ((size > 1024)) && ((idx < ${#units[@]} - 1)); do
        size=$((size / 1024)); idx=$((idx + 1))
    done
    echo "${size}${units[$idx]}"
}

# --- CPU 信息 ---
tool_cpu() {
    echo -e "${BOLD}=== CPU 信息 ===${RESET}"
    local model; model=$(grep -m1 'model name' /proc/cpuinfo 2>/dev/null | cut -d: -f2 | xargs)
    local cores; cores=$(grep -c '^processor' /proc/cpuinfo 2>/dev/null)
    echo "  型号: ${model:-未知}"
    echo "  核心数: $cores"

    echo -e "\n  ${BOLD}各核心使用率:${RESET}"
    while read -r line; do
        [[ "$line" == cpu* ]] || continue
        local name fields; read -r name fields <<< "$line"
        [[ "$name" != "cpu" ]] || continue
        local vals=($fields)
        local total=0; for v in "${vals[@]}"; do total=$((total + v)); done
        local idle=${vals[3]}
        local busy=$((total - idle))
        echo "    $name: 总=$total 忙=$busy 空闲=$idle"
    done < /proc/stat

    read -r l1 l5 l15 _ _ < /proc/loadavg
    echo -e "\n  负载: $l1 (1m)  $l5 (5m)  $l15 (15m)"
}

# --- 内存信息 ---
tool_mem() {
    echo -e "${BOLD}=== 内存信息 ===${RESET}"
    while IFS=': ' read -r key value unit; do
        case "$key" in
            MemTotal|MemFree|MemAvailable|Buffers|Cached|SwapTotal|SwapFree)
                printf "  %-15s %10s %s\n" "$key:" "$value" "${unit:-kB}"
                ;;
        esac
    done < /proc/meminfo

    local total avail; total=$(awk '/MemTotal/{print $2}' /proc/meminfo); avail=$(awk '/MemAvailable/{print $2}' /proc/meminfo)
    local used=$((total - avail))
    local pct=$((used * 100 / total))
    local bar="" filled=$((pct * 30 / 100))
    for ((i = 0; i < filled; i++)); do bar+="█"; done
    for ((i = filled; i < 30; i++)); do bar+="░"; done
    local color="$GREEN"
    if ((pct > 60)); then color="$YELLOW"; fi
    if ((pct > 85)); then color="$RED"; fi
    echo -e "\n  使用率: [${color}${bar}${RESET}] ${pct}%"
    echo "  已用: $(human_size $((used*1024))) / $(human_size $((total*1024)))"
}

# --- 磁盘信息 ---
tool_disk() {
    echo -e "${BOLD}=== 磁盘信息 ===${RESET}"
    printf "  %-20s %8s %8s %8s %6s\n" "挂载点" "总量" "已用" "可用" "使用率"
    printf "  %-20s %8s %8s %8s %6s\n" "--------------------" "--------" "--------" "--------" "------"
    df -hP 2>/dev/null | awk 'NR>1 && $1 !~ /^(tmpfs|devtmpfs|overlay)$/ {
        gsub(/%/,"",$5)
        printf "  %-20s %8s %8s %8s %5s%%\n", $6, $2, $3, $4, $5
    }'

    echo -e "\n  ${BOLD}inode 使用率:${RESET}"
    df -hiP 2>/dev/null | awk 'NR>1 && $1 !~ /^(tmpfs|devtmpfs|overlay)$/ && $5+0 > 50 {
        gsub(/%/,"",$5)
        printf "  %-20s %s%%\n", $6, $5
    }'
}

# --- 网络信息 ---
tool_net() {
    echo -e "${BOLD}=== 网络信息 ===${RESET}"
    echo -e "  ${BOLD}接口流量:${RESET}"
    tail -n +3 /proc/net/dev | while read -r iface rx_bytes _ _ _ _ _ _ _ tx_bytes _; do
        iface=${iface%:}
        [[ "$iface" == "lo" ]] && continue
        printf "  %-10s  RX: %-12s  TX: %s\n" "$iface" "$(human_size "$rx_bytes")" "$(human_size "$tx_bytes")"
    done

    echo -e "\n  ${BOLD}TCP 连接统计:${RESET}"
    if command -v ss &>/dev/null; then
        ss -s 2>/dev/null | head -5 | while IFS= read -r line; do echo "  $line"; done
    fi

    echo -e "\n  ${BOLD}监听端口:${RESET}"
    if command -v ss &>/dev/null; then
        ss -tulnp 2>/dev/null | tail -n +2 | head -10 | while IFS= read -r line; do echo "  $line"; done
    fi
}

# --- 进程信息 ---
tool_proc() {
    echo -e "${BOLD}=== 进程信息 ===${RESET}"
    local total; total=$(ls -d /proc/[0-9]* 2>/dev/null | wc -l)
    echo "  总进程数: $total"

    echo -e "\n  ${BOLD}TOP 10 (CPU):${RESET}"
    printf "  %-8s %-8s %5s %5s  %s\n" "USER" "PID" "%CPU" "%MEM" "COMMAND"
    ps aux --sort=-%cpu 2>/dev/null | head -11 | tail -10 | awk '{printf "  %-8s %-8s %5s %5s  %s\n", $1, $2, $3, $4, $11}'

    echo -e "\n  ${BOLD}TOP 10 (内存):${RESET}"
    printf "  %-8s %-8s %5s %5s  %s\n" "USER" "PID" "%CPU" "%MEM" "COMMAND"
    ps aux --sort=-%mem 2>/dev/null | head -11 | tail -10 | awk '{printf "  %-8s %-8s %5s %5s  %s\n", $1, $2, $3, $4, $11}'
}

# --- 系统概况 ---
tool_sysinfo() {
    echo -e "${BOLD}=== 系统概况 ===${RESET}"
    local hostname; hostname=$(hostname 2>/dev/null || echo "未知")
    local kernel; kernel=$(uname -r 2>/dev/null)
    local uptime_str
    if uptime_str=$(uptime -p 2>/dev/null); then
        :
    else
        local secs; read -r secs _ < /proc/uptime
        uptime_str="运行 ${secs%%.*}秒"
    fi
    echo "  主机名: $hostname"
    echo "  内核: $kernel"
    echo "  运行时间: $uptime_str"
    echo "  当前时间: $(date '+%Y-%m-%d %H:%M:%S')"
    echo "  用户: $(whoami)"
    echo "  Shell: $BASH_VERSION"
}

# --- 主菜单 ---
show_help() {
    echo "用法: $0 <工具名>"
    echo ""
    echo "可用工具:"
    echo "  cpu       CPU 信息和使用率"
    echo "  mem       内存和 Swap 信息"
    echo "  disk      磁盘使用情况"
    echo "  net       网络接口和连接"
    echo "  proc      进程统计"
    echo "  sysinfo   系统概况"
    echo "  all       显示所有信息"
    echo "  help      显示帮助"
}

case "${1:-help}" in
    cpu)     tool_cpu ;;
    mem)     tool_mem ;;
    disk)    tool_disk ;;
    net)     tool_net ;;
    proc)    tool_proc ;;
    sysinfo) tool_sysinfo ;;
    all)
        tool_sysinfo; echo ""
        tool_cpu; echo ""
        tool_mem; echo ""
        tool_disk; echo ""
        tool_net; echo ""
        tool_proc
        ;;
    help|--help|-h) show_help ;;
    *) echo "未知工具: $1"; show_help; exit 1 ;;
esac
