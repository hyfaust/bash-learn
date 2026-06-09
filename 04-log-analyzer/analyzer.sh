#!/bin/bash
# =============================================================================
# analyzer.sh — Web 日志分析器（基础版）
# 用法：bash analyzer.sh <日志文件>
# =============================================================================

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
BLUE='\033[0;34m'; CYAN='\033[0;36m'; WHITE='\033[1;37m'
NC='\033[0m'; BOLD='\033[1m'

TOP_N=10
SUSPICIOUS_404_THRESHOLD=50
LOG_FILE="${1:-access.log}"

print_header() {
    echo ""
    echo -e "${CYAN}$(printf '=%.0s' $(seq 1 60))${NC}"
    echo -e "${WHITE}${BOLD}  $1${NC}"
    echo -e "${CYAN}$(printf '=%.0s' $(seq 1 60))${NC}"
}

# 前置检查
[[ ! -f "$LOG_FILE" ]] && { echo -e "${RED}[错误]${NC} 文件不存在: ${LOG_FILE}"; exit 1; }
TOTAL_LINES=$(wc -l < "$LOG_FILE")
[[ "$TOTAL_LINES" -eq 0 ]] && { echo -e "${RED}[错误]${NC} 文件为空"; exit 1; }

echo -e "${GREEN}${BOLD}"
echo "╔══════════════════════════════════════════════════════════╗"
echo "║            Web 日志分析器 v1.0                           ║"
echo "╚══════════════════════════════════════════════════════════╝"
echo -e "${NC}"
echo -e "${BOLD}日志文件:${NC} ${LOG_FILE}"
echo -e "${BOLD}总请求数:${NC} ${TOTAL_LINES}"

# 1. IP 地址统计
print_header "1. 请求来源 IP (Top ${TOP_N})"
awk '{ ip[$1]++ }
END { for (i in ip) print ip[i], i }' "$LOG_FILE" | sort -rn | head -n "$TOP_N" | \
while read count ip; do
    pct=$(awk "BEGIN { printf \"%.1f\", ($count/$TOTAL_LINES)*100 }")
    bar_len=$((count * 30 / TOTAL_LINES + 1))
    bar=$(printf '█%.0s' $(seq 1 $bar_len))
    printf "  %-18s %6d (%5s%%) ${GREEN}%s${NC}\n" "$ip" "$count" "$pct" "$bar"
done

# 2. HTTP 状态码分布
print_header "2. HTTP 状态码分布"
awk '{ status[$9]++ }
END { for (s in status) print status[s], s }' "$LOG_FILE" | sort -rn | \
while read count status; do
    pct=$(awk "BEGIN { printf \"%.1f\", ($count/$TOTAL_LINES)*100 }")
    case "$status" in
        200) color="$GREEN"; desc="OK" ;;
        301) color="$BLUE"; desc="Redirect" ;;
        304) color="$BLUE"; desc="Not Modified" ;;
        403) color="$YELLOW"; desc="Forbidden" ;;
        404) color="$RED"; desc="Not Found" ;;
        500) color="$RED"; desc="Server Error" ;;
        *) color="$NC"; desc="" ;;
    esac
    bar_len=$((count * 30 / TOTAL_LINES + 1))
    bar=$(printf '█%.0s' $(seq 1 $bar_len))
    printf "  ${color}%-6s${NC} %6d (%5s%%) %-18s ${color}%s${NC}\n" "$status" "$count" "$pct" "$desc" "$bar"
done

# 3. 最常请求的 URL
print_header "3. 最常请求的 URL (Top ${TOP_N})"
awk '{ url[$7]++ }
END { for (u in url) print url[u], u }' "$LOG_FILE" | sort -rn | head -n "$TOP_N" | \
while read count url; do
    printf "  %-40s %5d\n" "$url" "$count"
done

# 4. 带宽统计
print_header "4. 带宽使用统计"
TOTAL_BYTES=$(awk '{ sum += $10 } END { print sum }' "$LOG_FILE")
echo -e "  ${BOLD}总传输量:${NC} ${TOTAL_BYTES} 字节"
awk '{
    bytes[$1] += $10
}
END { for (ip in bytes) print bytes[ip], ip }' "$LOG_FILE" | sort -rn | head -n "$TOP_N" | \
while read bytes ip; do
    if (( bytes >= 1048576 )); then
        human=$(awk "BEGIN { printf \"%.2f MB\", $bytes/1048576 }")
    elif (( bytes >= 1024 )); then
        human=$(awk "BEGIN { printf \"%.2f KB\", $bytes/1024 }")
    else
        human="${bytes} B"
    fi
    printf "  %-18s %12s\n" "$ip" "$human"
done

# 5. 可疑活动检测
print_header "5. 可疑活动检测"
awk -v threshold="$SUSPICIOUS_404_THRESHOLD" '
$9 == "404" { count_404[$1]++ }
END { for (ip in count_404) if (count_404[ip] >= threshold) print count_404[ip], ip }
' "$LOG_FILE" | sort -rn | \
while read count ip; do
    total=$(grep -c "^${ip} " "$LOG_FILE" 2>/dev/null || echo 0)
    pct=$(awk "BEGIN { printf \"%.1f\", ($count/$total)*100 }")
    echo -e "  ${RED}[警告]${NC} ${ip}  404: ${count}/${total} (${pct}%)"
done

# 6. 每小时请求量
print_header "6. 每小时请求量分布"
awk '{
    split($4, a, ":")
    hour[a[2]]++
}
END { for (h in hour) print h, hour[h] }' "$LOG_FILE" | sort -n | \
while read hour count; do
    bar_len=$((count * 40 / TOTAL_LINES + 1))
    bar=$(printf '▓%.0s' $(seq 1 $bar_len))
    printf "  %02d:00  %6d  ${CYAN}%s${NC}\n" "$hour" "$count" "$bar"
done

# 7. 摘要
print_header "7. 分析摘要"
SUCCESS=$(grep -cP '" 200 ' "$LOG_FILE" 2>/dev/null || echo 0)
CLIENT_ERR=$(grep -cP '" 4[0-9]{2} ' "$LOG_FILE" 2>/dev/null || echo 0)
SERVER_ERR=$(grep -cP '" 5[0-9]{2} ' "$LOG_FILE" 2>/dev/null || echo 0)
UNIQUE_IPS=$(awk '{print $1}' "$LOG_FILE" | sort -u | wc -l)

echo -e "  ${GREEN}■${NC} 成功 (2xx):     ${SUCCESS}"
echo -e "  ${YELLOW}■${NC} 客户端错误 (4xx): ${CLIENT_ERR}"
echo -e "  ${RED}■${NC} 服务器错误 (5xx): ${SERVER_ERR}"
echo -e "\n  ${BOLD}独立 IP:${NC} ${UNIQUE_IPS}"
echo ""
echo -e "${GREEN}${BOLD}分析完成！${NC}"
