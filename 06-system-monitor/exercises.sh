#!/bin/bash
# ============================================================================
# exercises.sh — 项目 06 练习题
# 用法: bash exercises.sh          # 运行练习
#       bash exercises.sh --answers # 查看并运行参考答案
# ============================================================================

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
CYAN='\033[0;36m'; BOLD='\033[1m'; NC='\033[0m'

MODE="practice"
[[ "${1:-}" == "--answers" ]] && MODE="answers"

# ============================================================================
# 练习 1：进程树视图
# 按父子关系显示进程树（类似 pstree）
# ============================================================================
exercise_1() {
    echo -e "\n${YELLOW}━━━ 练习 1：进程树视图 ━━━${NC}"

    if [[ "$MODE" == "answers" ]]; then
        echo -e "${GREEN}[参考答案]${NC}"
        # 从 /proc 读取进程父子关系
        declare -A ppid_map  # pid -> ppid
        declare -A pid_cmd   # pid -> command

        while read -r pid ppid comm; do
            [[ "$pid" == "PID" ]] && continue
            ppid_map["$pid"]="$ppid"
            pid_cmd["$pid"]="$comm"
        done < <(ps -e -o pid=,ppid=,comm= 2>/dev/null)

        # 递归打印进程树
        print_tree() {
            local pid="$1" prefix="$1" is_last="$2"
            local connector="├── "
            [[ "$is_last" == "last" ]] && connector="└── "
            local cmd="${pid_cmd[$pid]:-?}"
            echo "${prefix}${connector}${cmd} [${pid}]"
        }

        echo "  进程树 (前 20 个):"
        # 找到所有子进程，按 ppid 分组
        declare -A children
        for pid in "${!ppid_map[@]}"; do
            local ppid="${ppid_map[$pid]}"
            children["$ppid"]+="$pid "
        done

        # 从 PID 1 开始，打印前 20 个
        local count=0
        print_children() {
            local ppid="$1" indent="$2"
            local kids="${children[$ppid]}"
            [[ -z "$kids" ]] && return
            local kid_array=($kids)
            for i in "${!kid_array[@]}"; do
                if ((count >= 20)); then
                    echo "${indent}..."
                    return
                fi
                local kid="${kid_array[$i]}"
                local is_last="no"
                ((i == ${#kid_array[@]} - 1)) && is_last="last"
                local connector="├─ "
                [[ "$is_last" == "last" ]] && connector="└─ "
                local cmd="${pid_cmd[$kid]:-?}"
                echo "${indent}${connector}${cmd} [${kid}]"
                count=$((count + 1))
                local new_indent="${indent}│  "
                [[ "$is_last" == "last" ]] && new_indent="${indent}   "
                print_children "$kid" "$new_indent"
            done
        }

        print_children "1" "  "
    else
        # TODO: 从 /proc 读取 ppid，递归打印树
        # while read -r pid ppid comm; do
        #     ppid_map["$pid"]="$ppid"
        #     pid_cmd["$pid"]="$comm"
        # done < <(ps -e -o pid=,ppid=,comm=)
        echo "待实现..."
    fi
}

# ============================================================================
# 练习 2：CPU 历史折线图
# 每 2 秒采样一次 CPU，显示 ASCII 折线图
# ============================================================================
exercise_2() {
    echo -e "\n${YELLOW}━━━ 练习 2：CPU 历史折线图 ━━━${NC}"

    if [[ "$MODE" == "answers" ]]; then
        echo -e "${GREEN}[参考答案]${NC}"
        local samples=()
        local max_samples=20
        local height=8

        # 采集 CPU 使用率
        get_cpu() {
            read -r _ u1 n1 s1 i1 w1 q1 sq1 st1 _ _ < /proc/stat
            local t1=$((u1+n1+s1+i1+w1+q1+sq1+st1))
            local b1=$((t1-i1-w1))
            sleep 0.3
            read -r _ u2 n2 s2 i2 w2 q2 sq2 st2 _ _ < /proc/stat
            local t2=$((u2+n2+s2+i2+w2+q2+sq2+st2))
            local b2=$((t2-i2-w2))
            local dt=$((t2-t1)) db=$((b2-b1))
            if ((dt > 0)); then
                echo "scale=0; $db*100/$dt" | bc
            else
                echo "0"
            fi
        }

        # 采集几个样本
        echo "  采集中 (3 个样本)..."
        for ((s = 0; s < 3; s++)); do
            local cpu
            cpu=$(get_cpu)
            samples+=("$cpu")
            echo "    样本 $((s+1)): ${cpu}%"
        done

        # 绘制 ASCII 折线图
        echo ""
        echo "  CPU 历史:"
        for ((row = height; row >= 1; row--)); do
            local threshold=$((row * 100 / height))
            printf "  %3d%% │" "$threshold"
            for val in "${samples[@]}"; do
                if ((val >= threshold)); then
                    printf "█"
                else
                    printf " "
                fi
            done
            echo ""
        done
        printf "      └"
        for ((i = 0; i < ${#samples[@]}; i++)); do printf "─"; done
        echo ""
    else
        # TODO: 采样 + 绘制折线图
        # read -r _ u1 n1 s1 i1 w1 q1 sq1 st1 _ _ < /proc/stat
        # sleep 1
        # read -r _ u2 n2 s2 i2 w2 q2 sq2 st2 _ _ < /proc/stat
        # cpu=$(( (b2-b1)*100 / (t2-t1) ))
        echo "待实现..."
    fi
}

# ============================================================================
# 练习 3：网络连接监控
# 监控 TCP 连接数变化，异常时告警
# ============================================================================
exercise_3() {
    echo -e "\n${YELLOW}━━━ 练习 3：网络连接监控 ━━━${NC}"

    if [[ "$MODE" == "answers" ]]; then
        echo -e "${GREEN}[参考答案]${NC}"
        echo "  当前 TCP 连接统计:"
        if command -v ss &>/dev/null; then
            local total established time_wait
            total=$(ss -t state established 2>/dev/null | tail -n +2 | wc -l)
            time_wait=$(ss -t state time-wait 2>/dev/null | tail -n +2 | wc -l)
            local listening
            listening=$(ss -tulnp 2>/dev/null | tail -n +2 | wc -l)

            echo "    已建立连接: $total"
            echo "    TIME_WAIT:  $time_wait"
            echo "    监听端口:   $listening"

            # 告警阈值检查
            local threshold=100
            if ((total > threshold)); then
                echo -e "    ${RED}⚠ 告警: 连接数 $total > 阈值 $threshold${NC}"
            else
                echo -e "    ${GREEN}✓ 连接数正常 (< $threshold)${NC}"
            fi

            echo ""
            echo "  按状态统计:"
            ss -tan 2>/dev/null | tail -n +2 | awk '{print $1}' | sort | uniq -c | sort -rn | \
                while read -r count state; do
                    printf "    %-15s %d\n" "$state" "$count"
                done
        else
            echo "  ss 命令不可用"
        fi
    else
        # TODO: ss -tan | awk 统计各状态连接数
        # total=$(ss -t state established | wc -l)
        # if ((total > threshold)); then echo "告警!"; fi
        echo "待实现..."
    fi
}

# ============================================================================
# 练习 4：邮件告警
# 磁盘>90% 或 CPU>80% 持续 5 分钟时发送邮件
# ============================================================================
exercise_4() {
    echo -e "\n${YELLOW}━━━ 练习 4：告警系统 ━━━${NC}"

    if [[ "$MODE" == "answers" ]]; then
        echo -e "${GREEN}[参考答案]${NC}"
        # 告警状态文件
        local alert_state="/tmp/alert_state"
        local alert_count=0
        local threshold_cpu=80
        local threshold_disk=90

        # 获取 CPU
        read -r _ u1 n1 s1 i1 w1 q1 sq1 st1 _ _ < /proc/stat
        local t1=$((u1+n1+s1+i1+w1+q1+sq1+st1))
        sleep 0.2
        read -r _ u2 n2 s2 i2 w2 q2 sq2 st2 _ _ < /proc/stat
        local t2=$((u2+n2+s2+i2+w2+q2+sq2+st2))
        local dt=$((t2-t1))
        local db=$(( (t2-i2-w2) - (t1-i1-w1) ))
        local cpu_pct=0
        if ((dt > 0)); then cpu_pct=$((db * 100 / dt)); fi

        # 检查磁盘
        local max_disk
        max_disk=$(df -hP 2>/dev/null | awk 'NR>1 {gsub(/%/,"",$5); if($5+0>m) m=$5+0} END{print m}')

        echo "  当前状态:"
        echo "    CPU: ${cpu_pct}% (阈值: ${threshold_cpu}%)"
        echo "    磁盘最大使用: ${max_disk}% (阈值: ${threshold_disk}%)"

        echo ""
        echo "  告警逻辑:"
        if ((cpu_pct > threshold_cpu)); then
            echo -e "    ${RED}⚠ CPU 告警: ${cpu_pct}% > ${threshold_cpu}%${NC}"
            echo "    → 记录到状态文件，累计 5 分钟后发送邮件"
        else
            echo -e "    ${GREEN}✓ CPU 正常${NC}"
        fi

        if ((max_disk > threshold_disk)); then
            echo -e "    ${RED}⚠ 磁盘告警: ${max_disk}% > ${threshold_disk}%${NC}"
        else
            echo -e "    ${GREEN}✓ 磁盘正常${NC}"
        fi

        echo ""
        echo "  实现要点:"
        echo "    1. cron 每分钟运行一次检查脚本"
        echo "    2. 用状态文件记录持续超阈值的时间"
        echo "    3. 超过 5 分钟 (5次连续) 发送邮件"
        echo "    4. mail -s '告警' admin@example.com < message"
    else
        # TODO: 检查阈值，记录状态文件，累计超时发送邮件
        echo "待实现..."
    fi
}

# ============================================================================
# 练习 5：Web 报告页
# 生成 HTML 系统报告（包含表格和样式）
# ============================================================================
exercise_5() {
    echo -e "\n${YELLOW}━━━ 练习 5：HTML 系统报告 ━━━${NC}"

    if [[ "$MODE" == "answers" ]]; then
        echo -e "${GREEN}[参考答案]${NC}"
        local outfile="/tmp/system_report.html"
        local now
        now=$(date '+%Y-%m-%d %H:%M:%S')
        local hostname
        hostname=$(hostname 2>/dev/null || echo "unknown")
        local kernel
        kernel=$(uname -r)
        local mem_total mem_avail
        mem_total=$(awk '/MemTotal/{print $2}' /proc/meminfo)
        mem_avail=$(awk '/MemAvailable/{print $2}' /proc/meminfo)
        local mem_pct=$(( (mem_total - mem_avail) * 100 / mem_total ))

        cat > "$outfile" <<HTMLEOF
<!DOCTYPE html>
<html lang="zh-CN">
<head>
<meta charset="UTF-8">
<title>系统报告 - $hostname</title>
<style>
  body { font-family: sans-serif; max-width: 800px; margin: 40px auto; padding: 0 20px; background: #f5f5f5; }
  h1 { color: #333; border-bottom: 2px solid #4a9eff; padding-bottom: 8px; }
  table { width: 100%; border-collapse: collapse; margin: 16px 0; background: #fff; }
  th, td { padding: 10px 14px; border: 1px solid #ddd; text-align: left; }
  th { background: #4a9eff; color: #fff; }
  tr:nth-child(even) { background: #f9f9f9; }
  .bar { height: 20px; background: #4a9eff; border-radius: 4px; }
  .warn { color: #e74c3c; font-weight: bold; }
  .ok { color: #27ae60; }
  .meta { color: #888; font-size: 14px; }
</style>
</head>
<body>
<h1>🖥 系统报告</h1>
<p class="meta">生成时间: $now | 主机: $hostname | 内核: $kernel</p>

<h2>内存使用</h2>
<table>
<tr><th>项目</th><th>值</th></tr>
<tr><td>总内存</td><td>$((mem_total/1024)) MB</td></tr>
<tr><td>可用内存</td><td>$((mem_avail/1024)) MB</td></tr>
<tr><td>使用率</td><td>${mem_pct}% <div class="bar" style="width:${mem_pct}%"></div></td></tr>
</table>

<h2>磁盘使用</h2>
<table>
<tr><th>挂载点</th><th>总量</th><th>已用</th><th>可用</th><th>使用率</th></tr>
HTMLEOF

        df -hP 2>/dev/null | awk 'NR>1 && $1 !~ /^(tmpfs|devtmpfs)$/ {
            gsub(/%/,"",$5)
            printf "<tr><td>%s</td><td>%s</td><td>%s</td><td>%s</td><td>%s%%</td></tr>\n", $6, $2, $3, $4, $5
        }' >> "$outfile"

        cat >> "$outfile" <<HTMLEOF
</table>

<h2>TOP 10 进程 (CPU)</h2>
<table>
<tr><th>USER</th><th>PID</th><th>%CPU</th><th>%MEM</th><th>COMMAND</th></tr>
HTMLEOF

        ps aux --sort=-%cpu 2>/dev/null | head -11 | tail -10 | awk '{printf "<tr><td>%s</td><td>%s</td><td>%s</td><td>%s</td><td>%s</td></tr>\n", $1, $2, $3, $4, $11}' >> "$outfile"

        echo "</table></body></html>" >> "$outfile"

        echo "  生成报告: $outfile"
        echo "  文件大小: $(du -h "$outfile" | cut -f1)"
        echo ""
        echo "  内容预览 (前 15 行):"
        head -15 "$outfile" | sed 's/^/    /'
        echo "    ..."
    else
        # TODO: 用 cat heredoc 生成 HTML，嵌入系统信息
        echo "待实现..."
    fi
}

# ============================================================================
# 主菜单
# ============================================================================
if [[ "$MODE" == "answers" ]]; then
    echo -e "${CYAN}${BOLD}项目 06 参考答案 — 系统监控${NC}"
    exercise_1; exercise_2; exercise_3; exercise_4; exercise_5
    echo -e "\n${GREEN}全部完成！${NC}"
    exit 0
fi

echo -e "${CYAN}${BOLD}项目 06 练习题 — 系统监控${NC}"
echo ""
echo "选择练习 (1-5):"
echo "  提示: bash exercises.sh --answers 查看所有参考答案"
read -rp "编号: " choice
case "$choice" in
    1) exercise_1 ;; 2) exercise_2 ;; 3) exercise_3 ;;
    4) exercise_4 ;; 5) exercise_5 ;;
    *) echo "无效选择"; exit 1 ;;
esac
