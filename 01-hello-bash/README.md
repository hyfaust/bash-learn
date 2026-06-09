# 项目 01：Hello Bash — 变量与基础 I/O

## 项目简介

欢迎来到 Bash 学习之旅的第一站！在这个项目中，我们将构建一个 **个性化问候卡生成器**，通过它来学习 Bash 中最基础也最重要的概念：变量、字符串操作、输入输出和算术运算。

### 你将学到什么

- 变量的定义、使用和作用域
- 字符串的各种操作方法
- `echo` 和 `printf` 的格式化输出
- `read` 命令的用户输入
- Bash 中的算术运算方式
- 标量变量的内存模型

### 项目文件结构

```
01-hello-bash/
├── README.md            # 本教程文档
├── hello.sh             # Hello World 入门脚本
├── greeting_card.sh     # 问候卡生成器（主项目）
└── exercises.sh         # 练习题模板
```

---

## 核心概念详解

### 1. 变量（Variables）

变量是编程的基石。在 Bash 中，变量用于存储数据，可以是字符串、数字等各种类型。

#### 1.1 局部变量 vs 环境变量

| 特性 | 局部变量 | 环境变量 |
|------|---------|---------|
| 作用域 | 仅当前 Shell | 当前 Shell 及所有子进程 |
| 定义方式 | `VAR=value` | `export VAR=value` |
| 命名约定 | 小写或大小写混合 | 通常全大写 |
| 常见用途 | 脚本内部临时数据 | PATH、HOME 等系统配置 |
| 子进程可见 | ❌ 不可见 | ✅ 可见 |

```bash
# 局部变量（仅在当前 shell 可见）
name="张三"
echo "$name"       # 输出: 张三

# 环境变量（子进程也可继承）
export APP_NAME="MyApp"
bash -c 'echo "$APP_NAME"'   # 输出: MyApp

# 查看所有环境变量
env
printenv
```

#### 1.2 变量命名规则

```bash
# ✅ 合法的变量名
user_name="张三"
_count=10
MAX_SIZE=1024
myVar2="hello"

# ❌ 非法的变量名
2name="错误"       # 不能以数字开头
my-name="错误"     # 不能包含连字符
my name="错误"     # 不能包含空格
```

#### 1.3 赋值与引用

```bash
# ⚠️ 关键规则：= 两边不能有空格！
name="Hello"      # ✅ 正确
name = "Hello"    # ❌ 错误！Bash 会把 name 当作命令

# 引用变量（$ 符号）
echo "$name"       # 推荐：双引号引用
echo "$name World" # 变量和文本混用
echo ${name}       # 花括号形式
echo "${name}World" # 花括号避免歧义

# 不加引号的问题
msg="Hello World"
echo $msg          # 可能被拆分成两个参数
echo "$msg"        # 正确：保留空格，推荐始终加双引号
```

#### 1.4 readonly 和 unset

```bash
# 只读变量（定义后不可修改）
readonly PI=3.14159
PI=3.14            # ❌ 报错: readonly variable

# 删除变量
temp="临时数据"
unset temp
echo "$temp"       # 输出为空（变量已不存在）

# readonly 的变量不能 unset
readonly FIXED="固定值"
unset FIXED        # ❌ 报错: readonly variable
```

---

### 2. 字符串操作

Bash 中变量本质上都是字符串（即使存储的是数字），因此字符串操作非常重要。

#### 2.1 拼接

```bash
first="Hello"
second="World"

# 直接拼接
greeting="$first $second"      # "Hello World"
path="/home""/user""/docs"     # "/home/user/docs"

# 混合文本
msg="你好, ${first}!"          # "你好, Hello!"
```

#### 2.2 长度

```bash
str="Hello Bash"
echo "${#str}"     # 输出: 10（字符数）

# 数组长度用 #arr[@]，字符串长度用 #str
```

#### 2.3 子串提取

```bash
str="Hello Bash World"

echo "${str:0:5}"    # "Hello"      （从位置0开始，取5个字符）
echo "${str:6:4}"    # "Bash"       （从位置6开始，取4个字符）
echo "${str:6}"      # "Bash World" （从位置6到末尾）
echo "${str: -5}"    # "World"      （从倒数第5个开始，注意冒号后有空格）
```

#### 2.4 查找与替换

```bash
str="Hello Bash Hello World"

# 替换第一个匹配
echo "${str/Hello/Hi}"      # "Hi Bash Hello World"

# 替换所有匹配（双斜杠）
echo "${str//Hello/Hi}"     # "Hi Bash Hi World"

# 删除匹配（替换为空）
echo "${str//Hello/}"       # " Bash  World"

# 前缀删除（最短匹配）
echo "${str#Hello}"         # " Bash Hello World"

# 前缀删除（最长匹配）
path="/home/user/docs"
echo "${path#*/}"           # "home/user/docs"
echo "${path##*/}"          # "docs"（类似 basename）

# 后缀删除
echo "${path%/*}"           # "/home/user"（类似 dirname）
echo "${path%%/*}"          # ""（删除所有 /）
```

#### 2.5 默认值

```bash
# ${var:-default} — 变量未定义或为空时使用默认值
name="${USER:-anonymous}"
echo "欢迎, $name"

# ${var:=default} — 变量未定义或为空时，赋值并使用
: "${config_dir:=/etc/myapp}"
echo "$config_dir"    # /etc/myapp

# ${var:+alternate} — 变量已定义且非空时使用替代值
debug=true
echo "调试模式: ${debug:+已启用}"   # "调试模式: 已启用"

# ${var:?error} — 变量未定义或为空时报错退出
: "${DB_HOST:?数据库地址未配置}"
```

---

### 3. echo 与 printf

#### 3.1 echo 命令

```bash
# 基本输出
echo "Hello World"

# -e 启用转义字符
echo -e "第一行\n第二行"        # \n 换行
echo -e "姓名:\t张三"           # \t 制表符
echo -e "\033[31m红色文字\033[0m" # ANSI 颜色

# -n 不换行
echo -n "请输入: "

# 常用转义序列
# \n  换行      \t  制表符      \\  反斜杠
# \a  响铃      \r  回车        \b  退格
```

#### 3.2 printf 命令

`printf` 比 `echo` 更强大，支持精确的格式化控制。

```bash
# 基本格式化
printf "姓名: %s, 年龄: %d\n" "张三" 25

# 常用格式符
# %s   字符串
# %d   整数
# %f   浮点数
# %x   十六进制
# %o   八进制
# %b   解释转义序列

# 宽度控制
printf "%-20s %10d\n" "苹果" 100     # 左对齐20字符, 右对齐10字符
printf "%-20s %10d\n" "香蕉" 200
printf "%-20s %10d\n" "橙子" 300

# 输出:
# 苹果                        100
# 香蕉                        200
# 橙子                        300

# 浮点精度
printf "圆周率: %.4f\n" 3.14159     # "圆周率: 3.1416"

# 前补零
printf "编号: %05d\n" 42            # "编号: 00042"

# 百分号
printf "完成率: %d%%\n" 85          # "完成率: 85%"
```

---

### 4. read 命令

`read` 是 Bash 中从标准输入读取数据的核心命令。

#### 4.1 基本用法

```bash
# 基本读取
echo -n "请输入你的名字: "
read name
echo "你好, $name!"

# -p 提示符（一行完成提示+读取）
read -p "请输入年龄: " age
echo "你 $age 岁了"

# 同时读取多个变量
read -p "姓 名: " first last
echo "姓: $first, 名: $last"
```

#### 4.2 常用选项

| 选项 | 说明 | 示例 |
|------|------|------|
| `-p` | 显示提示文本 | `read -p "输入: " var` |
| `-s` | 静默模式（不显示输入） | `read -s -p "密码: " pwd` |
| `-t` | 超时秒数 | `read -t 5 -p "5秒内输入: " var` |
| `-n` | 限制读取字符数 | `read -n 1 -p "按任意键..." key` |
| `-r` | 禁止反斜杠转义 | `read -r line`（推荐） |
| `-a` | 读入数组 | `read -a arr <<< "a b c"` |
| `-d` | 指定结束符（默认换行） | `read -d '' var < file` |
| `-N` | 精确读取 N 个字符 | `read -N 4 code` |

```bash
# 密码输入（-s 隐藏）
read -s -p "请输入密码: " password
echo ""  # 换行（因为 -s 不会自动换行）
echo "密码长度: ${#password}"

# 超时读取
if read -t 10 -p "10秒内输入 (超时将使用默认值): " input; then
    echo "你输入了: $input"
else
    echo "超时，使用默认值"
fi

# 单字符读取
read -n 1 -p "确认删除? [y/N] " confirm
echo ""  # 换行
```

#### 4.3 IFS 与 read

IFS（Internal Field Separator）决定了 `read` 如何分割输入。

```bash
# 默认 IFS 是 空格、制表符、换行
read -p "输入两个数字: " a b    # 输入 "10 20" → a=10, b=20

# 自定义 IFS（读取 CSV 数据）
IFS=',' read -r name age city <<< "张三,25,北京"
echo "$name $age $city"

# 逐行读取文件
while IFS= read -r line; do
    echo "行: $line"
done < "data.txt"
```

---

### 5. 算术运算

Bash 支持多种算术运算方式，适用于不同的场景。

#### 5.1 `$(( ))` — 算术展开（推荐）

```bash
a=10; b=3

echo "$((a + b))"     # 13   加法
echo "$((a - b))"     # 7    减法
echo "$((a * b))"     # 30   乘法
echo "$((a / b))"     # 3    整数除法
echo "$((a % b))"     # 1    取余
echo "$((a ** 2))"    # 100  幂运算

# 自增自减
((a++))    # a 变为 11
((a--))    # a 变回 10
((a += 5)) # a 变为 15

# 比较运算（返回 0=真/1=假，用于条件判断）
if ((a > b)); then echo "a 更大"; fi
```

#### 5.2 let 命令

```bash
let "result = 10 + 5"     # result=15
let "x = 2 ** 10"         # x=1024
let "y++"                 # y 自增 1
```

#### 5.3 expr 命令（较老的方式）

```bash
# 注意：运算符两边必须有空格，且 * 需要转义
result=$(expr 10 + 5)     # result=15
result=$(expr 10 \* 5)    # result=50（* 必须转义）
```

#### 5.4 bc — 浮点运算

Bash 的 `$(( ))` 只支持整数。浮点运算需要 `bc`。

```bash
# bc 基本用法
echo "3.14 * 2" | bc            # 6.28

# 设置精度
echo "scale=4; 10 / 3" | bc     # 3.3333

# bc 用于变量计算
pi=$(echo "scale=10; 4*a(1)" | bc -l)   # 3.1415926535
area=$(echo "scale=2; $pi * 5 * 5" | bc)
echo "半径5的圆面积: $area"             # 78.53
```

#### 5.5 运算符优先级

| 优先级 | 运算符 | 说明 |
|--------|--------|------|
| 1（最高） | `()` | 括号 |
| 2 | `**` | 幂运算 |
| 3 | `*` `/` `%` | 乘、除、取余 |
| 4 | `+` `-` | 加、减 |
| 5 | `<<` `>>` | 位移 |
| 6 | `<` `<=` `>` `>=` | 比较 |
| 7 | `==` `!=` | 等于、不等于 |
| 8 | `&` | 按位与 |
| 9 | `^` | 按位异或 |
| 10 | `\|` | 按位或 |
| 11 | `&&` | 逻辑与 |
| 12（最低） | `\|\|` | 逻辑或 |

---

### 6. 数据结构：标量变量的内存模型

在 Bash 中，所有变量本质上都是 **字符串**。即使你存储一个数字，它在内存中也是以字符形式存在。

```
┌─────────────────────────────────────────────┐
│            Bash 符号表 (Symbol Table)         │
├──────────────┬──────────────────────────────┤
│  变量名       │  值 (字符串)                   │
├──────────────┼──────────────────────────────┤
│  name        │  "张三"         → 字节: E5BC.. │
│  age         │  "25"           → 字节: 32 35 │
│  path        │  "/home/user"   → 字节: 2F.. │
│  PI          │  "3.14159"      → 字节: 33.. │
└──────────────┴──────────────────────────────┘

  当使用 $(( )) 进行算术运算时:
  Bash 会将字符串临时转换为整数进行计算
  计算结果再转回字符串存储

  "25"  ──(ASCII转整数)──►  25  ──(+1)──►  26  ──(整数转ASCII)──►  "26"
```

这就是为什么：
- 赋值时 `=` 两边不能有空格（语法要求）
- 浮点运算需要 `bc`（Bash 内部不支持浮点转换）
- 变量比较时有 `-eq`（整数比较）和 `==`（字符串比较）之分

---

## 运行方式

```bash
# 进入项目目录
cd /home/faust/vibe/bash_learn/01-hello-bash

# 给脚本添加执行权限
chmod +x hello.sh greeting_card.sh exercises.sh

# 运行 Hello World 脚本
./hello.sh

# 运行问候卡生成器
./greeting_card.sh

# 或者使用 bash 命令直接运行（无需 chmod）
bash hello.sh
bash greeting_card.sh
```

---

## 练习题

### 练习 1：温度转换器
编写脚本，读取用户输入的摄氏温度，转换为华氏温度并输出。公式：`F = C * 9/5 + 32`

### 练习 2：字符串反转
编写函数，接收一个字符串参数，输出其反转结果。例如 "Hello" → "olleH"

### 练习 3：信息表格
使用 `printf` 打印一个格式化的个人信息表格，包含姓名、年龄、城市、职业四列，带边框线。

### 练习 4：简易计算器
读取用户输入的两个数字和运算符（+、-、*、/），输出计算结果。使用 `bc` 支持浮点运算。

### 练习 5：ASCII 艺术
使用 `echo` 和转义字符，输出一个用特殊字符组成的图案（如三角形、菱形或你的名字首字母）。
