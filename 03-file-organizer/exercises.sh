#!/bin/bash
# =============================================================================
# exercises.sh — 项目 03 练习题
# 用法: bash exercises.sh          # 运行练习
#       bash exercises.sh --answers # 查看并运行参考答案
# =============================================================================

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
CYAN='\033[0;36m'; BOLD='\033[1m'; NC='\033[0m'

MODE="practice"
[[ "${1:-}" == "--answers" ]] && MODE="answers"

# ============================================================================
# 练习 1：撤销功能
# 读取日志中的移动记录，将文件移回原位
# ============================================================================
exercise_1() {
    echo -e "\n${YELLOW}━━━ 练习 1：基于日志撤销 ━━━${NC}"

    if [[ "$MODE" == "answers" ]]; then
        echo -e "${GREEN}[参考答案]${NC}"
        # 创建测试环境
        local tmpdir
        tmpdir=$(mktemp -d)
        mkdir -p "$tmpdir/images" "$tmpdir/documents"
        echo "photo" > "$tmpdir/images/photo.jpg"
        echo "report" > "$tmpdir/documents/report.txt"

        # 模拟日志
        local logfile="$tmpdir/.organizer.log"
        echo "移动: $tmpdir/photo.jpg -> $tmpdir/images/photo.jpg" > "$logfile"
        echo "移动: $tmpdir/report.txt -> $tmpdir/documents/report.txt" >> "$logfile"

        echo "  日志内容:"
        cat "$logfile" | sed 's/^/    /'

        echo ""
        echo "  撤销操作:"
        while IFS=' -> ' read -r action src arrow dest; do
            if [[ "$action" == "移动:" && -e "$dest" ]]; then
                mkdir -p "$(dirname "$src")"
                mv "$dest" "$src"
                echo -e "  ${GREEN}[恢复]${NC} $(basename "$dest") → $(dirname "$src")/"
            fi
        done < <(tac "$logfile")

        echo "  验证: $(ls "$tmpdir"/*.jpg "$tmpdir"/*.txt 2>/dev/null | wc -l) 个文件在原位"
        rm -rf "$tmpdir"
    else
        # TODO: 读取日志，反向移动文件
        # while IFS=' -> ' read -r action src arrow dest; do
        #     if [[ "$action" == "移动:" && -e "$dest" ]]; then
        #         mv "$dest" "$src"
        #     fi
        # done < <(tac "$LOG_FILE")
        echo "待实现..."
    fi
}

# ============================================================================
# 练习 2：从配置文件读取规则
# 格式: *.psd=design  *.sketch=design
# ============================================================================
exercise_2() {
    echo -e "\n${YELLOW}━━━ 练习 2：自定义规则 ━━━${NC}"

    if [[ "$MODE" == "answers" ]]; then
        echo -e "${GREEN}[参考答案]${NC}"
        local rules_file
        rules_file=$(mktemp)
        cat > "$rules_file" <<'EOF'
*.psd=design
*.sketch=design
*.fig=design
*.mp4=video
*.mov=video
*.log=temp
*.tmp=temp
EOF
        echo "  规则文件:"
        cat "$rules_file" | sed 's/^/    /'

        # 解析规则到关联数组
        declare -A rules
        while IFS='=' read -r pattern dest; do
            [[ "$pattern" =~ ^#.*$ || -z "$pattern" ]] && continue
            rules["$pattern"]="$dest"
        done < "$rules_file"

        # 测试匹配
        echo ""
        echo "  测试文件匹配:"
        for test_file in "photo.psd" "design.sketch" "movie.mp4" "readme.txt"; do
            local ext="${test_file##*.}"
            local matched="others"
            for pattern in "${!rules[@]}"; do
                local pext="${pattern##*.}"
                if [[ "$ext" == "$pext" ]]; then
                    matched="${rules[$pattern]}"
                    break
                fi
            done
            echo "    $test_file → $matched"
        done

        rm -f "$rules_file"
    else
        # TODO: 读取配置文件到关联数组
        # declare -A rules
        # while IFS='=' read -r pattern dest; do
        #     rules["$pattern"]="$dest"
        # done < rules.conf
        echo "待实现..."
    fi
}

# ============================================================================
# 练习 3：生成 cron 任务
# ============================================================================
exercise_3() {
    echo -e "\n${YELLOW}━━━ 练习 3：定时整理 ━━━${NC}"

    if [[ "$MODE" == "answers" ]]; then
        echo -e "${GREEN}[参考答案]${NC}"
        local script_path
        script_path=$(readlink -f "$(dirname "$0")/organizer.sh" 2>/dev/null || echo "/path/to/organizer.sh")

        echo "  生成 crontab 配置:"
        echo ""
        echo "  # 每天凌晨 3 点整理下载目录"
        echo "  0 3 * * * $script_path --by-type ~/Downloads >> /tmp/organizer.log 2>&1"
        echo ""
        echo "  # 每周一凌晨整理桌面"
        echo "  0 4 * * 1 $script_path --by-type ~/Desktop >> /tmp/organizer.log 2>&1"
        echo ""
        echo "  安装方法:"
        echo "    crontab -e  # 编辑后粘贴上述行"
        echo "    crontab -l  # 查看已安装的任务"
    else
        # TODO: 输出 crontab 行
        # echo "0 3 * * * /path/to/organizer.sh ~/Downloads"
        echo "待实现..."
    fi
}

# ============================================================================
# 练习 4：整理后统计报告
# 统计每个分类目录的文件数和总大小
# ============================================================================
exercise_4() {
    echo -e "\n${YELLOW}━━━ 练习 4：统计报告 ━━━${NC}"

    if [[ "$MODE" == "answers" ]]; then
        echo -e "${GREEN}[参考答案]${NC}"
        # 创建模拟目录
        local tmpdir
        tmpdir=$(mktemp -d)
        mkdir -p "$tmpdir"/{images,documents,videos,code}
        for i in 1 2 3; do echo "img" > "$tmpdir/images/photo$i.jpg"; done
        for i in 1 2; do echo "doc" > "$tmpdir/documents/file$i.pdf"; done
        echo "vid" > "$tmpdir/videos/clip.mp4"
        for i in 1 2 3 4; do echo "code" > "$tmpdir/code/script$i.sh"; done

        echo "  📊 整理统计报告"
        echo "  ─────────────────────────────────"
        printf "  %-15s %6s %10s\n" "分类" "文件数" "大小"
        echo "  ─────────────────────────────────"
        for dir in "$tmpdir"/*/; do
            local dirname
            dirname=$(basename "$dir")
            local count
            count=$(find "$dir" -type f | wc -l)
            local size
            size=$(du -sh "$dir" 2>/dev/null | cut -f1)
            printf "  %-15s %6d %10s\n" "$dirname" "$count" "$size"
        done
        echo "  ─────────────────────────────────"
        local total
        total=$(find "$tmpdir" -type f | wc -l)
        printf "  %-15s %6d %10s\n" "合计" "$total" "$(du -sh "$tmpdir" | cut -f1)"

        rm -rf "$tmpdir"
    else
        # TODO: 遍历分类目录统计
        # for dir in "$target"/*/; do
        #     count=$(find "$dir" -type f | wc -l)
        #     size=$(du -sh "$dir" | cut -f1)
        #     printf "%-15s %6d %10s\n" "$(basename "$dir")" "$count" "$size"
        # done
        echo "待实现..."
    fi
}

# ============================================================================
# 练习 5：递归处理子目录（跳过特殊目录）
# ============================================================================
exercise_5() {
    echo -e "\n${YELLOW}━━━ 练习 5：递归整理 ━━━${NC}"

    if [[ "$MODE" == "answers" ]]; then
        echo -e "${GREEN}[参考答案]${NC}"
        # 创建测试目录
        local tmpdir
        tmpdir=$(mktemp -d)
        mkdir -p "$tmpdir/src" "$tmpdir/.git/objects" "$tmpdir/node_modules/pkg"
        echo "code" > "$tmpdir/src/main.sh"
        echo "git" > "$tmpdir/.git/config"
        echo "nm" > "$tmpdir/node_modules/pkg/index.js"
        echo "doc" > "$tmpdir/readme.txt"

        echo "  递归查找（跳过 .git 和 node_modules）:"
        find "$tmpdir" -type f \
            -not -path "*/.git/*" \
            -not -path "*/node_modules/*" | while read -r f; do
            local rel="${f#$tmpdir/}"
            echo "    $rel"
        done

        echo ""
        echo "  按扩展名统计:"
        find "$tmpdir" -type f \
            -not -path "*/.git/*" \
            -not -path "*/node_modules/*" | \
            awk -F. '{print tolower($NF)}' | sort | uniq -c | sort -rn | \
            while read -r count ext; do
                echo "    .$ext: $count 个"
            done

        rm -rf "$tmpdir"
    else
        # TODO: find "$dir" -type f -not -path "*/.git/*" -not -path "*/node_modules/*"
        echo "待实现..."
    fi
}

# ============================================================================
# 主菜单
# ============================================================================
if [[ "$MODE" == "answers" ]]; then
    echo -e "${CYAN}${BOLD}项目 03 参考答案 — 文件整理器${NC}"
    exercise_1; exercise_2; exercise_3; exercise_4; exercise_5
    echo -e "\n${GREEN}全部完成！${NC}"
    exit 0
fi

echo -e "${CYAN}${BOLD}项目 03 练习题 — 文件整理器${NC}"
echo ""
echo "选择练习 (1-5):"
echo "  提示: bash exercises.sh --answers 查看所有参考答案"
read -rp "编号: " choice
case "$choice" in
    1) exercise_1 ;; 2) exercise_2 ;; 3) exercise_3 ;;
    4) exercise_4 ;; 5) exercise_5 ;;
    *) echo "无效选择"; exit 1 ;;
esac
