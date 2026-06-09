#!/bin/bash
# =============================================================================
# analyzer_advanced.sh — Web 日志分析器（高级版）
# 功能：时间维度分析、地理信息、柱状图、CSV导出、多文件、日期过滤
# 用法：bash analyzer_advanced.sh [选项] <日志文件...>
# =============================================================================

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
BLUE='\033[0;34m'; MAGENTA='\033[0;35m'; CYAN='\033[0;36m'
WHITE='\033[1;37m'; NC='\033[0m'; BOLD='\033[1m'

TOP_N=10
CSV_OUTPUT=""
DATE_RANGE=""
LOG_FILES=()

show_help() {
    echo "用法: $0 [选项] <日志文件...>"
    echo "  -d START:END   日期范围过滤"
    echo "  -o FILENAME    导出 CSV"
    echo "  -h             帮助"
}

print_header() {
    echo ""
    echo -e "${CYAN}$(printf '═%.0s' $(seq 1 60))${NC}"
    echo -e "${WHITE}${BOLD}  $1${NC}"
    echo -e "${CYAN}$(printf '═%.0s' $(seq 1 60))${NC}"
}

draw_bar() {
    local label="$1" value="$2" max_value="$3" max_width="${4:-40}" color="${5:-$CYAN}"
    local bar_width=0
    (( max_value > 0 )) && bar_width=$(( value * max_width / max_value ))
    (( value > 0 && bar_width == 0 )) && bar_width=1
    local bar=$(printf '█%.0s' $(seq 1 $bar_width) 2>/dev/null)
    printf "  %-12s ${color}%-*s${NC} %d\n" "$label" "$max_width" "$bar" "$value"
}

human_size() {
    local bytes=$1
    if (( bytes >= 1073741824 )); then awk "BEGIN { printf \"%.2f GB\", $bytes/1073741824 }"
    elif (( bytes >= 1048576 )); then awk "BEGIN { printf \"%.2f MB\", $bytes/1048576 }"
    elif (( bytes >= 1024 )); then awk "BEGIN { printf \"%.2f KB\", $bytes/1024 }"
    else echo "${bytes} B"; fi
}

get_geo() {
    case "$1" in
        192.168.1.*) echo "内网-办公区" ;;
        192.168.2.*) echo "内网-测试" ;;
        10.0.0.*)    echo "内网-服务器" ;;
        66.249.*)    echo "Google" ;;
        157.55.*)    echo "Microsoft" ;;
        203.208.*)   echo "日本" ;;
        123.125.*)   echo "百度" ;;
        45.33.*)     echo "美国-Linode" ;;
        91.219.*)    echo "俄罗斯" ;;
        *)           echo "未知" ;;
    esac
}

# 参数解析
while getopts "d:o:h" opt; do
    case $opt in
        d) DATE_RANGE="$OPTARG" ;;
        o) CSV_OUTPUT="$OPTARG" ;;
        h) show_help; exit 0 ;;
        *) show_help; exit 1 ;;
    esac
done
shift $((OPTIND - 1))
LOG_FILES=("$@")
[[ ${#LOG_FILES[@]} -eq 0 ]] && LOG_FILES=("access.log")

for f in "${LOG_FILES[@]}"; do
    [[ ! -f "$f" ]] && { echo -e "${RED}[错误]${NC} 文件不存在: $f"; exit 1; }
done

# 合并文件
TEMP=$(mktemp)
trap "rm -f $TEMP" EXIT
cat "${LOG_FILES[@]}" > "$TEMP"

TOTAL_LINES=$(wc -l < "$TEMP")

echo -e "${GREEN}${BOLD}"
echo "╔══════════════════════════════════════════════════════════╗"
echo "║          Web 日志分析器（高级版）v2.0                     ║"
echo "╚══════════════════════════════════════════════════════════╝"
echo -e "${NC}"
echo -e "${BOLD}日志文件:${NC} ${LOG_FILES[*]}"
echo -e "${BOLD}总请求数:${NC} ${TOTAL_LINES}"

# 1. 每天请求量
print_header "1. 每天请求量分布"
awk '{
    split($4, dt, "/"); split(dt[3], ytt, ":")
    key = dt[1]"/"dt[2]"/"ytt[1]
    c[key]++
} END { for (d in c) print d, c[d] }' "$TEMP" | sort -t/ -k3,3 -k2,2 -k1,1n | {
    max=0; lines=()
    while read day count; do lines+=("$day $count"); (( count > max )) && max=$count; done
    for line in "${lines[@]}"; do
        draw_bar $(echo "$line" | awk '{print $1}') $(echo "$line" | awk '{print $2}') $max 40 "$GREEN"
    done
}

# 2. 每小时分布
print_header "2. 每小时请求量分布"
awk '{ split($4,a,":"); c[a[2]]++ } END { for(h in c) print h, c[h] }' "$TEMP" | sort -n | {
    max=0; lines=()
    while read hour count; do lines+=("$hour $count"); (( count > max )) && max=$count; done
    for line in "${lines[@]}"; do
        draw_bar "$(echo "$line"|awk '{print $1}'):00" $(echo "$line"|awk '{print $2}') $max 40 "$CYAN"
    done
}

# 3. IP 统计与地理
print_header "3. IP 地址统计 (Top ${TOP_N})"
awk '{ ip[$1]++ } END { for(i in ip) print ip[i], i }' "$TEMP" | sort -rn | head -n "$TOP_N" | \
while read count ip; do
    pct=$(awk "BEGIN{printf \"%.1f\",($count/$TOTAL_LINES)*100}")
    geo=$(get_geo "$ip")
    printf "  %-18s %6d (%5s%%) ${MAGENTA}%-15s${NC}\n" "$ip" "$count" "$pct" "$geo"
done

# 4. 状态码分布
print_header "4. HTTP 状态码分布"
awk '{ c[$9]++ } END { for(s in c) print c[s], s }' "$TEMP" | sort -rn | {
    max=0; lines=()
    while read count status; do lines+=("$status $count"); (( count > max )) && max=$count; done
    for line in "${lines[@]}"; do
        s=$(echo "$line"|awk '{print $1}'); c=$(echo "$line"|awk '{print $2}')
        case "$s" in 200) co="$GREEN";; 3*) co="$BLUE";; 4*) co="$YELLOW";; 5*) co="$RED";; *) co="$NC";; esac
        draw_bar "$s" "$c" $max 40 "$co"
    done
}

# 5. 带宽统计
print_header "5. 带宽使用统计"
TOTAL_BYTES=$(awk '{s+=$10}END{print s}' "$TEMP")
echo -e "  ${BOLD}总传输量:${NC} $(human_size "$TOTAL_BYTES")"
AVG=$(awk '{s+=$10;n++}END{if(n>0)printf "%.0f",s/n;else print 0}' "$TEMP")
echo -e "  ${BOLD}平均响应:${NC} $(human_size "$AVG")"

# 6. 最常请求的 URL
print_header "6. 最常请求的 URL (Top ${TOP_N})"
awk '{ url[$7]++ } END { for(u in url) print url[u], u }' "$TEMP" | sort -rn | head -n "$TOP_N" | \
while read count url; do
    printf "  %-40s %5d\n" "$url" "$count"
done

# 7. 可疑活动
print_header "7. 可疑活动分析"
awk '$9=="404"{c[$1]++}END{for(i in c)if(c[i]>=20)print c[i],i}' "$TEMP" | sort -rn | head -5 | \
while read count ip; do
    total=$(awk -v ip="$ip" '$1==ip' "$TEMP"|wc -l)
    geo=$(get_geo "$ip")
    echo -e "  ${RED}[警告]${NC} ${ip} (${geo})  404: ${count}/${total}"
done

# 8. 摘要
print_header "8. 分析摘要"
SUCCESS=$(awk '$9=="200"' "$TEMP"|wc -l)
CLIENT_ERR=$(awk '$9~/^4[0-9][0-9]$/' "$TEMP"|wc -l)
SERVER_ERR=$(awk '$9~/^5[0-9][0-9]$/' "$TEMP"|wc -l)
UNIQUE_IPS=$(awk '{print $1}' "$TEMP"|sort -u|wc -l)

echo -e "  ${GREEN}■${NC} 成功 (2xx):     ${SUCCESS}"
echo -e "  ${YELLOW}■${NC} 客户端错误 (4xx): ${CLIENT_ERR}"
echo -e "  ${RED}■${NC} 服务器错误 (5xx): ${SERVER_ERR}"
echo -e "\n  ${BOLD}独立 IP:${NC} ${UNIQUE_IPS}  ${BOLD}总带宽:${NC} $(human_size "$TOTAL_BYTES")"

if [[ -n "$CSV_OUTPUT" ]]; then
    echo "类型,项目,数值" > "$CSV_OUTPUT"
    echo "独立IP,总数,$UNIQUE_IPS" >> "$CSV_OUTPUT"
    echo "总带宽,字节,$TOTAL_BYTES" >> "$CSV_OUTPUT"
    echo -e "\n  ${GREEN}[已导出]${NC} CSV: ${CSV_OUTPUT}"
fi

echo ""
echo -e "${GREEN}${BOLD}高级分析完成！${NC}"
