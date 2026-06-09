# 项目 05：备份工具（Backup Tool）

## 项目简介

在本项目中，我们将构建一个功能完整的 **命令行备份工具**，支持增量备份、压缩、轮转和日志记录。你将学习 Bash 高级编程：数组、getopts、trap、错误处理。

### 你将学到什么

- 索引数组和关联数组
- `getopts` 命令行参数解析
- 错误处理（set -euo pipefail、trap）
- `tar` 归档与增量备份
- 日期时间处理
- 进程管理与信号处理
- 函数库组织模式

### 项目文件结构

```
05-backup-tool/
├── README.md              # 本教程文档
├── backup.sh              # 主备份脚本
├── backup_advanced.sh     # 高级版（配置文件、校验、并行）
├── backup.conf            # 配置文件示例
├── lib.sh                 # 共享函数库
└── exercises.sh           # 练习题模板
```

---

## 核心概念详解

### 1. 数组（Arrays）

#### 1.1 索引数组

```bash
# 声明
fruits=("苹果" "香蕉" "橙子" "葡萄")

# 逐个赋值
colors=()
colors[0]="红色"; colors[1]="绿色"; colors[2]="蓝色"

# 访问
echo "${fruits[0]}"       # 苹果
echo "${fruits[@]}"       # 所有元素
echo "${#fruits[@]}"      # 长度: 4
echo "${fruits[@]:1:2}"   # 切片: 香蕉 橙子

# 追加和删除
fruits+=("葡萄")
unset fruits[1]           # 删除（不重排索引）

# 遍历
for item in "${fruits[@]}"; do echo "$item"; done
for i in "${!fruits[@]}"; do echo "$i: ${fruits[$i]}"; done

# 合并
a=("x" "y"); b=("z" "w")
combined=("${a[@]}" "${b[@]}")
```

#### 1.2 关联数组

```bash
# 必须先声明
declare -A config
config[backup_dir]="/backup"
config[compress]="gzip"
config[keep_count]=7

# 声明时初始化
declare -A user=([name]="张三" [age]=28 [city]="北京")

# 访问
echo "${user[name]}"      # 张三
echo "${!user[@]}"        # 所有键: name age city
echo "${user[@]}"         # 所有值: 张三 28 北京

# 遍历
for key in "${!config[@]}"; do
    echo "$key = ${config[$key]}"
done
```

#### 1.3 数组与字符串转换

```bash
# 字符串 → 数组
str="apple banana cherry"
read -ra fruits <<< "$str"

# 自定义分隔符
IFS=':' read -ra paths <<< "/usr/bin:/usr/local/bin"

# 数组 → 字符串
arr=("hello" "world")
joined=$(IFS=','; echo "${arr[*]}")  # "hello,world"
```

---

### 2. 命令行参数解析

#### 2.1 位置参数

```bash
# $0 脚本名, $1~$9 前9个参数, ${10}+ 第10个起
# $# 参数个数, "$@" 每个独立, "$*" 合并为一个

# shift 移除已处理的参数
while [[ $# -gt 0 ]]; do
    echo "参数: $1"
    shift
done
```

#### 2.2 getopts（短选项）

```bash
while getopts "f:n:vh" opt; do
    case "$opt" in
        f) file="$OPTARG" ;;    # OPTARG: 选项的参数值
        n) count="$OPTARG" ;;
        v) verbose=true ;;
        h) usage; exit 0 ;;
        \?) echo "无效选项" >&2; exit 1 ;;
        :)  echo "选项需要参数" >&2; exit 1 ;;
    esac
done
shift $((OPTIND - 1))  # 移除已解析的选项
```

**冒号含义：**

| optstring | 说明 |
|-----------|------|
| `f:n:v` | -f 需要参数, -n 需要参数, -v 不需要 |
| `:f:n:v` | 第一个 `:` 开启静默模式 |

#### 2.3 长选项处理

```bash
# 方式一：GNU getopt
PARSED=$(getopt -o s:d:vh --long source:,dest:,verbose,help -n "$0" -- "$@")
eval set -- "$PARSED"
while true; do
    case "$1" in
        -s|--source) src="$2"; shift 2 ;;
        -v|--verbose) verbose=true; shift ;;
        --) shift; break ;;
    esac
done

# 方式二：手动 while+case
while [[ $# -gt 0 ]]; do
    case "$1" in
        -s|--source) src="$2"; shift 2 ;;
        -v|--verbose) verbose=true; shift ;;
        -h|--help) usage; exit 0 ;;
        --) shift; break ;;
        -*) echo "未知选项: $1" >&2; exit 1 ;;
        *)  break ;;
    esac
done
```

---

### 3. 错误处理与调试

#### 3.1 Shell 选项

```bash
set -e              # 遇错即停
set -u              # 未定义变量报错
set -o pipefail     # 管道错误传播
set -x              # 调试跟踪（打印每条命令）

# 推荐组合
set -euo pipefail
```

| 选项 | 作用 | 推荐场景 |
|------|------|---------|
| `set -e` | 遇错即停 | 所有脚本 |
| `set -u` | 未定义变量报错 | 所有脚本 |
| `set -o pipefail` | 管道错误传播 | 所有脚本 |
| `set -x` | 调试跟踪 | 仅调试时 |

#### 3.2 trap 命令

```bash
# 捕获信号
trap 'echo "退出"' EXIT
trap 'echo "Ctrl+C"; exit 130' INT
trap 'echo "终止"' TERM

# 清理临时文件（最佳实践）
TMPDIR=$(mktemp -d)
cleanup() {
    local exit_code=$?
    rm -rf "$TMPDIR"
    exit "$exit_code"
}
trap cleanup EXIT INT TERM
```

**常见信号：**

| 信号 | 编号 | 说明 |
|------|------|------|
| SIGHUP | 1 | 终端断开 |
| SIGINT | 2 | Ctrl+C |
| SIGTERM | 15 | 请求终止 |
| SIGUSR1 | 10 | 用户自定义 |
| SIGKILL | 9 | 强制终止（不可捕获） |

#### 3.3 日志函数

```bash
log_info()  { echo "[$(date '+%H:%M:%S')] [INFO]  $*"; }
log_warn()  { echo "[$(date '+%H:%M:%S')] [WARN]  $*" >&2; }
log_error() { echo "[$(date '+%H:%M:%S')] [ERROR] $*" >&2; }
die()       { log_error "$1"; exit "${2:-1}"; }
```

---

### 4. 日期与时间

```bash
date '+%Y-%m-%d'              # 2026-06-05
date '+%Y%m%d_%H%M%S'         # 20260605_143025（适合文件名）
date '+%s'                     # Unix 时间戳

# 时间戳运算
now=$(date '+%s')
seven_days_ago=$((now - 7 * 86400))
date -d @"$seven_days_ago" '+%Y-%m-%d'

# 耗时计算
start=$(date '+%s')
# ... 操作 ...
elapsed=$(( $(date '+%s') - start ))
echo "耗时: ${elapsed} 秒"
```

---

### 5. tar 与压缩

| 选项 | 含义 |
|------|------|
| `-c` | 创建归档 |
| `-x` | 解压 |
| `-t` | 列出内容 |
| `-v` | 详细输出 |
| `-f` | 指定文件名 |
| `-z` | gzip 压缩 |
| `-j` | bzip2 压缩 |
| `-J` | xz 压缩 |

```bash
# 创建压缩归档
tar -czf backup.tar.gz /data/

# 增量备份
tar --listed-incremental=snapshot.snar -czf full.tar.gz /data/
tar --listed-incremental=snapshot.snar -czf incr.tar.gz /data/

# 恢复
tar -xzf full.tar.gz -C /restore/
tar --listed-incremental=/ -xzf incr.tar.gz -C /restore/
```

**压缩工具比较：**

| 工具 | 扩展名 | 压缩率 | 速度 |
|------|--------|--------|------|
| gzip | .tar.gz | 一般 | 快 |
| bzip2 | .tar.bz2 | 较好 | 较慢 |
| xz | .tar.xz | 最好 | 最慢 |

---

### 6. 进程与子shell

```bash
# 命令替换
current_date=$(date '+%Y-%m-%d')

# 子shell（不改变父 shell 变量）
count=5
( count=10; echo "子shell: $count" )  # 10
echo "父shell: $count"                # 5

# 文件锁（防止并发）
LOCK="/var/lock/backup.lock"
exec 200>"$LOCK"
flock -n 200 || { echo "另一个实例在运行"; exit 1; }
```

---

## 备份策略图

```
全量备份: 每次备份所有数据
╔═══════════════════════════════════╗
║  A B C D E F G H I J K L M N O  ║  Day1
╚═══════════════════════════════════╝
╔═══════════════════════════════════╗
║  A B C D E F G H I J K L M N O  ║  Day2（重复）
╚═══════════════════════════════════╝

增量备份: 只备份自上次以来变化的数据
╔═══════════════════════════════════╗
║  A B C D E F G H I J K L M N O  ║  Day1: 全量
╚═══════════════════════════════════╝
    ┌─────────┐
    │ C' F' K'│                      Day2: 增量
    └─────────┘
         ┌────────┐
         │ A' M'  │                   Day3: 增量
         └────────┘
恢复 = 全量 + Day2增量 + Day3增量

差异备份: 始终基于最近全量
╔═══════════════════════════════════╗
║  A B C D E F G H I J K L M N O  ║  Day1: 全量
╚═══════════════════════════════════╝
    ┌─────────┐
    │ C' F' K'│                      Day2: 差异(自Day1)
    └─────────┘
    ┌──────────────┐
    │ C' F' K' A' M'│               Day3: 差异(自Day1)
    └──────────────┘
恢复 = 全量 + 最新差异
```

---

## 运行方式

```bash
cd /home/faust/vibe/bash_learn/05-backup-tool
chmod +x backup.sh backup_advanced.sh

# 基础备份
./backup.sh -s /home/user/docs -d /tmp/backup
./backup.sh -s /data -d /tmp/backup -c xz -n 5 -v

# 高级备份（使用配置文件）
./backup_advanced.sh -f backup.conf
./backup_advanced.sh -f backup.conf -V  # 带验证
```

---

## 练习题

1. 支持从 `~/.backup.conf` 读取默认配置
2. 实现差异备份模式
3. 添加邮件/桌面通知
4. SHA256 校验和验证
5. 并行多目录备份（flock 保护日志）
