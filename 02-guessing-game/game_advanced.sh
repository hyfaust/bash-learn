#!/bin/bash
# =============================================================================
# game_advanced.sh — 猜数字游戏（高级版）
# 演示：select菜单、SECONDS计时、ANSI颜色、排行榜文件、循环增强
# =============================================================================

# --- 颜色定义 ---
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

# --- 排行榜文件 ---
LEADERBOARD="/tmp/guessing_game_leaderboard.txt"
touch "$LEADERBOARD" 2>/dev/null

# --- 游戏统计 ---
total_games=0
total_wins=0

# --- 工具函数 ---
print_header() {
    echo -e "${MAGENTA}${BOLD}"
    echo "╔══════════════════════════════════════════════╗"
    echo "║     🎮 猜数字游戏 - 高级版 v2.0 🎮         ║"
    echo "║     带排行榜 · 计时 · 多难度模式            ║"
    echo "╚══════════════════════════════════════════════╝"
    echo -e "${NC}"
}

# --- 主菜单（使用 select） ---
show_menu() {
    PS3=$'\n请选择操作 > '
    local options=("开始游戏" "查看排行榜" "游戏规则" "退出")

    echo -e "${YELLOW}${BOLD}主菜单${NC}"
    select opt in "${options[@]}"; do
        case "$opt" in
            "开始游戏")     return 0 ;;
            "查看排行榜")   show_leaderboard; return 0 ;;
            "游戏规则")     show_rules; return 0 ;;
            "退出")         echo -e "${GREEN}再见！${NC}"; exit 0 ;;
            *)              echo -e "${RED}无效选择，请重试${NC}" ;;
        esac
    done
}

# --- 游戏规则 ---
show_rules() {
    echo ""
    echo -e "${CYAN}${BOLD}📋 游戏规则${NC}"
    echo "  1. 电脑随机生成一个数字"
    echo "  2. 你来猜这个数字"
    echo "  3. 每次猜测后会提示'大了'或'小了'"
    echo "  4. 在限定次数内猜对即获胜"
    echo "  5. 分数 = (剩余次数 / 总次数) × 100"
    echo ""
    echo -e "${YELLOW}难度等级:${NC}"
    printf "  %-8s %-15s %-10s\n" "等级" "范围" "最大次数"
    printf "  %-8s %-15s %-10s\n" "简单" "1 ~ 50" "7 次"
    printf "  %-8s %-15s %-10s\n" "中等" "1 ~ 100" "10 次"
    printf "  %-8s %-15s %-10s\n" "困难" "1 ~ 500" "15 次"
    printf "  %-8s %-15s %-10s\n" "噩梦" "1 ~ 1000" "15 次"
    echo ""
}

# --- 选择难度 ---
select_difficulty() {
    echo -e "${YELLOW}${BOLD}选择难度${NC}"
    local difficulty_names=("简单" "中等" "困难" "噩梦")
    local difficulty_ranges=(50 100 500 1000)
    local difficulty_attempts=(7 10 15 15)

    PS3=$'\n选择难度 > '
    select diff in "${difficulty_names[@]}"; do
        case "$diff" in
            "简单")  idx=0; break ;;
            "中等")  idx=1; break ;;
            "困难")  idx=2; break ;;
            "噩梦")  idx=3; break ;;
            *)       echo -e "${RED}无效选择${NC}" ;;
        esac
    done

    MAX=${difficulty_ranges[$idx]}
    MAX_ATTEMPTS=${difficulty_attempts[$idx]}
    DIFF_NAME="$diff"
    SECRET=$((RANDOM % MAX + 1))

    echo -e "\n${GREEN}已选择: ${DIFF_NAME} (1 ~ ${MAX}, ${MAX_ATTEMPTS} 次机会)${NC}\n"
}

# --- 输入验证 ---
validate_guess() {
    local input="$1"
    if [[ -z "$input" ]]; then
        echo -e "${RED}请输入数字！${NC}"; return 1
    fi
    if [[ ! "$input" =~ ^[0-9]+$ ]]; then
        echo -e "${RED}请输入有效数字！${NC}"; return 1
    fi
    if (( input < 1 || input > MAX )); then
        echo -e "${RED}范围: 1 ~ ${MAX}${NC}"; return 1
    fi
    return 0
}

# --- 显示进度条 ---
show_progress() {
    local current=$1 total=$2 width=20
    local filled=$((current * width / total))
    local empty=$((width - filled))
    local bar=""
    for ((i = 0; i < filled; i++)); do bar+="█"; done
    for ((i = 0; i < empty; i++)); do bar+="░"; done
    printf "  进度: [%s] %d/%d\n" "$bar" "$current" "$total"
}

# --- 游戏主循环 ---
play_round() {
    local attempts=0 guess
    local hint_min=1 hint_max=$MAX

    # 使用 SECONDS 计时
    SECONDS=0

    echo -e "${CYAN}我想了一个 1 ~ ${MAX} 之间的数字，开始猜！${NC}\n"

    while (( attempts < MAX_ATTEMPTS )); do
        local remaining=$((MAX_ATTEMPTS - attempts))
        show_progress "$attempts" "$MAX_ATTEMPTS"

        if ! read -rp "🎯 第 $((attempts + 1)) 次 [剩余 ${remaining}]: " guess; then
            echo ""; echo -e "${RED}输入结束，答案是 ${SECRET}${NC}"; return 1
        fi

        if ! validate_guess "$guess"; then
            continue
        fi

        ((attempts++))

        if (( guess == SECRET )); then
            local elapsed=$SECONDS
            local score=$(( (MAX_ATTEMPTS - attempts + 1) * 100 / MAX_ATTEMPTS ))

            echo ""
            echo -e "${GREEN}${BOLD}🎉 恭喜猜对！答案是 ${SECRET}${NC}"
            echo -e "${GREEN}  次数: ${attempts}/${MAX_ATTEMPTS}${NC}"
            echo -e "${GREEN}  耗时: ${elapsed} 秒${NC}"
            echo -e "${YELLOW}  得分: ${score} 分${NC}"

            ((total_wins++))

            # 保存到排行榜
            echo "${score}|${DIFF_NAME}|${attempts}|${elapsed}秒|$(date '+%m-%d %H:%M')" >> "$LEADERBOARD"

            # 显示评级
            if (( score >= 90 )); then
                echo -e "${MAGENTA}  评级: ⭐⭐⭐ 大师级！${NC}"
            elif (( score >= 70 )); then
                echo -e "${CYAN}  评级: ⭐⭐ 高手${NC}"
            elif (( score >= 50 )); then
                echo -e "${GREEN}  评级: ⭐ 不错${NC}"
            else
                echo -e "${YELLOW}  评级: 勉强过关${NC}"
            fi
            return 0
        fi

        if (( guess < SECRET )); then
            echo -e "${BLUE}  📈 小了！${NC}"
            (( guess > hint_min )) && hint_min=$guess
        else
            echo -e "${RED}  📉 大了！${NC}"
            (( guess < hint_max )) && hint_max=$guess
        fi

        # 智能提示
        if (( remaining <= 3 )); then
            echo -e "${YELLOW}  💡 提示: ${hint_min} ~ ${hint_max}${NC}"
        fi
    done

    local elapsed=$SECONDS
    echo ""
    echo -e "${RED}😢 游戏结束！答案是 ${SECRET}${NC}"
    echo -e "${RED}  耗时: ${elapsed} 秒${NC}"
    return 1
}

# --- 排行榜 ---
show_leaderboard() {
    echo ""
    echo -e "${YELLOW}${BOLD}🏆 排行榜 Top 10${NC}"
    echo ""

    if [[ ! -s "$LEADERBOARD" ]]; then
        echo "  暂无记录，快去玩一局吧！"
        echo ""
        return
    fi

    printf "  ${BOLD}%-4s %-6s %-8s %-6s %-6s %-12s${NC}\n" "排名" "分数" "难度" "次数" "耗时" "时间"
    echo "  ──────────────────────────────────────"

    local rank=0
    sort -t'|' -k1 -rn "$LEADERBOARD" | head -10 | while IFS='|' read -r score diff attempts elapsed time; do
        ((rank++))
        printf "  %-4d %-6d %-8s %-6s %-6s %-12s\n" "$rank" "$score" "$diff" "$attempts" "$elapsed" "$time"
    done

    echo ""
}

# --- 主程序 ---
main() {
    print_header

    while true; do
        show_menu
        echo ""

        select_difficulty
        play_round
        ((total_games++))

        echo ""
        echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        echo -e "总局: ${total_games} | 胜: ${total_wins}"
        echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        echo ""

        if ! read -rp "继续游戏? [Y/n] " again; then
            break
        fi
        [[ "$again" =~ ^[Nn] ]] && break
    done

    echo ""
    echo -e "${GREEN}感谢游玩！${NC}"
    if (( total_games > 0 )); then
        echo -e "  胜率: $(( total_wins * 100 / total_games ))%"
    fi
    show_leaderboard
}

main
