# 项目 04：日志分析器 (Log Analyzer)

## 项目简介

在本项目中，我们将构建一个 **Web 服务器日志分析工具**，用于解析 Apache/Nginx 的 Combined Log Format 日志，提取关键统计信息，并生成可视化报告。

通过这个项目，你将深入学习 Bash 中最强大的文本处理三剑客：**grep**、**awk**、**sed**，以及**正则表达式**和**管道重定向**等核心概念。

### 你将学到什么

- 管道与重定向的完整用法
- grep 命令的深度使用
- 正则表达式（BRE / ERE / PCRE）
- awk 编程（字段处理、数组、内置变量）
- sed 流编辑器（替换、删除、插入）
- 数据流处理的经典模式

### 项目文件结构

```
04-log-analyzer/
├── README.md              # 本教程文档
├── generate_logs.sh       # 生成模拟日志数据
├── analyzer.sh            # 基础日志分析器
├── analyzer_advanced.sh   # 高级分析器（时间维度、CSV导出）
└── exercises.sh           # 练习题模板
```

---

## 核心概念详解

### 1. 管道 (Pipes) 与重定向

#### 1.1 管道 `|` — 进程间通信

管道将前一个命令的 **标准输出** 连接到后一个命令的 **标准输入**。

```bash
# 管道的工作原理
#   命令A | 命令B | 命令C
#   stdout → stdin    stdout → stdin

# 示例：统计日志中 404 的数量
grep " 404 " access.log | wc -l
```

**管道的特性：**
- 传输的是**字节流**（文本），不是文件
- **单向**：只能从左到右
- 每个命令在**独立子进程**中运行
- 右侧处理慢时，左侧会被阻塞（背压机制）

#### 1.2 输出重定向

```bash
echo "Hello" > output.txt       # >  覆盖写
echo "World" >> output.txt      # >> 追加写
ls /nonexistent 2> error.log    # 2> 标准错误重定向
command > out.txt 2>&1          # 2>&1 合并 stderr 到 stdout
command &> all_output.txt       # &> 简写（Bash 特有）
command > /dev/null 2>&1        # 丢弃所有输出
```

#### 1.3 输入重定向

```bash
sort < unsorted.txt              # < 从文件读取

cat << EOF                       # << Here Document
第一行
第二行
EOF

read -r first rest <<< "Hello World"  # <<< Here String
```

#### 1.4 文件描述符

| 文件描述符 | 名称 | 说明 |
|-----------|------|------|
| 0 | stdin | 标准输入 |
| 1 | stdout | 标准输出 |
| 2 | stderr | 标准错误 |

```bash
exec > /tmp/script.log 2>&1   # 重定向整个脚本的输出
exec 3> /tmp/custom.log       # 自定义文件描述符
echo "写入FD3" >&3
exec 3>&-                     # 关闭
```

---

### 2. grep 命令深度解析

grep（Global Regular Expression Print）是最常用的文本搜索工具。

#### 2.1 常用选项速查表

| 选项 | 说明 | 示例 |
|------|------|------|
| `-i` | 忽略大小写 | `grep -i "error" log` |
| `-v` | 反向匹配（排除） | `grep -v "DEBUG" log` |
| `-c` | 只输出匹配行数 | `grep -c "404" log` |
| `-l` | 只输出匹配的文件名 | `grep -rl "TODO" src/` |
| `-n` | 显示行号 | `grep -n "error" log` |
| `-r` | 递归搜索目录 | `grep -r "pattern" dir/` |
| `-E` | 使用扩展正则 (ERE) | `grep -E "err\|warn" log` |
| `-P` | 使用 Perl 正则 (PCRE) | `grep -P "\d+" log` |
| `-o` | 只输出匹配部分 | `grep -oP '\d+\.\d+' log` |
| `-A N` | 显示匹配行后 N 行 | `grep -A 3 "error" log` |
| `-B N` | 显示匹配行前 N 行 | `grep -B 2 "error" log` |
| `-C N` | 显示匹配行前后 N 行 | `grep -C 2 "error" log` |
| `-w` | 全词匹配 | `grep -w "the" file` |
| `-m N` | 最多匹配 N 行 | `grep -m 5 "pattern" log` |

#### 2.2 实战示例

```bash
# 查找所有来自特定 IP 的请求
grep "192.168.1.100" access.log

# 查找所有 4xx 和 5xx 错误
grep -E '" [45][0-9]{2} ' access.log

# 提取所有 IP 地址
grep -oP '\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}' access.log | sort | uniq -c | sort -rn

# 查找错误并显示上下文
grep -C 2 '" 500 ' access.log
```

---

### 3. 正则表达式 (Regular Expressions)

#### 3.1 BRE vs ERE vs PCRE 对比

| 特性 | BRE | ERE | PCRE |
|------|-----|-----|------|
| 工具 | `grep`, `sed` | `grep -E`, `awk` | `grep -P`, `perl` |
| `+` 一或多次 | `\+` | `+` | `+` |
| `?` 零或一次 | `\?` | `?` | `?` |
| `{n,m}` 量词 | `\{n,m\}` | `{n,m}` | `{n,m}` |
| `()` 分组 | `\(\)` | `()` | `()` |
| `\|` 或 | `\|` | `\|` | `\|` |
| `\d` 数字 | ❌ | ❌ | ✅ |
| `\w` 单词字符 | ❌ | ❌ | ✅ |
| `\s` 空白 | ❌ | ❌ | ✅ |
| `\b` 单词边界 | ❌ | ❌ | ✅ |
| 非贪婪 `*?` | ❌ | ❌ | ✅ |
| 零宽断言 | ❌ | ❌ | ✅ |

#### 3.2 元字符速查表

| 元字符 | 说明 | 示例 | 匹配 |
|--------|------|------|------|
| `.` | 任意字符 | `a.c` | "abc", "a1c" |
| `*` | 零或多次 | `ab*c` | "ac", "abc", "abbc" |
| `+` | 一或多次 | `ab+c` | "abc", "abbc" |
| `?` | 零或一次 | `ab?c` | "ac", "abc" |
| `^` | 行首 | `^Hello` | 行首的 "Hello" |
| `$` | 行尾 | `world$` | 行尾的 "world" |
| `[abc]` | 字符类 | `[aeiou]` | 元音字母 |
| `[^abc]` | 排除类 | `[^0-9]` | 非数字 |

#### 3.3 POSIX 字符类

| 字符类 | 等价 | 说明 |
|--------|------|------|
| `[[:alpha:]]` | `[a-zA-Z]` | 字母 |
| `[[:digit:]]` | `[0-9]` | 数字 |
| `[[:alnum:]]` | `[a-zA-Z0-9]` | 字母数字 |
| `[[:space:]]` | `[ \t\n\r\f\v]` | 空白 |

#### 3.4 常用正则模式

```bash
# IP 地址
'\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}'

# 日期 (YYYY-MM-DD)
'[0-9]{4}-[0-9]{2}-[0-9]{2}'

# HTTP 状态码
'" [1-5][0-9]{2} '

# URL
'https?://[^ "]+'
```

---

### 4. awk 命令深度解析

awk 是一门完整的文本处理编程语言。

#### 4.1 基本语法

```bash
awk 'pattern { action }' file
awk '{ print }' file           # 打印所有行
awk '{ print $1, $3 }' file    # 打印第1和第3字段
awk -F: '{ print $1 }' /etc/passwd  # 指定分隔符
```

#### 4.2 内置变量速查表

| 变量 | 说明 |
|------|------|
| `NR` | 当前总行号 |
| `NF` | 当前行字段数 |
| `FS` | 输入字段分隔符 |
| `OFS` | 输出字段分隔符 |
| `$0` | 整行内容 |
| `$N` | 第 N 个字段 |
| `$NF` | 最后一个字段 |
| `FILENAME` | 当前文件名 |
| `FNR` | 当前文件内行号 |

#### 4.3 BEGIN 和 END 块

```bash
awk '
BEGIN { total = 0 }
{ total += $10 }
END { print "总字节数:", total }
' access.log
```

#### 4.4 关联数组（计数器模式）

```bash
# 统计每个 IP 的请求次数
awk '{ ip_count[$1]++ }
END {
    for (ip in ip_count)
        print ip_count[ip], ip
}' access.log | sort -rn | head -10
```

#### 4.5 字符串函数

| 函数 | 说明 |
|------|------|
| `split(s, a, sep)` | 分割字符串到数组 |
| `substr(s, start, len)` | 提取子串 |
| `gsub(regex, repl, s)` | 全局替换 |
| `sub(regex, repl, s)` | 替换第一个匹配 |
| `match(s, regex)` | 正则匹配 |
| `sprintf(fmt, ...)` | 格式化字符串 |
| `length(s)` | 字符串长度 |

#### 4.6 printf 格式化

```bash
awk '{
    printf "%-20s %8d %10.2f%%\n", $1, $2, $3
}' data.txt
# %-20s  左对齐20字符
# %8d    右对齐8位整数
# %.2f   两位小数
```

---

### 5. sed 命令深度解析

sed（Stream Editor）是非交互式的流编辑器。

#### 5.1 基本用法

```bash
sed 's/旧/新/' file        # 替换每行第一个匹配
sed 's/旧/新/g' file       # 替换所有匹配
sed -i 's/旧/新/g' file    # 原地编辑
```

#### 5.2 地址（作用范围）

```bash
sed '3d' file              # 删除第 3 行
sed '2,5d' file            # 删除第 2-5 行
sed '/^#/d' file           # 删除注释行
sed '/start/,/end/d' file  # 删除 start 到 end 之间
```

#### 5.3 常用命令

| 命令 | 说明 |
|------|------|
| `s/old/new/` | 替换 |
| `d` | 删除 |
| `p` | 打印（配合 -n） |
| `i\text` | 在匹配行前插入 |
| `a\text` | 在匹配行后追加 |
| `c\text` | 替换整行 |

#### 5.4 分组捕获

```bash
# 交换两个字段
sed -E 's/(.+):(.+)/\2:\1/' file
```

---

### 6. 数据流模型

Unix 文本处理的经典模式：

```
生成 → 过滤 → 转换 → 聚合
```

| 阶段 | 说明 | 典型工具 |
|------|------|---------|
| **生成** | 产生数据流 | `cat`, `echo`, `find` |
| **过滤** | 选择/排除行 | `grep`, `awk '条件'` |
| **转换** | 修改格式 | `sed`, `awk`, `tr` |
| **聚合** | 汇总统计 | `sort`, `uniq -c`, `wc` |

```bash
# 经典日志分析管道
cat access.log |               # 生成
  grep '" 404 ' |              # 过滤
  awk '{print $1}' |           # 转换
  sort | uniq -c | sort -rn |  # 聚合
  head -10

# 更高效的写法
awk '$9 == "404" {print $1}' access.log | sort | uniq -c | sort -rn | head -10
```

---

### 7. grep vs awk vs sed 对比

| 场景 | 推荐工具 | 原因 |
|------|---------|------|
| 搜索特定文本 | **grep** | 最快最简单 |
| 按条件过滤行 | **grep** 或 **awk** | grep 更简洁 |
| 提取特定字段 | **awk** | 原生字段分割 |
| 文本替换 | **sed** | 专为替换设计 |
| 数学运算 | **awk** | 支持变量和运算 |
| 复杂逻辑 | **awk** | 完整编程语言 |

---

## 日志格式说明

### Apache Combined Log Format

```
IP - - [时间戳] "方法 URL 协议" 状态码 大小 "Referer" "UA"
```

**字段分解：**

```
192.168.1.100 - - [25/May/2026:14:30:45 +0800] "GET /index.html HTTP/1.1" 200 4096 "https://google.com/" "Mozilla/5.0 ..."
|             | | |                      |       |                    | |     |              |                  |
$1            $2 $3 $4                   $5      $6                   $7 $8   $9             $10               $11+
```

**awk 字段映射：**
- `$1` = IP 地址
- `$4` = 时间戳
- `$6` = 请求方法（带引号）
- `$7` = URL
- `$9` = 状态码
- `$10` = 响应大小

---

## 运行方式

```bash
cd /home/faust/vibe/bash_learn/04-log-analyzer

# 1. 生成测试日志（1200行）
bash generate_logs.sh . 1200

# 2. 运行基础分析器
bash analyzer.sh access.log

# 3. 运行高级分析器
bash analyzer_advanced.sh access.log

# 4. 高级分析器带选项
bash analyzer_advanced.sh -d 2026-05-25:2026-05-27 access.log
bash analyzer_advanced.sh -o report.csv access.log

# 5. 做练习题
bash exercises.sh access.log
```

---

## 练习题

### 练习 1：grep 统计
使用 `grep` 统计日志中每个 HTTP 状态码各出现了多少次。

### 练习 2：awk 字段提取
使用 `awk` 提取所有 POST 请求的 URL，统计每个 URL 被 POST 的次数。

### 练习 3：sed 数据脱敏
使用 `sed` 将日志中的所有 IP 地址替换为 `[REDACTED]`。

### 练习 4：管道组合
找出所有触发 500 错误的请求，列出 URL 和时间戳，按时间排序。

### 练习 5：综合分析
编写完整脚本，统计独立 IP 数量、HTTP 方法分布、最大响应的前 5 个请求。
