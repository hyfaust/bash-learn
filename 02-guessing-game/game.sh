#!/bin/bash
# =============================================================================
# game.sh — 猜数字游戏（基础版）
# 演示：case、if/else、while循环、RANDOM、输入验证、计分
# =============================================================================

# --- 颜色定义 ---
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

# --- 游戏统计 ---
games_played=0
games_won=0

# --- 显示欢迎信息 ---
show_welcome() {
    echo -e "${CYAN}"
    echo "╔══════════════════════════════════════╗"
    echo "║        🎮 猜数字游戏 v1.0 🎮        ║"
    echo "║                                      ║"
    echo "║  我想了一个数字，你能猜到吗？         ║"
    echo "╚══════════════════════════════════════╝"
    echo -e "${NC}"
}

# --- 难度选择（使用 case） ---
select_difficulty() {
    echo -e "${YELLOW}请选择难度:${NC}"
    echo "  1) 简单   (1 ~ 50,   最多 7 次)"
    echo "  2) 中等   (1 ~ 100,  最多 10 次)"
    echo "  3) 困难   (1 ~ 500,  最多 12 次)"
    echo ""

    read -rp "请输入选项 (1/2/3): " choice

    case "$choice" in
        1)  MIN=1;   MAX=50;   MAX_ATTEMPTS=7 ;;
        2)  MIN=1;   MAX=100;  MAX_ATTEMPTS=10 ;;
        3)  MIN=1;   MAX=500;  MAX_ATTEMPTS=12 ;;
        *)  echo -e "${YELLOW}无效选择，默认中等难度${NC}"
            MIN=1; MAX=100; MAX_ATTEMPTS=10 ;;
    esac

    SECRET=$((RANDOM % (MAX - MIN + 1) + MIN))
}

# --- 输入验证 ---
validate_input() {
    local input="$1"

    # 检查是否为空
    if [[ -z "$input" ]]; then
        echo -e "${RED}请输入一个数字！${NC}"
        return 1
    fi

    # 检查是否为数字（使用正则匹配）
    if [[ ! "$input" =~ ^[0-9]+$ ]]; then
        echo -e "${RED}请输入有效的数字！${NC}"
        return 1
    fi

    # 检查范围
    if (( input < MIN || input > MAX )); then
        echo -e "${RED}请输入 ${MIN} ~ ${MAX} 之间的数字！${NC}"
        return 1
    fi

    return 0
}

# --- 游戏主循环 ---
play_game() {
    local attempts=0
    local guess

    echo ""
    echo -e "${GREEN}我想了一个 ${MIN} ~ ${MAX} 之间的数字${NC}"
    echo -e "你有 ${MAX_ATTEMPTS} 次机会，开始猜吧！"
    echo ""

    # while 循环：在最大尝试次数内
    while (( attempts < MAX_ATTEMPTS )); do
        # 计算剩余次数
        local remaining=$((MAX_ATTEMPTS - attempts))

        if ! read -rp "第 $((attempts + 1)) 次猜测 (剩余 ${remaining} 次): " guess; then
            echo ""
            echo -e "${RED}输入结束，游戏退出${NC}"
            echo -e "${RED}答案是: ${SECRET}${NC}"
            return 1
        fi

        # 输入验证
        if ! validate_input "$guess"; then
            continue  # 输入无效，不计入次数
        fi

        ((attempts++))

        # 比较猜测与答案
        if (( guess == SECRET )); then
            echo ""
            echo -e "${GREEN}🎉 恭喜你猜对了！答案就是 ${SECRET}${NC}"
            echo -e "${GREEN}你用了 ${attempts} 次猜中${NC}"

            # 计算分数
            local score=$(( (MAX_ATTEMPTS - attempts + 1) * 100 / MAX_ATTEMPTS ))
            echo -e "${YELLOW}得分: ${score} 分${NC}"

            ((games_won++))
            return 0

        elif (( guess < SECRET )); then
            echo -e "${CYAN}📈 小了！再大一点${NC}"
        else
            echo -e "${CYAN}📉 大了！再小一点${NC}"
        fi

        # 提示：剩余次数不多时给出范围提示
        if (( remaining <= 3 )); then
            echo -e "${YELLOW}💡 提示：答案在 ${MIN} ~ ${MAX} 之间${NC}"
        fi
    done

    # 用完所有次数
    echo ""
    echo -e "${RED}😢 很遗憾，你没有猜到！${NC}"
    echo -e "${RED}答案是: ${SECRET}${NC}"
    return 1
}

# --- 主程序 ---
main() {
    show_welcome

    while true; do
        select_difficulty
        play_game
        ((games_played++))

        echo ""
        echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        echo -e "统计: 玩了 ${games_played} 局, 赢了 ${games_won} 局"
        echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        echo ""

        # 是否再来一局
        if ! read -rp "再来一局? [Y/n] " again; then
            break
        fi
        case "$again" in
            n|N|no|NO) break ;;
        esac
    done

    echo ""
    echo -e "${GREEN}感谢游玩！最终统计:${NC}"
    echo -e "  总局数: ${games_played}"
    echo -e "  胜利数: ${games_won}"
    if (( games_played > 0 )); then
        local win_rate=$(( games_won * 100 / games_played ))
        echo -e "  胜率:   ${win_rate}%"
    fi
    echo ""
}

main
