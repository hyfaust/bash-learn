#!/bin/bash
# =============================================================================
# exercises.sh — 项目 01 练习题
# 用法: bash exercises.sh          # 运行练习（学生填写 TODO）
#       bash exercises.sh --answers # 查看并运行参考答案
# =============================================================================

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
CYAN='\033[0;36m'; BOLD='\033[1m'; NC='\033[0m'

MODE="practice"
[[ "${1:-}" == "--answers" ]] && MODE="answers"

# ============================================================================
# 练习 1：温度转换器
# 要求：读取摄氏温度，转换为华氏温度
# 公式：F = C * 9/5 + 32
# ============================================================================
exercise_1() {
    echo -e "\n${YELLOW}━━━ 练习 1：温度转换器 ━━━${NC}"
    echo "公式: F = C × 9/5 + 32"

    if [[ "$MODE" == "answers" ]]; then
        echo -e "${GREEN}[参考答案]${NC}"
        # 用数组模拟多组输入
        for celsius in 0 25 37 100 -40; do
            fahrenheit=$(echo "scale=1; $celsius * 9 / 5 + 32" | bc)
            echo "  ${celsius}°C = ${fahrenheit}°F"
        done
    else
        read -rp "请输入摄氏温度: " celsius
        # TODO: 计算华氏温度并输出
        # fahrenheit=$(echo "scale=1; $celsius * 9 / 5 + 32" | bc)
        # echo "${celsius}°C = ${fahrenheit}°F"
        echo "待实现..."
    fi
}

# ============================================================================
# 练习 2：字符串反转
# 要求：编写函数，反转输入的字符串
# ============================================================================
exercise_2() {
    echo -e "\n${YELLOW}━━━ 练习 2：字符串反转 ━━━${NC}"

    if [[ "$MODE" == "answers" ]]; then
        echo -e "${GREEN}[参考答案]${NC}"
        # 方法 1：循环逐字符拼接
        reverse_loop() {
            local input="$1" reversed=""
            for ((i = ${#input} - 1; i >= 0; i--)); do
                reversed+="${input:i:1}"
            done
            echo "$reversed"
        }
        # 方法 2：使用 rev 命令
        reverse_cmd() { echo "$1" | rev; }

        for str in "Hello" "Bash脚本" "12345"; do
            echo "  循环反转 '$str': $(reverse_loop "$str")"
            echo "  rev 反转 '$str': $(reverse_cmd "$str")"
        done
    else
        # TODO: 实现字符串反转
        # reverse_string() {
        #     local input="$1" reversed=""
        #     for ((i=${#input}-1; i>=0; i--)); do
        #         reversed+="${input:i:1}"
        #     done
        #     echo "$reversed"
        # }
        echo "反转 'Hello': 待实现..."
    fi
}

# ============================================================================
# 练习 3：信息表格
# 要求：用 printf 打印带边框的个人信息表格
# ============================================================================
exercise_3() {
    echo -e "\n${YELLOW}━━━ 练习 3：信息表格 ━━━${NC}"

    if [[ "$MODE" == "answers" ]]; then
        echo -e "${GREEN}[参考答案]${NC}"
        print_row() { printf "| %-6s | %-4s | %-6s | %-6s |\n" "$1" "$2" "$3" "$4"; }
        divider="+--------+------+--------+--------+"
        echo "$divider"
        print_row "姓名" "年龄" "城市" "职业"
        echo "$divider"
        print_row "张三" "25" "北京" "工程师"
        print_row "李四" "30" "上海" "设计师"
        print_row "王五" "28" "深圳" "产品经理"
        echo "$divider"
    else
        # TODO: 用 printf 打印带边框的表格
        # printf "| %-6s | %-4s | %-6s | %-6s |\n" "姓名" "年龄" "城市" "职业"
        echo "待实现..."
    fi
}

# ============================================================================
# 练习 4：简易计算器
# 要求：读取两个数字和运算符，输出结果（用 bc 支持浮点）
# ============================================================================
exercise_4() {
    echo -e "\n${YELLOW}━━━ 练习 4：简易计算器 ━━━${NC}"

    if [[ "$MODE" == "answers" ]]; then
        echo -e "${GREEN}[参考答案]${NC}"
        calculate() {
            local num1="$1" op="$2" num2="$3"
            local result
            case "$op" in
                +|-|\*|/) result=$(echo "scale=2; $num1 $op $num2" | bc) ;;
                *) echo "  未知运算符: $op"; return 1 ;;
            esac
            echo "  $num1 $op $num2 = $result"
        }
        calculate 10 + 3
        calculate 15.5 - 4.2
        calculate 7 \* 8
        calculate 22 / 7
    else
        read -rp "输入第一个数字: " num1
        read -rp "输入运算符 (+, -, *, /): " op
        read -rp "输入第二个数字: " num2
        # TODO: 计算并输出结果
        # result=$(echo "scale=2; $num1 $op $num2" | bc)
        # echo "$num1 $op $num2 = $result"
        echo "待实现..."
    fi
}

# ============================================================================
# 练习 5：ASCII 艺术
# 要求：输出一个用字符组成的图案
# ============================================================================
exercise_5() {
    echo -e "\n${YELLOW}━━━ 练习 5：ASCII 艺术 ━━━${NC}"

    if [[ "$MODE" == "answers" ]]; then
        echo -e "${GREEN}[参考答案] — 菱形${NC}"
        local n=5
        # 上半部分（含中间行）
        for ((i = 1; i <= n; i++)); do
            local spaces=$((n - i))
            local stars=$((2 * i - 1))
            printf "%*s" "$spaces" ""
            for ((j = 0; j < stars; j++)); do printf "★"; done
            echo ""
        done
        # 下半部分
        for ((i = n - 1; i >= 1; i--)); do
            local spaces=$((n - i))
            local stars=$((2 * i - 1))
            printf "%*s" "$spaces" ""
            for ((j = 0; j < stars; j++)); do printf "★"; done
            echo ""
        done
    else
        # TODO: 用 echo 输出一个三角形、菱形或其他图案
        # for ((i=1; i<=5; i++)); do
        #     printf "%*s" $((5-i)) ""
        #     for ((j=0; j<2*i-1; j++)); do printf "*"; done
        #     echo ""
        # done
        echo "待实现..."
    fi
}

# ============================================================================
# 主菜单
# ============================================================================
if [[ "$MODE" == "answers" ]]; then
    echo -e "${CYAN}${BOLD}项目 01 参考答案 — Hello Bash${NC}"
    exercise_1; exercise_2; exercise_3; exercise_4; exercise_5
    echo -e "\n${GREEN}全部完成！${NC}"
    exit 0
fi

echo -e "${CYAN}${BOLD}项目 01 练习题 — Hello Bash${NC}"
echo ""
echo "选择要运行的练习 (1-5):"
echo "  提示: bash exercises.sh --answers 查看所有参考答案"
read -rp "请输入编号: " choice

case "$choice" in
    1) exercise_1 ;;
    2) exercise_2 ;;
    3) exercise_3 ;;
    4) exercise_4 ;;
    5) exercise_5 ;;
    *) echo "无效选择"; exit 1 ;;
esac
