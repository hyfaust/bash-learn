#!/bin/bash
# =============================================================================
# exercises.sh — 项目 04 练习题
# 用法: bash exercises.sh [access.log]        # 运行练习
#       bash exercises.sh [access.log] --answers # 查看并运行参考答案
# =============================================================================

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
CYAN='\033[0;36m'; BOLD='\033[1m'; NC='\033[0m'

MODE="practice"
LOG_FILE="access.log"
for arg in "$@"; do
    [[ "$arg" == "--answers" ]] && MODE="answers"
    [[ "$arg" != "--answers" && -n "$arg" ]] && LOG_FILE="$arg"
done

if [[ ! -f "$LOG_FILE" ]]; then
    echo -e "${RED}[错误]${NC} 日志文件不存在: $LOG_FILE"
    echo "请先运行: bash generate_logs.sh"
    exit 1
fi

echo -e "${CYAN}${BOLD}项目 04 练习题 — 日志分析器${NC}"
echo "日志文件: $LOG_FILE ($(wc -l < "$LOG_FILE") 行)"
echo ""

# ============================================================================
# 练习 1：grep 统计 404 数量
# ============================================================================
exercise_1() {
    echo -e "${YELLOW}━━━ 练习 1: grep 统计 404 数量 ━━━${NC}"

    if [[ "$MODE" == "answers" ]]; then
        echo -e "${GREEN}[参考答案]${NC}"
        count_404=$(grep -c '" 404 ' "$LOG_FILE")
        echo "  404 数量: $count_404"
        echo ""
        echo "  命令: grep -c '\" 404 ' $LOG_FILE"
        echo "  说明: grep -c 统计匹配行数"
    else
        echo "要求：使用 grep -c 统计 404 状态码的总数量"
        count_404=$(echo "TODO: 用你的 grep 命令替换")
        echo "  404 数量: ${count_404}"
    fi
}

# ============================================================================
# 练习 2：awk 提取 POST 请求 URL（去重）
# ============================================================================
exercise_2() {
    echo -e "\n${YELLOW}━━━ 练习 2: awk 提取 POST 请求 URL ━━━${NC}"

    if [[ "$MODE" == "answers" ]]; then
        echo -e "${GREEN}[参考答案]${NC}"
        post_urls=$(awk '$6 ~ /POST/ {print $7}' "$LOG_FILE" | sort -u)
        echo "$post_urls" | head -10 | while IFS= read -r url; do
            echo "  $url"
        done
        echo "  (共 $(echo "$post_urls" | wc -l) 个唯一 URL)"
        echo ""
        echo "  命令: awk '\$6 ~ /POST/ {print \$7}' $LOG_FILE | sort -u"
    else
        echo "要求：使用 awk 提取 POST 请求的 URL（去重）"
        post_urls=$(echo "TODO: 用你的 awk 命令替换")
        echo "$post_urls" | head -5
    fi
}

# ============================================================================
# 练习 3：sed 替换内部 IP
# ============================================================================
exercise_3() {
    echo -e "\n${YELLOW}━━━ 练习 3: sed 替换内部 IP ━━━${NC}"

    if [[ "$MODE" == "answers" ]]; then
        echo -e "${GREEN}[参考答案]${NC}"
        echo "  替换前 (前 3 行):"
        head -3 "$LOG_FILE" | sed 's/^/    /'
        echo ""
        echo "  替换后 (前 3 行):"
        sed -E 's/192\.168\.[0-9]+\.[0-9]+/INTERNAL_IP/g; s/10\.0\.[0-9]+\.[0-9]+/INTERNAL_IP/g; s/172\.16\.[0-9]+\.[0-9]+/INTERNAL_IP/g' "$LOG_FILE" | head -3 | sed 's/^/    /'
        echo ""
        echo "  命令: sed -E 's/192\\.168\\.[0-9]+\\.[0-9]+/INTERNAL_IP/g' $LOG_FILE"
    else
        echo "要求：用 sed 将 192.168.x.x 替换为 INTERNAL"
        sanitized=$(echo "TODO: 用你的 sed 命令替换")
        echo "$sanitized" | head -3
    fi
}

# ============================================================================
# 练习 4：管道组合 — /login.html 访问者统计
# ============================================================================
exercise_4() {
    echo -e "\n${YELLOW}━━━ 练习 4: 管道组合 — /login.html 访问者 ━━━${NC}"

    if [[ "$MODE" == "answers" ]]; then
        echo -e "${GREEN}[参考答案]${NC}"
        login_visitors=$(grep '/login.html' "$LOG_FILE" | awk '{print $1}' | sort | uniq -c | sort -rn)
        if [[ -n "$login_visitors" ]]; then
            echo "$login_visitors" | head -10 | while read -r count ip; do
                printf "  %-18s %s 次\n" "$ip" "$count"
            done
        else
            echo "  (日志中没有 /login.html 访问记录)"
            echo "  尝试其他 URL:"
            grep -oP 'GET \K[^ ]+' "$LOG_FILE" | sort | uniq -c | sort -rn | head -5 | while read -r count url; do
                printf "  %-30s %s 次\n" "$url" "$count"
            done
        fi
        echo ""
        echo "  命令: grep '/login.html' $LOG_FILE | awk '{print \$1}' | sort | uniq -c | sort -rn"
    else
        echo "要求：统计访问 /login.html 的 IP 及次数"
        login_visitors=$(echo "TODO: 用你的管道命令替换")
        echo "$login_visitors" | head -5
    fi
}

# ============================================================================
# 练习 5：浏览器统计
# ============================================================================
exercise_5() {
    echo -e "\n${YELLOW}━━━ 练习 5: 浏览器统计 ━━━${NC}"

    if [[ "$MODE" == "answers" ]]; then
        echo -e "${GREEN}[参考答案]${NC}"
        chrome=$(grep -c 'Chrome' "$LOG_FILE")
        firefox=$(grep -c 'Firefox' "$LOG_FILE")
        safari=$(grep -c 'Safari' "$LOG_FILE" | xargs -I{} sh -c 'echo $(({} - $(grep -c "Chrome" "'"$LOG_FILE"'")))')
        echo "  Chrome:  $chrome"
        echo "  Firefox: $firefox"
        echo "  Safari:  $safari (去除 Chrome 中含 Safari 的)"
        echo ""
        echo "  命令: grep -c 'Chrome' $LOG_FILE"
        echo "  注意: Chrome 的 UA 也包含 'Safari'，需要排除"
    else
        echo "要求：统计 Chrome/Firefox/Safari 的数量"
        chrome=$(echo "TODO")
        firefox=$(echo "TODO")
        safari=$(echo "TODO")
        echo "  Chrome: $chrome  Firefox: $firefox  Safari: $safari"
    fi
}

# ============================================================================
# 主逻辑
# ============================================================================
if [[ "$MODE" == "answers" ]]; then
    exercise_1; exercise_2; exercise_3; exercise_4; exercise_5
    echo -e "\n${GREEN}全部完成！${NC}"
    exit 0
fi

exercise_1; exercise_2; exercise_3; exercise_4; exercise_5
echo ""
echo "  提示: bash exercises.sh --answers 查看所有参考答案"
