#!/bin/bash
# =============================================================================
# greeting_card.sh — 个性化问候卡生成器
# 演示：read 输入、字符串操作、算术运算、printf 格式化、默认值
# =============================================================================

# --- 颜色定义 ---
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'  # 恢复默认颜色

echo -e "${CYAN}╔══════════════════════════════════════╗${NC}"
echo -e "${CYAN}║     个性化问候卡生成器 v1.0          ║${NC}"
echo -e "${CYAN}╚══════════════════════════════════════╝${NC}"
echo ""

# --- 收集用户信息 ---

# 使用 read -p 一行完成提示和读取
read -p "请输入你的名字: " name
# 使用默认值：如果用户直接回车，使用 "朋友"
name="${name:-朋友}"

read -p "你喜欢的颜色 (默认: 蓝色): " color
color="${color:-蓝色}"

read -p "请输入你的出生年份 (如 2000): " birth_year
birth_year="${birth_year:-2000}"

read -p "你的爱好 (默认: 编程): " hobby
hobby="${hobby:-编程}"

# --- 字符串操作演示 ---

# 转换为大写（使用 Bash 4+ 的 ${var^^} 语法）
name_upper="${name^^}"

# 获取名字长度
name_length="${#name}"

# 提取名字的前两个字符（如果够长的话）
if (( name_length >= 2 )); then
    name_prefix="${name:0:2}"
else
    name_prefix="$name"
fi

# --- 算术运算 ---

# 计算年龄
current_year=$(date '+%Y')
age=$((current_year - birth_year))

# 计算到下一个生日的天数（简化计算）
current_month_day=$(date '+%m%d')
if (( current_month_day > 0601 )); then
    days_to_birthday=$(( (365 - current_month_day + 0601) % 365 ))
else
    days_to_birthday=$(( 0601 - current_month_day ))
fi

# 有趣的数字
hours_lived=$((age * 365 * 24))
heartbeats=$((hours_lived * 75 * 60))  # 假设每分钟 75 次心跳

# --- 根据颜色设置 ANSI 颜色 ---
case "$color" in
    红*|red*)     card_color="$RED" ;;
    绿*|green*)   card_color="$GREEN" ;;
    黄*|yellow*)  card_color="$YELLOW" ;;
    蓝*|blue*)    card_color="$BLUE" ;;
    紫*|purple*)  card_color="$MAGENTA" ;;
    青*|cyan*)    card_color="$CYAN" ;;
    *)            card_color="$CYAN" ;;
esac

# --- 生成问候卡 ---

# 卡片宽度
width=42
border=$(printf '═%.0s' $(seq 1 $width))
line=$(printf '─%.0s' $(seq 1 $width))

echo ""
echo -e "${card_color}╔${border}╗${NC}"
echo -e "${card_color}║${NC}$(printf '%*s' $(( (width - 18) / 2 )) '')🎂 个人档案卡 🎂$(printf '%*s' $(( (width - 18 + 1) / 2 )) '')${card_color}║${NC}"
echo -e "${card_color}╠${border}╣${NC}"
printf "${card_color}║${NC}  %-12s: %-28s${card_color}║${NC}\n" "姓名" "$name"
printf "${card_color}║${NC}  %-12s: %-28s${card_color}║${NC}\n" "大写显示" "$name_upper"
printf "${card_color}║${NC}  %-12s: %-28s${card_color}║${NC}\n" "名字长度" "${name_length} 个字符"
printf "${card_color}║${NC}  %-12s: %-28s${card_color}║${NC}\n" "名字前缀" "${name_prefix}..."
printf "${card_color}║${NC}  ${line}${card_color}║${NC}\n"
printf "${card_color}║${NC}  %-12s: %-28s${card_color}║${NC}\n" "出生年份" "$birth_year"
printf "${card_color}║${NC}  %-12s: %-28s${card_color}║${NC}\n" "年龄" "$age 岁"
printf "${card_color}║${NC}  %-12s: %-28s${card_color}║${NC}\n" "已生活" "$hours_lived 小时"
printf "${card_color}║${NC}  %-12s: %-28s${card_color}║${NC}\n" "心跳次数" "$heartbeats 次 (估)"
printf "${card_color}║${NC}  ${line}${card_color}║${NC}\n"
printf "${card_color}║${NC}  %-12s: %-28s${card_color}║${NC}\n" "喜欢的颜色" "$color"
printf "${card_color}║${NC}  %-12s: %-28s${card_color}║${NC}\n" "爱好" "$hobby"
echo -e "${card_color}╠${border}╣${NC}"

# 生成随机祝福语
blessings=(
    "愿你代码无 Bug，生活有光！"
    "愿你每次 commit 都一次通过！"
    "愿你 Shell 脚本永远不报错！"
    "愿你终端里永远是绿色的 ✓"
    "愿你的 PATH 里永远有好运！"
)
random_index=$((RANDOM % ${#blessings[@]}))
blessing="${blessings[$random_index]}"

echo -e "${card_color}║${NC}$(printf '%*s' $(( (width - ${#blessing}) / 2 )) '')${blessing}$(printf '%*s' $(( (width - ${#blessing} + 1) / 2 )) '')${card_color}║${NC}"
echo -e "${card_color}╚${border}╝${NC}"

echo ""
echo -e "${GREEN}卡片生成完毕！${NC}"
echo -e "生成时间: $(date '+%Y-%m-%d %H:%M:%S')"
