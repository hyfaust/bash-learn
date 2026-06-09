#!/bin/bash
# =============================================================================
# generate_logs.sh — 生成模拟 Apache/Nginx 访问日志
# 格式：Apache Combined Log Format
# 用法：bash generate_logs.sh [输出目录] [行数]
# =============================================================================

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

OUTPUT_DIR="${1:-.}"
OUTPUT_FILE="${OUTPUT_DIR}/access.log"
NUM_LINES="${2:-1200}"

echo -e "${GREEN}[日志生成器]${NC} 开始生成模拟日志..."
echo -e "  输出文件: ${YELLOW}${OUTPUT_FILE}${NC}"
echo -e "  目标行数: ${YELLOW}${NUM_LINES}${NC}"

NORMAL_IPS=("192.168.1.100" "192.168.1.101" "192.168.1.102" "10.0.0.50" "10.0.0.51" "172.16.0.10" "172.16.0.11" "192.168.2.200" "192.168.3.15" "10.10.10.1")
BOT_IPS=("66.249.66.1" "66.249.66.2" "157.55.39.1" "203.208.60.1" "123.125.71.1")
SUSPICIOUS_IPS=("45.33.32.156" "185.130.44.108" "198.50.156.200" "91.219.237.1" "5.188.210.227")

NORMAL_URLS=("/" "/index.html" "/about.html" "/products.html" "/blog/" "/blog/post1.html" "/search?q=keyword" "/sitemap.xml")
STATIC_URLS=("/css/style.css" "/js/app.js" "/images/logo.png" "/favicon.ico")
API_URLS=("/api/v1/users" "/api/v1/products" "/api/v1/orders" "/api/v1/auth/login")
SUSPICIOUS_URLS=("/wp-admin/" "/wp-login.php" "/.env" "/.git/config" "/shell.php" "/xmlrpc.php" "/backup.sql")

METHODS=("GET" "GET" "GET" "GET" "GET" "POST" "POST" "PUT" "DELETE")
STATUS_NORMAL=(200 200 200 200 200 301 304 304 404)
STATUS_BOT=(200 200 200 301 304 403)
STATUS_SUSPICIOUS=(404 404 404 404 403 403 200 500 401)

USER_AGENTS=(
    "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 Chrome/120.0.0.0 Safari/537.36"
    "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 Chrome/120.0.0.0 Safari/537.36"
    "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 Chrome/120.0.0.0 Safari/537.36"
    "Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:121.0) Gecko/20100101 Firefox/121.0"
    "Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) Safari/604.1"
    "Mozilla/5.0 (compatible; Googlebot/2.1; +http://www.google.com/bot.html)"
    "Mozilla/5.0 (compatible; bingbot/2.0; +http://www.bing.com/bingbot.htm)"
)
BROWSER_COUNT=5

REFERERS=("-" "https://www.google.com/" "https://www.bing.com/search?q=example" "https://github.com/" "https://example.com/")

random_choice() { local arr=("$@"); echo "${arr[$((RANDOM % ${#arr[@]}))]}"; }

mkdir -p "$(dirname "${OUTPUT_FILE}")"

BASE_EPOCH=1779993600
current_epoch=$BASE_EPOCH

# Pre-compute base timestamp
base_ts=$(date -d "@${BASE_EPOCH}" +"%d/%b/%Y:%H:%M:%S %z" 2>/dev/null || echo "05/Jun/2026:12:00:00 +0800")
base_day=${base_ts:0:2}
base_mon=${base_ts:3:3}
base_year=${base_ts:7:4}
base_tz=${base_ts:20}

# Build all lines in memory then write once
output_lines=""
offset_seconds=0

for ((i = 0; i < NUM_LINES; i++)); do
    rand=$((RANDOM % 100))

    if (( rand < 70 )); then
        ip=$(random_choice "${NORMAL_IPS[@]}")
        url_type=$((RANDOM % 100))
        if (( url_type < 50 )); then url=$(random_choice "${NORMAL_URLS[@]}")
        elif (( url_type < 80 )); then url=$(random_choice "${STATIC_URLS[@]}")
        else url=$(random_choice "${API_URLS[@]}"); fi
        method=$(random_choice "${METHODS[@]}")
        status=$(random_choice "${STATUS_NORMAL[@]}")
        ua="${USER_AGENTS[$((RANDOM % BROWSER_COUNT))]}"
        referer=$(random_choice "${REFERERS[@]}")
    elif (( rand < 85 )); then
        ip=$(random_choice "${BOT_IPS[@]}")
        url=$(random_choice "${NORMAL_URLS[@]}")
        method="GET"
        status=$(random_choice "${STATUS_BOT[@]}")
        ua="${USER_AGENTS[$((BROWSER_COUNT + RANDOM % 2))]}"
        referer="-"
    else
        ip=$(random_choice "${SUSPICIOUS_IPS[@]}")
        url=$(random_choice "${SUSPICIOUS_URLS[@]}")
        method="GET"
        status=$(random_choice "${STATUS_SUSPICIOUS[@]}")
        ua="Mozilla/5.0 (compatible; Nmap Scripting Engine)"
        referer="-"
    fi

    # Compute time from offset (much faster than calling date 1200 times)
    total_secs=$((offset_seconds))
    hour=$((total_secs / 3600 % 24))
    minute=$((total_secs % 3600 / 60))
    second=$((total_secs % 60))
    printf -v timestamp "%s/%s/%s:%02d:%02d:%02d %s" "$base_day" "$base_mon" "$base_year" "$hour" "$minute" "$second" "$base_tz"

    case "$status" in
        200) size=$((RANDOM % 8192 + 256)) ;;
        301) size=$((RANDOM % 256 + 64)) ;;
        304) size=0 ;;
        403|404) size=$((RANDOM % 512 + 64)) ;;
        500) size=$((RANDOM % 128 + 32)) ;;
        *) size=$((RANDOM % 512 + 64)) ;;
    esac

    output_lines+="${ip} - - [${timestamp}] \"${method} ${url} HTTP/1.1\" ${status} ${size} \"${referer}\" \"${ua}\"
"
    offset_seconds=$((offset_seconds + RANDOM % 30 + 1))
done

printf '%s' "$output_lines" > "${OUTPUT_FILE}"

total_lines=$(wc -l < "${OUTPUT_FILE}")
file_size=$(du -h "${OUTPUT_FILE}" | cut -f1)

echo ""
echo -e "${GREEN}[完成]${NC} 日志文件生成成功！"
echo "  文件: ${OUTPUT_FILE}"
echo "  行数: ${total_lines}"
echo "  大小: ${file_size}"
echo ""
echo "使用: bash analyzer.sh ${OUTPUT_FILE}"
