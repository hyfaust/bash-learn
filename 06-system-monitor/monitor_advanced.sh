#!/bin/bash
# ============================================================================
# monitor_advanced.sh — 高级系统监控
# 功能: 告警系统、交互菜单、守护进程模式、历史记录
# ============================================================================

set -euo pipefail

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
CYAN='\033[0;36m'; BOLD='\033[1m'; DIM='\033[2m'; RESET='\033[0m'

CPU_THRESHOLD=80
MEM_THRESHOLD=85
DISK_THRESHOLD=90
LOG_FILE="/tmp/system_monitor.log"
DAEMON_MODE=false
ALERT_HISTORY=()

# --- 工具函数 ---
human_size() {
    local size="$1" units=("B" "K" "M" "G" "T") idx=0
    while ((size > 1024)) && ((idx < ${#units[@]} - 1)); do
        size=$((size / 1024)); idx=$((idx + 1))
    done
    echo "${size}${units[$idx]}"
}

make_bar() {
    local pct="$1" width="${2:-25}"
    local filled=$((pct * width / 100))
    local empty=$((width - filled))
    local bar="" color="$GREEN"
    if ((pct > 60)); then color="$YELLOW"; fi
    if ((pct > 85)); then color="$RED"; fi
    for ((i = 0; i < filled; i++)); do bar+="█"; done
    for ((i = 0; i < empty; i++)); do bar+="░"; done
    printf "${color}%s${RESET}" "$bar"
}

log_event() {
    local ts; ts=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[$ts] $*" >> "$LOG_FILE"
}

# --- 系统信息采集 ---
get_cpu_usage() {
    read -r _ u1 n1 s1 i1 w1 q1 sq1 st1 _ _ < /proc/stat
    local t1=$((u1+n1+s1+i1+w1+q1+sq1+st1))
    local b1=$((t1-i1-w1))
    sleep 0.3
    read -r _ u2 n2 s2 i2 w2 q2 sq2 st2 _ _ < /proc/stat
    local t2=$((u2+n2+s2+i2+w2+q2+sq2+st2))
    local b2=$((t2-i2-w2))
    local dt=$((t2-t1))
    local db=$((b2-b1))
    if ((dt > 0)); then echo "scale=1; $db*100/$dt" | bc; else echo "0.0"; fi
}

get_memory_percent() {
    local total=0 avail=0
    while IFS=': ' read -r key value _; do
        case "$key" in MemTotal) total="$value";; MemAvailable) avail="$value";; esac
    done < /proc/meminfo
    echo $(( (total - avail) * 100 / total ))
}

get_disk_alerts() {
    df -hP 2>/dev/null | awk -v thresh="$DISK_THRESHOLD" 'NR>1 && $1 !~ /^(tmpfs|devtmpfs)$/ {
        gsub(/%/,"",$5)
        if ($5+0 > thresh) printf "%s: %s%%", $6, $5
    }'
}

# --- 告警系统 ---
check_alerts() {
    local cpu; cpu=$(get_cpu_usage)
    local cpu_int=${cpu%%.*}
    local mem; mem=$(get_memory_percent)

    if ((cpu_int > CPU_THRESHOLD)); then
        local msg="CPU 告警: ${cpu}% > ${CPU_THRESHOLD}%"
        echo -e "  ${RED}⚠ $msg${RESET}"
        log_event "ALERT: $msg"
        ALERT_HISTORY+=("$(date '+%H:%M') $msg")
    fi

    if ((mem > MEM_THRESHOLD)); then
        local msg="内存告警: ${mem}% > ${MEM_THRESHOLD}%"
        echo -e "  ${RED}⚠ $msg${RESET}"
        log_event "ALERT: $msg"
        ALERT_HISTORY+=("$(date '+%H:%M') $msg")
    fi

    local disk_alerts; disk_alerts=$(get_disk_alerts)
    if [[ -n "$disk_alerts" ]]; then
        while IFS= read -r alert; do
            echo -e "  ${RED}⚠ 磁盘告警: $alert > ${DISK_THRESHOLD}%${RESET}"
            log_event "ALERT: 磁盘 $alert"
            ALERT_HISTORY+=("$(date '+%H:%M') 磁盘 $alert")
        done <<< "$disk_alerts"
    fi
}

# --- 历史图表（ASCII 折线图） ---
cpu_history=()
MAX_HISTORY=40

record_cpu() {
    local val="$1"
    cpu_history+=("$val")
    if ((${#cpu_history[@]} > MAX_HISTORY)); then cpu_history=("${cpu_history[@]:1}"); fi
}

draw_chart() {
    local title="$1"; shift
    local values=("$@")
    local height=10 width=${#values[@]}
    if ((width == 0)); then return; fi

    echo -e "  ${BOLD}$title${RESET}"
    for ((row = height; row >= 1; row--)); do
        local threshold=$((row * 100 / height))
        printf "  %3d%% │" "$threshold"
        for val in "${values[@]}"; do
            local int_val=${val%%.*}
            if ((int_val >= threshold)); then
                printf "█"
            else
                printf " "
            fi
        done
        echo ""
    done
    printf "      └"
    for ((i = 0; i < width; i++)); do printf "─"; done
    echo ""
}

# --- 系统快照 ---
system_snapshot() {
    local now; now=$(date '+%Y-%m-%d %H:%M:%S')
    local cpu; cpu=$(get_cpu_usage)
    local cpu_int=${cpu%%.*}
    record_cpu "$cpu_int"
    local mem; mem=$(get_memory_percent)
    read -r l1 l5 l15 _ _ < /proc/loadavg
    local procs; procs=$(ls -d /proc/[0-9]* 2>/dev/null | wc -l)

    local cpu_bar; cpu_bar=$(make_bar "${cpu_int:-0}")
    local mem_bar; mem_bar=$(make_bar "$mem")

    echo -e "${BOLD}┌──────────────────────────────────────────────────────────┐${RESET}"
    echo -e "${BOLD}│${RESET}  ${CYAN}${BOLD}系统监控${RESET}  ${DIM}$now${RESET}"
    echo -e "${BOLD}├──────────────────────────────────────────────────────────┤${RESET}"
    echo -e "${BOLD}│${RESET}  CPU:  [${cpu_bar}] ${cpu}%"
    echo -e "${BOLD}│${RESET}  内存: [${mem_bar}] ${mem}%"
    echo -e "${BOLD}│${RESET}  负载: $l1 (1m)  $l5 (5m)  $l15 (15m)  进程: $procs"
    echo -e "${BOLD}├──────────────────────────────────────────────────────────┤${RESET}"

    check_alerts

    echo -e "${BOLD}├──────────────────────────────────────────────────────────┤${RESET}"
    echo -e "${BOLD}│${RESET}  ${BOLD}TOP 5 进程:${RESET}"
    ps aux --sort=-%cpu 2>/dev/null | head -6 | tail -5 | while IFS= read -r line; do
        echo -e "${BOLD}│${RESET}  ${DIM}$line${RESET}"
    done

    if ((${#cpu_history[@]} > 3)); then
        echo -e "${BOLD}├──────────────────────────────────────────────────────────┤${RESET}"
        draw_chart "CPU 历史 (最近 ${#cpu_history[@]} 次)" "${cpu_history[@]}"
    fi

    echo -e "${BOLD}└──────────────────────────────────────────────────────────┘${RESET}"
}

# --- 交互菜单 ---
show_menu() {
    echo ""
    echo -e "${BOLD}操作菜单:${RESET}"
    echo "  1) 刷新仪表盘"
    echo "  2) 设置告警阈值"
    echo "  3) 查看告警历史"
    echo "  4) 网络连接统计"
    echo "  5) 磁盘详细信息"
    echo "  q) 退出"
    echo ""
}

show_connections() {
    echo -e "\n${BOLD}网络连接统计:${RESET}"
    if command -v ss &>/dev/null; then
        echo -e "  ${BOLD}TCP 状态:${RESET}"
        ss -t state established 2>/dev/null | tail -n +2 | wc -l | xargs -I{} echo "    已建立: {}"
        ss -t state time-wait 2>/dev/null | tail -n +2 | wc -l | xargs -I{} echo "    TIME_WAIT: {}"
        ss -tulnp 2>/dev/null | tail -n +2 | head -10 | while IFS= read -r line; do
            echo "    $line"
        done
    else
        echo "  ss 命令不可用"
    fi
}

configure_thresholds() {
    echo -e "\n当前阈值: CPU=${CPU_THRESHOLD}%  MEM=${MEM_THRESHOLD}%  DISK=${DISK_THRESHOLD}%"
    read -rp "新 CPU 阈值 (回车跳过): " val; if [[ -n "$val" ]]; then CPU_THRESHOLD="$val"; fi
    read -rp "新内存阈值 (回车跳过): " val; if [[ -n "$val" ]]; then MEM_THRESHOLD="$val"; fi
    read -rp "新磁盘阈值 (回车跳过): " val; if [[ -n "$val" ]]; then DISK_THRESHOLD="$val"; fi
    echo "阈值已更新"
}

show_alert_history() {
    echo -e "\n${BOLD}告警历史:${RESET}"
    if ((${#ALERT_HISTORY[@]} == 0)); then
        echo "  暂无告警"
    else
        for alert in "${ALERT_HISTORY[@]}"; do
            echo -e "  ${RED}$alert${RESET}"
        done
    fi
}

# --- 主逻辑 ---
if [[ "$DAEMON_MODE" == true ]]; then
    while true; do
        local cpu; cpu=$(get_cpu_usage); local cpu_int=${cpu%%.*}
        local mem; mem=$(get_memory_percent)
        if ((cpu_int > CPU_THRESHOLD)); then log_event "ALERT: CPU ${cpu}%"; fi
        if ((mem > MEM_THRESHOLD)); then log_event "ALERT: MEM ${mem}%"; fi
        sleep 60
    done
else
    trap 'tput cnorm 2>/dev/null; echo ""; exit 0' INT TERM
    while true; do
        clear
        system_snapshot
        show_menu
        read -rp "选择操作 [1/2/3/4/5/q]: " choice
        case "$choice" in
            1) continue ;;
            2) configure_thresholds; read -rp "按回车继续..." ;;
            3) show_alert_history; read -rp "按回车继续..." ;;
            4) show_connections; read -rp "按回车继续..." ;;
            5) df -hP 2>/dev/null; read -rp "按回车继续..." ;;
            q|Q) echo "再见!"; exit 0 ;;
            *) ;;
        esac
    done
fi
