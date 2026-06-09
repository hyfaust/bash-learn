# 项目 06：系统监控仪表盘（System Monitor）

## 项目简介

在本项目中，我们将构建一个 **实时系统监控仪表盘**，展示 CPU、内存、磁盘、网络和进程信息。你将学习 Bash 最高级的概念：/proc 文件系统、终端控制、后台进程和信号。

### 你将学到什么

- `/proc` 文件系统读取系统信息
- `tput` 终端控制与 ANSI 转义码
- 后台进程管理（`&`、`wait`、`jobs`、`kill`）
- 信号发送与处理（`trap`、`kill`）
- 算术精度计算（`bc`）
- 实时终端 UI 设计

### 项目文件结构

```
06-system-monitor/
├── README.md              # 本教程文档
├── monitor.sh             # 主监控脚本
├── monitor_advanced.sh    # 高级版（告警、交互菜单、守护进程）
├── mini_tools.sh          # 独立小工具集
└── exercises.sh           # 练习题模板
```

---

## 核心概念详解

### 1. /proc 文件系统

`/proc` 是 Linux 内核的虚拟文件系统，提供系统运行时信息。

#### 1.1 CPU 信息

```bash
# /proc/stat 第一行: CPU 总体统计
# cpu  user nice system idle iowait irq softirq steal
# cpu  2255 34  2290   2262  1565   0   35    0

read -r _ user nice system idle iowait irq softirq steal < /proc/stat
total=$((user + nice + system + idle + iowait + irq + softirq + steal))
busy=$((total - idle - iowait))
```

**CPU 使用率计算（两次采样取差）：**

```
CPU% = (busy2 - busy1) / (total2 - total1) × 100
```

#### 1.2 内存信息

```bash
# /proc/meminfo 关键字段
MemTotal:     16384000 kB    # 总物理内存
MemFree:       2048000 kB    # 完全空闲
MemAvailable:  8192000 kB    # 可用（含缓存可回收）
Buffers:        512000 kB    # 块设备缓冲
Cached:        4096000 kB    # 页缓存
SwapTotal:     2097152 kB    # 交换空间总量
SwapFree:      2097152 kB    # 交换空间空闲
```

```bash
get_mem_info() {
    while IFS=': ' read -r key value _; do
        case "$key" in
            MemTotal)     mem_total="$value" ;;
            MemAvailable) mem_available="$value" ;;
            SwapTotal)    swap_total="$value" ;;
            SwapFree)     swap_free="$value" ;;
        esac
    done < /proc/meminfo
    mem_used=$((mem_total - mem_available))
}
```

#### 1.3 磁盘与网络

```bash
# 磁盘：使用 df（底层读 /proc/mounts）
df -h | awk '$5+0 > 80 {print $6, $5}'

# 网络接口流量：/proc/net/dev
# Inter-|   Receive         |  Transmit
#  face |bytes packets errs  | bytes packets errs
#   eth0: 12345  100    0    | 67890  80     0
while read -r iface rx_bytes _ _ _ _ _ _ _ tx_bytes _; do
    iface=${iface%:}
    [[ "$iface" == "lo" || "$iface" == "Inter-" || "$iface" == "face" ]] && continue
    echo "$iface: RX=$(human_size "$rx_bytes") TX=$(human_size "$tx_bytes")"
done < /proc/net/dev
```

#### 1.4 进程信息

```bash
# 进程列表
ls /proc/ | grep -E '^[0-9]+$'

# 进程详情
pid=1234
cat /proc/$pid/status    # Name, State, VmRSS 等
cat /proc/$pid/cmdline   # 命令行（\0 分隔）

# top 命令（非交互模式）
top -bn1 | head -20
```

---

### 2. 终端控制

#### 2.1 tput 命令

```bash
# 光标控制
tput clear               # 清屏
tput cup 5 20            # 移动到第5行第20列
tput civis               # 隐藏光标
tput cnorm               # 恢复光标

# 文本属性
tput bold                # 粗体
tput dim                 # 暗色
tput smul / rmul         # 下划线 开/关
tput rev                 # 反色
tput sgr0                # 重置所有属性

# 颜色
tput setaf 1             # 前景色: 0黑 1红 2绿 3黄 4蓝 5紫 6青 7白
tput setab 4             # 背景色

# 获取终端尺寸
lines=$(tput lines)
cols=$(tput cols)
```

#### 2.2 ANSI 转义码

```bash
# 格式: \033[<参数>m
# 完整转义: \033[38;5;208m  (256色前景)
#           \033[48;5;240m  (256色背景)
#           \033[38;2;r;g;bm (24位真彩色)

RED='\033[0;31m'
GREEN='\033[0;32m'
BOLD='\033[1m'
RESET='\033[0m'
printf "${RED}错误${RESET}\n"
printf "${BOLD}粗体文本${RESET}\n"
```

**ANSI 颜色速查表：**

| 颜色 | 前景 | 背景 | 亮色前景 |
|------|------|------|---------|
| 黑 | 30 | 40 | 90 |
| 红 | 31 | 41 | 91 |
| 绿 | 32 | 42 | 92 |
| 黄 | 33 | 43 | 93 |
| 蓝 | 34 | 44 | 94 |
| 紫 | 35 | 45 | 95 |
| 青 | 36 | 46 | 96 |
| 白 | 37 | 47 | 97 |

#### 2.3 实时刷新技术

```bash
# 方式一：clear + 循环
while true; do
    clear
    echo "CPU: $(get_cpu)%"
    sleep 2
done

# 方式二：tput + home（无闪烁）
tput civis  # 隐藏光标
trap 'tput cnorm; exit' INT TERM
while true; do
    tput home
    echo "CPU: $(get_cpu)%    "
    sleep 2
done

# 方式三：watch 命令
watch -n 2 -t 'echo "CPU: $(grep cpu /proc/stat)"'
```

---

### 3. 后台进程

```bash
# 后台运行
long_task &
bg_pid=$!
echo "后台 PID: $bg_pid"

# 等待完成
wait $bg_pid
exit_code=$?
echo "退出码: $exit_code"

# 并行任务 + 等待全部
task_a &; pid_a=$!
task_b &; pid_b=$!
task_c &; pid_c=$!
wait $pid_a $pid_b $pid_c

# 超时控制
if ! timeout 10 some_command; then
    echo "超时或失败"
fi
```

---

### 4. 信号深入

```bash
# 发送信号
kill -SIGTERM $pid        # 请求终止
kill -SIGUSR1 $pid        # 自定义信号 1
kill -SIGHUP $pid         # 重新加载配置
kill -0 $pid              # 检查进程是否存在（不发送信号）

# 自定义信号处理
reload_config=false
trap 'reload_config=true' USR1

# 守护进程模式
nohup ./monitor.sh &>/dev/null &
disown
```

---

### 5. bc 计算器

```bash
# 整数除法的精度问题
echo "1/3" | bc                    # 0（整数）
echo "scale=2; 1/3" | bc           # .33
echo "scale=2; 100 * 23 / 48" | bc # 47.91

# 在脚本中使用
cpu_pct=$(echo "scale=1; $busy * 100 / $total" | bc)

# 比较浮点数
if (( $(echo "$cpu_pct > 80" | bc -l) )); then
    echo "CPU 过高!"
fi
```

---

### 6. printf 高级格式化

```bash
# 对齐和填充
printf "%-20s %8s %8s\n" "文件" "大小" "权限"   # 左对齐
printf "%-20s %8d %8s\n" "$name" "$size" "$perm"  # 右对齐数字

# 动态宽度
width=30
printf "%${width}s\n" "右对齐"

# 表格输出
print_table() {
    printf "%-6s %-8s %-4s %-10s\n" "PID" "USER" "%CPU" "COMMAND"
    printf "%-6s %-8s %-4s %-10s\n" "------" "--------" "----" "----------"
    # ... 数据行
}

# 进度条
printf "\r进度: [%-50s] %d%%" "$bar" "$pct"
```

---

## 终端 UI 设计图

```
┌─────────────────────────────────────────────────────┐
│                   系统监控仪表盘                      │
│                   2026-06-05 14:30:25               │
├──────────────────────┬──────────────────────────────┤
│                      │                              │
│  CPU 使用率: 23.5%   │  内存: 8.2G/16G (51.3%)      │
│  ████████░░░░░░░░░░░ │  ██████████░░░░░░░░░░░░░░░   │
│                      │                              │
│  核心温度: 45°C       │  Swap: 0.5G/2G (25.0%)      │
│  进程数: 285          │  缓存: 4.1G                  │
│                      │                              │
├──────────────────────┴──────────────────────────────┤
│  磁盘使用:                                            │
│  /          45.2G/100G  ██████████░░░░░░░░  45%     │
│  /home      120.5G/500G ████░░░░░░░░░░░░░░  24%     │
│  /tmp       2.1G/10G    ██████████████████░  90% ⚠  │
├─────────────────────────────────────────────────────┤
│  网络: eth0 RX: 1.2G  TX: 456M                      │
│  负载: 0.85 0.72 0.68                               │
├─────────────────────────────────────────────────────┤
│  TOP 进程:                                            │
│  PID    USER     %CPU  %MEM  COMMAND                 │
│  1234   root     15.2  3.4   chrome                  │
│  5678   user     8.1   2.1   code                    │
│  9012   user     5.3   1.8   node                    │
└─────────────────────────────────────────────────────┘
按 q 退出 | 按 r 刷新
```

---

## 运行方式

```bash
cd /home/faust/vibe/bash_learn/06-system-monitor
chmod +x monitor.sh monitor_advanced.sh mini_tools.sh

# 基础监控（单次快照）
./monitor.sh

# 实时刷新模式
./monitor.sh --live

# 高级版（告警、交互菜单）
./monitor_advanced.sh

# 独立小工具
./mini_tools.sh cpu
./mini_tools.sh mem
./mini_tools.sh disk
./mini_tools.sh net
```

---

## 练习题

1. 添加进程树视图（pstree 风格）
2. 实现 CPU/内存/磁盘历史图表（ASCII 折线图）
3. 添加网络连接监控（ss -tulnp）
4. 邮件告警（磁盘>90%、CPU>80%持续5分钟）
5. 守护进程模式 + Web 报告页生成
