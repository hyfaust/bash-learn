#!/bin/bash
# Generate content.js from README.md files
set -euo pipefail

BASE="/home/faust/vibe/bash_learn"
OUT="/home/faust/vibe/bash_learn/content.js"

declare -A TITLES=(
    [01-hello-bash]="Hello Bash — 基础入门"
    [02-guessing-game]="猜数字游戏 — 条件与循环"
    [03-file-organizer]="文件整理器 — 文件操作"
    [04-log-analyzer]="日志分析器 — 文本处理"
    [05-backup-tool]="备份工具 — 函数与参数"
    [06-system-monitor]="系统监控 — 进程与信号"
)

declare -A DESCS=(
    [01-hello-bash]="变量、字符串、echo/printf、read、算术运算"
    [02-guessing-game]="if/else、比较运算符、while循环、case语句、随机数"
    [03-file-organizer]="find、文件测试、关联数组、mv/cp、路径操作"
    [04-log-analyzer]="grep、awk、sed、管道组合、sort/uniq/wc"
    [05-backup-tool]="函数定义、参数处理、getopts、trap信号、tar打包"
    [06-system-monitor]="/proc文件系统、tput终端控制、后台进程、bc计算器"
)

declare -A ICONS=(
    [01-hello-bash]="🚀"
    [02-guessing-game]="🎯"
    [03-file-organizer]="📁"
    [04-log-analyzer]="📊"
    [05-backup-tool]="💾"
    [06-system-monitor]="🖥"
)

declare -A DIFFS=(
    [01-hello-bash]="⭐"
    [02-guessing-game]="⭐⭐"
    [03-file-organizer]="⭐⭐⭐"
    [04-log-analyzer]="⭐⭐⭐⭐"
    [05-backup-tool]="⭐⭐⭐⭐⭐"
    [06-system-monitor]="⭐⭐⭐⭐⭐⭐"
)

projects="01-hello-bash 02-guessing-game 03-file-organizer 04-log-analyzer 05-backup-tool 06-system-monitor"

echo "const PROJECTS = [" > "$OUT"
first=true
for proj in $projects; do
    dir="${BASE}/${proj}"
    readme="${dir}/README.md"
    
    if [[ "$first" == true ]]; then
        first=false
    else
        echo "," >> "$OUT"
    fi
    
    # Read and escape markdown content for JS string
    content=$(python3 -c "
import json, sys
with open('$readme', 'r') as f:
    print(json.dumps(f.read()))
")
    
    # Get list of source files
    src_files=""
    for f in "$dir"/*.sh "$dir"/*.conf; do
        [[ -f "$f" ]] || continue
        fname=$(basename "$f")
        if [[ -z "$src_files" ]]; then
            src_files="$fname"
        else
            src_files="$src_files,$fname"
        fi
    done
    
    cat >> "$OUT" <<EOF
  {
    id: "$proj",
    title: "${TITLES[$proj]}",
    description: "${DESCS[$proj]}",
    icon: "${ICONS[$proj]}",
    difficulty: "${DIFFS[$proj]}",
    files: "$src_files",
    content: $content
  }
EOF
done

echo "];" >> "$OUT"

echo "Generated $OUT ($(wc -c < "$OUT") bytes)"
