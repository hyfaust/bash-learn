# 项目 02：猜数字游戏 — 控制流

## 项目简介

在本项目中，我们将构建一个带难度选择、计分系统和回放功能的 **数字猜谜游戏**。通过这个有趣的游戏项目，你将全面掌握 Bash 的控制流结构。

### 你将学到什么

- `if/elif/else` 条件判断的各种用法
- `test` 命令和 `[]` vs `[[]]` 的区别
- `for`、`while`、`until` 循环
- `case` 模式匹配语句
- `$RANDOM` 随机数生成
- 退出码与短路逻辑

### 项目文件结构

```
02-guessing-game/
├── README.md            # 本教程文档
├── game.sh              # 基础猜数字游戏
├── game_advanced.sh     # 高级版（排行榜、计时、颜色）
└── exercises.sh         # 练习题模板
```

---

## 核心概念详解

### 1. 条件判断（if/elif/else）

#### 1.1 基本语法

```bash
# 单分支
if [[ condition ]]; then
    # 代码块
fi

# 双分支
if [[ condition ]]; then
    # 条件为真
else
    # 条件为假
fi

# 多分支
if [[ condition1 ]]; then
    # 条件1为真
elif [[ condition2 ]]; then
    # 条件2为真
else
    # 都不满足
fi

# 单行写法（简短命令）
if [[ -f "$file" ]]; then echo "文件存在"; fi

# 短路写法
[[ -f "$file" ]] && echo "存在" || echo "不存在"
```

#### 1.2 test 命令与 `[ ]` vs `[[ ]]`

| 特性 | `[ ]` (test) | `[[ ]]` (Bash 扩展) |
|------|-------------|---------------------|
| POSIX 兼容 | ✅ 是 | ❌ 否（Bash/Zsh） |
| 字符串比较 | `=` `!=` | `==` `!=` `=~`（正则） |
| 通配符匹配 | ❌ | ✅ `[[ $var == *.txt ]]` |
| 正则匹配 | ❌ | ✅ `[[ $var =~ ^[0-9]+$ ]]` |
| 逻辑组合 | `-a` `-o` | `&&` `\|\|` |
| 变量安全 | 需要引号 `"$var"` | 可以不引号（但仍推荐） |
| `<` `>` | 需要转义 `\<` `\>` | 直接使用 |

**推荐：始终使用 `[[ ]]`**，除非需要严格 POSIX 兼容。

```bash
# [[ ]] 的优势示例
name="hello123"

# 通配符匹配
[[ "$name" == hello* ]] && echo "以 hello 开头"

# 正则匹配
[[ "$name" =~ ^[a-z]+[0-9]+$ ]] && echo "字母+数字格式"

# 不需要担心变量为空时的语法错误
[[ $undefined_var == "test" ]]   # 不会报错
[ $undefined_var = "test" ]      # ❌ 可能报错
```

#### 1.3 字符串比较

```bash
a="hello"
b="world"

[[ "$a" == "$b" ]]    # 等于
[[ "$a" != "$b" ]]    # 不等于
[[ -z "$a" ]]          # 为空（长度为0）
[[ -n "$a" ]]          # 非空（长度>0）
[[ "$a" < "$b" ]]      # 字典序小于
```

#### 1.4 数字比较

| 运算符 | 含义 | 记忆 |
|--------|------|------|
| `-eq` | 等于 | **eq**ual |
| `-ne` | 不等于 | **n**ot **e**qual |
| `-lt` | 小于 | **l**ess **t**han |
| `-gt` | 大于 | **g**reater **t**han |
| `-le` | 小于等于 | **l**ess or **e**qual |
| `-ge` | 大于等于 | **g**reater or **e**qual |

```bash
a=10; b=20
[[ $a -lt $b ]] && echo "$a 小于 $b"

# 在 (( )) 中可以直接用 < > == 等
(( a < b )) && echo "$a 小于 $b"
(( a == 10 )) && echo "a 等于 10"
```

#### 1.5 逻辑运算

```bash
# && 与（两个都为真才为真）
[[ $a -gt 5 && $a -lt 15 ]] && echo "在范围内"

# || 或（一个为真就为真）
[[ "$color" == "红" || "$color" == "蓝" ]] && echo "红或蓝"

# ! 非（取反）
[[ ! -f "$file" ]] && echo "文件不存在"

# 复杂组合
if [[ ( $age -ge 18 && $age -le 65 ) && "$has_ticket" == "yes" ]]; then
    echo "允许入场"
fi
```

#### 1.6 文件测试运算符

| 运算符 | 说明 | 示例 |
|--------|------|------|
| `-e` | 存在 | `[[ -e "$f" ]]` |
| `-f` | 是常规文件 | `[[ -f "$f" ]]` |
| `-d` | 是目录 | `[[ -d "$d" ]]` |
| `-r` | 可读 | `[[ -r "$f" ]]` |
| `-w` | 可写 | `[[ -w "$f" ]]` |
| `-x` | 可执行 | `[[ -x "$f" ]]` |
| `-s` | 非空（大小>0） | `[[ -s "$f" ]]` |
| `-L` | 是符号链接 | `[[ -L "$f" ]]` |

---

### 2. 循环（for/while/until）

#### 2.1 for 循环的三种形式

```bash
# 形式一：列表遍历
for fruit in "苹果" "香蕉" "橙子"; do
    echo "水果: $fruit"
done

# 形式二：范围遍历
for i in {1..10}; do
    echo "数字: $i"
done

# 带步长
for i in {0..20..5}; do
    echo "$i"  # 0, 5, 10, 15, 20
done

# 形式三：C 风格 for
for ((i = 0; i < 10; i++)); do
    echo "索引: $i"
done

# 遍历文件
for file in *.txt; do
    echo "文件: $file"
done

# 遍历命令输出
for user in $(cat /etc/passwd | cut -d: -f1); do
    echo "用户: $user"
done
```

#### 2.2 while 循环

```bash
# 基本 while
count=1
while [[ $count -le 5 ]]; do
    echo "第 $count 次"
    ((count++))
done

# 读取文件（推荐方式）
while IFS= read -r line; do
    echo "行: $line"
done < "data.txt"

# 无限循环
while true; do
    read -p "输入 quit 退出: " input
    [[ "$input" == "quit" ]] && break
done

# 等价的无限循环写法
while :; do
    # ...
    break
done
```

#### 2.3 until 循环（条件为假时执行）

```bash
# until: 条件为假时继续循环（与 while 相反）
count=1
until [[ $count -gt 5 ]]; do
    echo "第 $count 次"
    ((count++))
done
```

#### 2.4 break 和 continue

```bash
# break: 跳出整个循环
for i in {1..100}; do
    [[ $i -gt 10 ]] && break
    echo "$i"
done

# continue: 跳过当前迭代
for i in {1..10}; do
    [[ $((i % 2)) -eq 0 ]] && continue  # 跳过偶数
    echo "$i"  # 只输出奇数
done

# break N: 跳出 N 层循环
for i in {1..5}; do
    for j in {1..5}; do
        [[ $j -eq 3 ]] && break 2  # 跳出两层
        echo "$i-$j"
    done
done
```

---

### 3. case 语句

`case` 是 Bash 中的模式匹配语句，类似于其他语言的 `switch`。

```bash
# 基本语法
case "$variable" in
    pattern1)
        # 代码块
        ;;
    pattern2)
        # 代码块
        ;;
    *)
        # 默认分支（类似 default）
        ;;
esac

# 多模式匹配（用 | 分隔）
case "$choice" in
    y|Y|yes|YES)
        echo "确认"
        ;;
    n|N|no|NO)
        echo "取消"
        ;;
    *)
        echo "无效输入"
        ;;
esac

# 通配符模式
case "$filename" in
    *.jpg|*.png|*.gif)  echo "图片文件" ;;
    *.txt|*.md)          echo "文本文件" ;;
    *.sh)                echo "Shell 脚本" ;;
    *)                   echo "未知类型" ;;
esac

# 范围匹配
case "$char" in
    [a-z]) echo "小写字母" ;;
    [A-Z]) echo "大写字母" ;;
    [0-9]) echo "数字" ;;
    *)     echo "其他字符" ;;
esac
```

---

### 4. RANDOM 变量

`$RANDOM` 是 Bash 的内置变量，每次引用返回一个 0~32767 之间的随机整数。

```bash
# 基本用法
echo $RANDOM                    # 0 ~ 32767

# 生成指定范围的随机数
# 公式: $((RANDOM % (max - min + 1) + min))
echo $((RANDOM % 50 + 1))      # 1 ~ 50
echo $((RANDOM % 100))          # 0 ~ 99
echo $((RANDOM % 100 + 1))      # 1 ~ 100

# 设置种子（使随机序列可重现）
RANDOM=42
echo $RANDOM  # 每次运行都相同

# 基于时间的种子
RANDOM=$(date +%s)
```

---

### 5. 退出码（Exit Code）

```bash
# $? 保存上一个命令的退出码
ls /tmp
echo $?    # 0（成功）

ls /nonexistent
echo $?    # 2（失败）

# 自定义退出码
exit 0     # 成功
exit 1     # 一般错误
exit 2     # 用法错误

# 在条件判断中利用退出码
if some_command; then
    echo "成功"
else
    echo "失败，退出码: $?"
fi
```

**退出码约定：**

| 退出码 | 含义 |
|--------|------|
| 0 | 成功 |
| 1 | 一般错误 |
| 2 | 误用 shell 命令 |
| 126 | 权限不足 |
| 127 | 命令未找到 |
| 128+N | 被信号 N 终止 |
| 130 | 被 Ctrl+C 终止 |
| 255 | 退出码越界 |

---

### 6. 逻辑运算符短路

```bash
# && 短路与：第一个为假，不执行第二个
command1 && command2
# 等价于:
# if command1; then command2; fi

# || 短路或：第一个为真，不执行第二个
command1 || command2
# 等价于:
# if ! command1; then command2; fi

# 组合使用
mkdir -p /tmp/test && cd /tmp/test && echo "成功"

# 默认值模式
name="${input:-默认值}"

# 条件执行模式
[[ -f "$config" ]] && source "$config" || echo "配置文件不存在"
```

---

### 工具对比表

#### `[]` vs `[[]]` 对比

| 特性 | `[ ]` | `[[ ]]` |
|------|-------|---------|
| 标准 | POSIX | Bash 扩展 |
| 字符串比较 | `=` | `==` |
| 模式匹配 | ❌ | `== glob` |
| 正则匹配 | ❌ | `=~ regex` |
| 逻辑运算 | `-a` `-o` | `&&` `\|\|` |
| 变量安全 | 需引号 | 较安全 |
| 性能 | 外部命令 | 内建 |

#### `for` vs `while` 选择指南

| 场景 | 推荐 |
|------|------|
| 遍历已知列表 | `for item in list` |
| 遍历数字范围 | `for ((i=0; i<n; i++))` |
| 读取文件每一行 | `while read -r line` |
| 条件循环 | `while [[ condition ]]` |
| 无限循环 | `while true` 或 `while :` |

---

## 游戏设计

### 游戏流程图

```
┌─────────────┐
│  开始游戏    │
└──────┬──────┘
       ▼
┌─────────────┐
│  选择难度    │
│  1.简单(1-50)│
│  2.中等(1-100)│
│  3.困难(1-500)│
└──────┬──────┘
       ▼
┌─────────────┐     ┌──────────┐
│  生成随机数  │────►│ 游戏循环  │
└─────────────┘     └────┬─────┘
                         ▼
                  ┌─────────────┐
                  │  用户猜测    │◄────────────┐
                  └──────┬──────┘             │
                         ▼                    │
                  ┌─────────────┐             │
                  │  比较大小    │             │
                  └──────┬──────┘             │
                         │                    │
              ┌──────────┼──────────┐         │
              ▼          ▼          ▼         │
         ┌──────┐  ┌──────────┐  ┌──────┐   │
         │ 大了  │  │  正确!   │  │ 小了  │   │
         └──┬───┘  └────┬─────┘  └──┬───┘   │
            │           ▼           │        │
            │     ┌──────────┐      │        │
            │     │ 计算分数  │      │        │
            │     └────┬─────┘      │        │
            │          ▼            │        │
            │     ┌──────────┐      │        │
            │     │ 再来一局? │      │        │
            │     └────┬─────┘      │        │
            │     是/否 │            │        │
            └───────────┴────────────┘        │
                是                            │
                 └────────────────────────────┘
```

---

## 运行方式

```bash
cd /home/faust/vibe/bash_learn/02-guessing-game
chmod +x game.sh game_advanced.sh

# 运行基础版
./game.sh

# 运行高级版
./game_advanced.sh
```

---

## 练习题

### 练习 1：添加提示系统
当用户连续猜错 3 次时，自动缩小提示范围（如"答案在 30-70 之间"）。

### 练习 2：多人模式
支持 2-4 名玩家轮流猜数字，记录每人猜的次数，最后比较胜负。

### 练习 3：自定义范围
让玩家自己设定数字范围和最大尝试次数。

### 练习 4：猜数字 AI
编写一个自动猜数字的 AI，使用二分查找策略，展示 AI 的猜测过程。

### 练习 5：历史记录
将每次游戏的结果保存到文件，支持查看历史最高分排行榜。
