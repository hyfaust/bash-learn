#!/bin/bash
# =============================================================================
# hello.sh — Hello Bash 入门脚本
# 演示：变量定义、echo 输出、算术运算、printf 格式化
# =============================================================================

# --- 1. 变量定义与使用 ---
name="Bash 学习者"
version=5
greeting="Hello, ${name}!"

echo "=== 变量演示 ==="
echo "$greeting"
echo "你正在学习 Bash 版本 $version"
echo ""

# --- 2. echo 的各种用法 ---
echo "=== echo 演示 ==="
echo "普通输出（自动换行）"
echo -n "不换行输出，"
echo "接着的文本会接在同一行"
echo -e "使用 \\t 制表符\t对齐文本"
echo -e "使用 \\n 换行符\n分成两行"
echo ""

# --- 3. 算术运算：计算你活了多少天 ---
echo "=== 算术运算演示 ==="
age=25  # 假设年龄为 25 岁
days_alive=$((age * 365))
hours_alive=$((days_alive * 24))
seconds_alive=$((hours_alive * 3600))

echo "假设你 $age 岁："
echo "  你已经活了大约 $days_alive 天"
echo "  也就是 $hours_alive 小时"
echo "  也就是 $seconds_alive 秒"
echo ""

# 百分比计算
total_questions=100
correct=85
percentage=$((correct * 100 / total_questions))
echo "考试成绩: $correct/$total_questions = ${percentage}%"
echo ""

# --- 4. readonly 和 unset ---
echo "=== readonly 演示 ==="
readonly SCHOOL="Bash 大学"
echo "学校: $SCHOOL"
# SCHOOL="其他"  # 取消注释会报错: readonly variable

temp_var="临时数据"
echo "临时变量: $temp_var"
unset temp_var
echo "unset 后: '${temp_var:-已删除}'"
echo ""

# --- 5. printf 格式化输出 ---
echo "=== printf 演示 ==="
printf "%-15s %10s %12s\n" "水果" "单价(元)" "数量"
printf "%-15s %10s %12s\n" "---" "---" "---"
printf "%-15s %10.2f %12d\n" "苹果" 5.50 10
printf "%-15s %10.2f %12d\n" "香蕉" 3.80 20
printf "%-15s %10.2f %12d\n" "橙子" 4.20 15
echo ""

# 用 printf 绘制进度条
echo -n "进度: ["
for i in $(seq 1 20); do
    printf "█"
    sleep 0.05
done
printf "] 100%%\n"
