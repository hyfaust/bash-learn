#!/bin/bash
# =============================================================================
# exercises.sh — 项目 02 练习题
# 用法: bash exercises.sh          # 运行练习
#       bash exercises.sh --answers # 查看并运行参考答案
# =============================================================================

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
CYAN='\033[0;36m'; BOLD='\033[1m'; NC='\033[0m'

MODE="practice"
[[ "${1:-}" == "--answers" ]] && MODE="answers"

# ============================================================================
# 练习 1：智能提示系统
# 连续猜错 3 次时，缩小提示范围
# ============================================================================
exercise_1() {
    echo -e "\n${YELLOW}━━━ 练习 1：智能提示 ━━━${NC}"

    if [[ "$MODE" == "answers" ]]; then
        echo -e "${GREEN}[参考答案]${NC}"
        local secret=$((RANDOM % 100 + 1))
        local attempts=0 low=1 high=100
        echo "(秘密数字是 $secret，用于演示)"

        for guess in 50 75 60 65 63 64 62 61; do
            ((attempts++))
            if ((guess == secret)); then
                echo "  猜 $guess → 🎉 猜对了！用了 ${attempts} 次"
                break
            elif ((guess < secret)); then
                echo "  猜 $guess → 小了"
                low=$((guess + 1))
            else
                echo "  猜 $guess → 大了"
                high=$((guess - 1))
            fi
            # 每 3 次缩小范围提示
            if ((attempts % 3 == 0)); then
                echo "  💡 提示: 答案在 $low ~ $high 之间"
            fi
        done
    else
        echo "实现智能提示：每猜错 3 次显示范围提示"
        # TODO: 在猜数字循环中添加:
        # if (( attempts % 3 == 0 )); then
        #     echo "提示: 答案在 $low ~ $high 之间"
        # fi
        echo "待实现..."
    fi
}

# ============================================================================
# 练习 2：多人模式
# 2-4 名玩家轮流猜数字
# ============================================================================
exercise_2() {
    echo -e "\n${YELLOW}━━━ 练习 2：多人模式 ━━━${NC}"

    if [[ "$MODE" == "answers" ]]; then
        echo -e "${GREEN}[参考答案]${NC}"
        local secret=$((RANDOM % 50 + 1))
        local players=("张三" "李四" "王五")
        local -a attempts=(0 0 0)
        local round=0 winner=""
        echo "(秘密数字是 $secret，用于演示)"

        # 模拟轮流猜
        local guesses=(25 40 35 42 38 39)
        local gi=0
        while [[ -z "$winner" ]] && ((gi < ${#guesses[@]})); do
            local pidx=$((round % ${#players[@]}))
            local pname="${players[$pidx]}"
            local guess="${guesses[$gi]}"
            attempts[$pidx]=$((attempts[pidx] + 1))
            echo "  ${pname} 猜 $guess"

            if ((guess == secret)); then
                winner="$pname"
                echo "  🎉 ${pname} 猜对了！用了 ${attempts[pidx]} 次"
            elif ((guess < secret)); then
                echo "    → 小了"
            else
                echo "    → 大了"
            fi
            round=$((round + 1))
            gi=$((gi + 1))
        done

        echo ""
        echo "  统计:"
        for i in "${!players[@]}"; do
            echo "    ${players[$i]}: 猜了 ${attempts[$i]} 次"
        done
    else
        # TODO: 用数组存储玩家名和猜测次数
        # players=("张三" "李四" "王五")
        # attempts=(0 0 0)
        # while [[ -z "$winner" ]]; do
        #     pidx=$((round % ${#players[@]}))
        #     read -rp "${players[$pidx]} 猜: " guess
        #     ...
        # done
        echo "待实现..."
    fi
}

# ============================================================================
# 练习 3：自定义范围
# 让玩家自己设定范围和最大次数
# ============================================================================
exercise_3() {
    echo -e "\n${YELLOW}━━━ 练习 3：自定义范围 ━━━${NC}"

    if [[ "$MODE" == "answers" ]]; then
        echo -e "${GREEN}[参考答案]${NC}"
        local min=1 max=200 max_attempts=7
        local secret=$((RANDOM % (max - min + 1) + min))
        echo "范围: $min ~ $max, 最多 $max_attempts 次"
        echo "(秘密数字是 $secret)"

        local guesses=(100 150 125 137 131 128 129)
        local attempts=0
        for guess in "${guesses[@]}"; do
            attempts=$((attempts + 1))
            if ((attempts > max_attempts)); then
                echo "  💀 超过最大次数！答案是 $secret"
                break
            fi
            if ((guess == secret)); then
                echo "  猜 $guess → 🎉 猜对了！用了 ${attempts} 次"
                break
            elif ((guess < secret)); then
                echo "  猜 $guess → 小了"
            else
                echo "  猜 $guess → 大了"
            fi
        done
    else
        # TODO: read -p "最小值: " min
        #       read -p "最大值: " max
        #       read -p "最大尝试次数: " max_attempts
        #       secret=$((RANDOM % (max - min + 1) + min))
        echo "待实现..."
    fi
}

# ============================================================================
# 练习 4：AI 猜数字（二分查找）
# 用户想数字，AI 用二分法猜
# ============================================================================
exercise_4() {
    echo -e "\n${YELLOW}━━━ 练习 4：AI 猜数字（二分查找）━━━${NC}"

    if [[ "$MODE" == "answers" ]]; then
        echo -e "${GREEN}[参考答案]${NC}"
        local secret=667  # 模拟用户心中想的数字
        echo "用户心中想的数字: $secret"
        local low=1 high=1000 attempts=0

        while ((low <= high)); do
            local mid=$(( (low + high) / 2 ))
            attempts=$((attempts + 1))

            if ((mid == secret)); then
                echo "  AI 猜 $mid → ✅ 对了！用了 ${attempts} 次"
                break
            elif ((mid < secret)); then
                echo "  AI 猜 $mid → 小了"
                low=$((mid + 1))
            else
                echo "  AI 猜 $mid → 大了"
                high=$((mid - 1))
            fi
        done
    else
        # TODO: 实现二分查找
        # low=1; high=1000
        # while ((low <= high)); do
        #     mid=$(( (low + high) / 2 ))
        #     read -p "是 $mid 吗? (大了/小了/对了): " answer
        #     case "$answer" in
        #         大了) high=$((mid - 1)) ;;
        #         小了) low=$((mid + 1)) ;;
        #         对了) echo "AI 猜对了！"; break ;;
        #     esac
        # done
        echo "待实现..."
    fi
}

# ============================================================================
# 练习 5：历史记录与排行榜
# 保存游戏结果到文件，支持查看排行榜
# ============================================================================
exercise_5() {
    echo -e "\n${YELLOW}━━━ 练习 5：历史记录与排行榜 ━━━${NC}"

    if [[ "$MODE" == "answers" ]]; then
        echo -e "${GREEN}[参考答案]${NC}"
        local score_file="/tmp/guess_scores.txt"

        # 模拟几轮游戏结果
        echo "张三 5" >> "$score_file"
        echo "李四 8" >> "$score_file"
        echo "王五 3" >> "$score_file"
        echo "赵六 6" >> "$score_file"
        echo "张三 4" >> "$score_file"

        echo "  📊 排行榜（猜测次数越少越好）:"
        echo "  ─────────────────────────"
        sort -t' ' -k2 -n "$score_file" | head -10 | \
            awk '{printf "  %-8s %d 次\n", $1, $2}'
        echo ""

        # 统计每人最佳成绩
        echo "  🏆 每人最佳:"
        awk '{
            if (!($1 in best) || $2 < best[$1]) best[$1] = $2
        } END {
            for (name in best) printf "  %-8s %d 次\n", name, best[name]
        }' "$score_file" | sort -t' ' -k2 -n

        rm -f "$score_file"
    else
        # TODO: 保存结果到文件
        # echo "$(whoami) $attempts" >> ~/.guess_scores.txt
        # echo "排行榜:"
        # sort -t' ' -k2 -n ~/.guess_scores.txt | head -10
        echo "待实现..."
    fi
}

# ============================================================================
# 主菜单
# ============================================================================
if [[ "$MODE" == "answers" ]]; then
    echo -e "${CYAN}${BOLD}项目 02 参考答案 — 猜数字游戏${NC}"
    exercise_1; exercise_2; exercise_3; exercise_4; exercise_5
    echo -e "\n${GREEN}全部完成！${NC}"
    exit 0
fi

echo -e "${CYAN}${BOLD}项目 02 练习题 — 猜数字游戏${NC}"
echo ""
echo "选择练习 (1-5):"
echo "  提示: bash exercises.sh --answers 查看所有参考答案"
read -rp "编号: " choice
case "$choice" in
    1) exercise_1 ;; 2) exercise_2 ;; 3) exercise_3 ;;
    4) exercise_4 ;; 5) exercise_5 ;;
    *) echo "无效选择"; exit 1 ;;
esac
