# 项目 03：文件整理器 — 文件与目录操作

## 项目简介

在本项目中，我们将构建一个智能文件整理工具，能按类型、日期或大小自动分类文件到有序的目录结构中。通过这个项目，你将掌握 Bash 中文件操作、`find` 命令和函数编程。

### 你将学到什么

- 文件操作命令（cp、mv、rm、mkdir、touch、ln）
- `find` 命令的深度使用
- 文件测试运算符
- 通配符与 Globbing
- 函数定义与调用
- `xargs` 命令

### 项目文件结构

```
03-file-organizer/
├── README.md              # 本教程文档
├── organizer.sh           # 基础文件整理器
├── organizer_advanced.sh  # 高级版（按日期、去重、撤销）
├── test_setup.sh          # 创建测试文件
└── exercises.sh           # 练习题模板
```

---

## 核心概念详解

### 1. 文件操作命令

#### 1.1 复制、移动、删除

```bash
# 复制
cp source.txt dest.txt           # 复制文件
cp -r source_dir/ dest_dir/      # 递归复制目录
cp -p source.txt dest.txt        # 保留权限和时间戳
cp -i source.txt dest.txt        # 覆盖前确认
cp -u source.txt dest.txt        # 只复制更新的文件

# 移动/重命名
mv old.txt new.txt               # 重命名
mv file.txt /path/to/dir/        # 移动
mv -i *.txt /backup/             # 批量移动，覆盖前确认

# 删除
rm file.txt                      # 删除文件
rm -i file.txt                   # 删除前确认
rm -r directory/                 # 递归删除目录
rm -rf directory/                # 强制递归删除（⚠️ 危险！）

# 创建目录
mkdir -p /path/to/nested/dir     # -p 递归创建多级目录

# 创建文件
touch newfile.txt                # 创建空文件或更新时间戳
```

#### 1.2 硬链接 vs 软链接

```bash
# 硬链接（共享同一 inode，删除原文件不影响链接）
ln source.txt hardlink.txt

# 软链接/符号链接（指向原文件路径，类似快捷方式）
ln -s /path/to/source.txt symlink.txt

# 区别:
# 硬链接: 不能跨文件系统，不能链接目录
# 软链接: 可以跨文件系统，可以链接目录
```

---

### 2. find 命令深度解析

`find` 是 Linux 中最强大的文件搜索工具。

#### 2.1 基本语法

```bash
find [搜索路径] [匹配条件] [操作]
```

#### 2.2 按名称查找

```bash
# 按文件名（区分大小写）
find /home -name "*.txt"

# 按文件名（不区分大小写）
find /home -iname "*.JPG"

# 按路径模式
find /var -path "*/log/*.gz"
```

#### 2.3 按类型查找

```bash
find /tmp -type f      # 常规文件
find /tmp -type d      # 目录
find /tmp -type l      # 符号链接
find /tmp -type b      # 块设备
find /tmp -type c      # 字符设备
```

#### 2.4 按大小查找

```bash
find /home -size +100M     # 大于 100MB
find /home -size -1M       # 小于 1MB
find /home -size 0         # 空文件
find /home -size +1G -size -10G   # 1G 到 10G 之间
```

#### 2.5 按时间查找

```bash
find /home -mtime -7       # 最近 7 天内修改
find /home -mtime +30      # 超过 30 天前修改
find /home -mmin -60       # 最近 60 分钟内修改
find /home -atime -1       # 最近 1 天内访问
find /home -ctime -7       # 最近 7 天内状态改变
find /home -newer ref.txt  # 比 ref.txt 更新的文件
```

**时间参数对比：**

| 参数 | 含义 | 单位 |
|------|------|------|
| `-mtime` | 修改时间 (内容) | 天 |
| `-atime` | 访问时间 | 天 |
| `-ctime` | 变更时间 (元数据) | 天 |
| `-mmin` | 修改时间 | 分钟 |
| `-amin` | 访问时间 | 分钟 |
| `-newer` | 比某文件更新 | — |

#### 2.6 按权限查找

```bash
find /home -perm 644       # 精确匹配权限
find /home -perm -644      # 至少有这些权限
find /home -perm /644      # 任一权限匹配
find /home -user john      # 属于用户 john
find /home -group devs     # 属于组 devs
```

#### 2.7 逻辑组合

```bash
# 与（-and 可省略）
find /home -name "*.txt" -size +1M

# 或
find /home \( -name "*.jpg" -o -name "*.png" \)

# 非
find /home -name "*.txt" ! -name "README*"

# 复杂组合
find /home \( -name "*.log" -o -name "*.tmp" \) -mtime +30
```

#### 2.8 -exec 执行操作

```bash
# 对每个匹配文件执行命令
find /home -name "*.tmp" -exec rm {} \;

# 使用 + 替代 \; 提高效率（批量传递参数）
find /home -name "*.txt" -exec grep -l "TODO" {} +

# 删除 30 天前的日志
find /var/log -name "*.log" -mtime +30 -exec rm {} \;

# 复制找到的文件
find /source -name "*.jpg" -exec cp {} /dest/ \;

# 使用 xargs 配合
find /home -name "*.txt" -print0 | xargs -0 grep "pattern"
```

#### 2.9 安全处理文件名（含空格/特殊字符）

```bash
# ❌ 不安全：文件名有空格时会出错
find . -name "*.txt" | xargs rm

# ✅ 安全：使用 -print0 和 xargs -0
find . -name "*.txt" -print0 | xargs -0 rm

# ✅ 安全：使用 -exec
find . -name "*.txt" -exec rm {} +
```

---

### 3. 文件测试运算符

| 运算符 | 说明 | 示例 |
|--------|------|------|
| `-e` | 文件存在 | `[[ -e "$f" ]]` |
| `-f` | 是常规文件 | `[[ -f "$f" ]]` |
| `-d` | 是目录 | `[[ -d "$d" ]]` |
| `-L` | 是符号链接 | `[[ -L "$f" ]]` |
| `-r` | 可读 | `[[ -r "$f" ]]` |
| `-w` | 可写 | `[[ -w "$f" ]]` |
| `-x` | 可执行 | `[[ -x "$f" ]]` |
| `-s` | 非空（大小 > 0） | `[[ -s "$f" ]]` |
| `-nt` | 更新于（newer than） | `[[ "$a" -nt "$b" ]]` |
| `-ot` | 旧于（older than） | `[[ "$a" -ot "$b" ]]` |

```bash
if [[ -f "$config" && -r "$config" ]]; then
    source "$config"
fi

# 检查文件是否为空
if [[ ! -s "$logfile" ]]; then
    echo "日志文件为空"
fi
```

---

### 4. 通配符与 Globbing

#### 4.1 基本通配符

| 通配符 | 说明 | 示例 |
|--------|------|------|
| `*` | 匹配任意字符（任意数量） | `*.txt` |
| `?` | 匹配任意单个字符 | `file?.txt` |
| `[abc]` | 匹配方括号中的任一字符 | `file[123].txt` |
| `[a-z]` | 匹配范围中的任一字符 | `[a-z]*.txt` |
| `[!abc]` | 匹配不在方括号中的字符 | `[!0-9]*` |
| `{a,b,c}` | 匹配大括号中的任一项 | `*.{jpg,png,gif}` |

```bash
# 示例
ls *.txt              # 所有 .txt 文件
ls image?.png         # image1.png, imageA.png 等
ls [0-9]*             # 以数字开头的文件
ls *.{jpg,png,gif}    # 所有图片文件
```

#### 4.2 extglob 扩展通配符

```bash
# 启用 extglob
shopt -s extglob

# 模式说明
?(pattern)    # 零次或一次
*(pattern)    # 零次或多次
+(pattern)    # 一次或多次
@(pattern)    # 精确一次
!(pattern)    # 不匹配

# 示例
ls *.+(txt|md)        # .txt 或 .md 文件
ls !(*.tmp|*.bak)     # 不是 .tmp 或 .bak 的文件
ls @(main|index).*    # main.* 或 index.*
```

---

### 5. 函数（Functions）

#### 5.1 定义语法

```bash
# 方式一（推荐）
function_name() {
    # 代码块
}

# 方式二
function function_name {
    # 代码块
}
```

#### 5.2 参数传递

```bash
greet() {
    echo "你好, $1!"        # $1 = 第一个参数
    echo "年龄: $2"          # $2 = 第二个参数
    echo "参数个数: $#"      # $# = 参数总数
    echo "所有参数: $@"      # $@ = 所有参数（各自独立）
    echo "所有参数: $*"      # $* = 所有参数（合并为一个）
}

greet "张三" 25 "北京"
```

#### 5.3 返回值

```bash
# 方式一：return（返回 0-255 的退出码）
is_even() {
    (( $1 % 2 == 0 )) && return 0 || return 1
}

if is_even 42; then
    echo "42 是偶数"
fi

# 方式二：echo（返回任意字符串，推荐）
get_extension() {
    local filename="$1"
    echo "${filename##*.}"
}

ext=$(get_extension "photo.jpg")
echo "扩展名: $ext"   # jpg
```

#### 5.4 局部变量

```bash
my_function() {
    local count=10          # 局部变量，函数外不可见
    local name="$1"         # 接收参数作为局部变量
    result=$((count + 5))   # ⚠️ 没有 local，是全局变量
    echo "$name: $result"
}
```

#### 5.5 递归函数

```bash
# 递归计算目录大小
dir_size() {
    local dir="$1"
    local total=0

    for item in "$dir"/*; do
        if [[ -f "$item" ]]; then
            local size
            size=$(stat -c%s "$item" 2>/dev/null || echo 0)
            total=$((total + size))
        elif [[ -d "$item" ]]; then
            local sub_size
            sub_size=$(dir_size "$item")
            total=$((total + sub_size))
        fi
    done

    echo "$total"
}
```

---

### 6. xargs 命令

```bash
# 基本用法：将 stdin 转为命令参数
echo "file1 file2 file3" | xargs rm

# -I 占位符
find . -name "*.bak" | xargs -I {} mv {} /backup/

# -n 每次传递的参数数量
echo "1 2 3 4 5 6" | xargs -n 2 echo
# 输出:
# 1 2
# 3 4
# 5 6

# -P 并行执行
find . -name "*.jpg" | xargs -P 4 -I {} convert {} -resize 50% thumb_{}

# -0 处理含空格的文件名
find . -name "*.txt" -print0 | xargs -0 wc -l
```

---

### 文件迭代方式对比

| 方式 | 语法 | 处理特殊文件名 | 性能 |
|------|------|---------------|------|
| `for f in *.txt` | `for f in *.txt; do ...` | ⚠️ 空格会拆分 | 快 |
| `find -exec` | `find . -exec cmd {} \;` | ✅ 安全 | 中 |
| `find + xargs -0` | `find -print0 \| xargs -0` | ✅ 安全 | 最快 |
| `while read` | `find \| while read -r f` | ⚠️ 需要 IFS= | 中 |

---

## 整理器架构

```
┌──────────────────────────────────────────┐
│           文件整理器工作流程               │
├──────────────────────────────────────────┤
│                                          │
│  [扫描目录] ──► [读取文件扩展名]           │
│       │                                  │
│       ▼                                  │
│  [分类判断]                               │
│   ├── .jpg/.png/.gif  → images/          │
│   ├── .pdf/.doc/.txt  → documents/       │
│   ├── .mp4/.avi/.mkv  → videos/          │
│   ├── .mp3/.wav/.flac → audio/           │
│   ├── .zip/.tar/.gz   → archives/        │
│   └── 其他             → others/          │
│       │                                  │
│       ▼                                  │
│  [处理冲突] ──► [移动文件] ──► [记录日志]  │
│                                          │
└──────────────────────────────────────────┘
```

---

## 运行方式

```bash
cd /home/faust/vibe/bash_learn/03-file-organizer
chmod +x organizer.sh organizer_advanced.sh test_setup.sh

# 1. 创建测试文件
bash test_setup.sh

# 2. 预览整理（不实际移动）
bash organizer.sh --dry-run /path/to/messy/dir

# 3. 执行整理
bash organizer.sh /path/to/messy/dir

# 4. 高级版：按日期整理
bash organizer_advanced.sh --by-date /path/to/dir

# 5. 高级版：查重
bash organizer_advanced.sh --dedup /path/to/dir
```

---

## 练习题

### 练习 1：撤销功能
基于日志文件实现 `--undo` 选项，将文件移回原位。

### 练习 2：自定义规则
支持从配置文件读取自定义分类规则（如 `*.psd → design/`）。

### 练习 3：定时整理
编写一个 cron 兼容的版本，每天自动整理下载目录。

### 练习 4：文件统计报告
整理完成后输出统计报告：每个分类多少文件、总大小等。

### 练习 5：递归整理
支持递归处理子目录，但跳过特定目录（如 .git、node_modules）。
