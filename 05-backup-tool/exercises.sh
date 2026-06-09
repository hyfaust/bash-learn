#!/bin/bash
# ============================================================================
# exercises.sh — 项目 05 练习题
# 用法: bash exercises.sh          # 运行练习
#       bash exercises.sh --answers # 查看并运行参考答案
# ============================================================================

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
CYAN='\033[0;36m'; BOLD='\033[1m'; NC='\033[0m'

MODE="practice"
[[ "${1:-}" == "--answers" ]] && MODE="answers"

# ============================================================================
# 练习 1：配置文件解析
# 从 ~/.backup.conf 读取默认参数，命令行参数优先
# ============================================================================
exercise_1() {
    echo -e "\n${YELLOW}━━━ 练习 1：配置文件解析 ━━━${NC}"

    if [[ "$MODE" == "answers" ]]; then
        echo -e "${GREEN}[参考答案]${NC}"
        # 创建测试配置
        local conf
        conf=$(mktemp)
        cat > "$conf" <<'EOF'
# 备份配置
SOURCE_DIR=/home/user/documents
BACKUP_DIR=/mnt/backup
COMPRESS=gzip
KEEP_DAYS=30
EXCLUDE=.git:node_modules:*.tmp
EOF
        echo "  配置文件:"
        cat "$conf" | sed 's/^/    /'

        # 解析函数
        load_config() {
            local file="$1"
            while IFS='=' read -r key value; do
                [[ "$key" =~ ^[[:space:]]*# ]] && continue
                [[ -z "$key" ]] && continue
                key=$(echo "$key" | xargs)  # trim
                value=$(echo "$value" | xargs)
                case "$key" in
                    SOURCE_DIR) SOURCE_DIR="$value" ;;
                    BACKUP_DIR) BACKUP_DIR="$value" ;;
                    COMPRESS)   COMPRESS="$value" ;;
                    KEEP_DAYS)  KEEP_DAYS="$value" ;;
                    EXCLUDE)    EXCLUDE="$value" ;;
                esac
            done < "$file"
        }

        # 加载配置
        SOURCE_DIR="." BACKUP_DIR="." COMPRESS="none" KEEP_DAYS="7" EXCLUDE=""
        load_config "$conf"

        echo ""
        echo "  解析结果:"
        echo "    SOURCE_DIR=$SOURCE_DIR"
        echo "    BACKUP_DIR=$BACKUP_DIR"
        echo "    COMPRESS=$COMPRESS"
        echo "    KEEP_DAYS=$KEEP_DAYS"
        echo "    EXCLUDE=$EXCLUDE"

        echo ""
        echo "  命令行覆盖演示:"
        COMPRESS="bzip2"  # 模拟命令行参数
        echo "    COMPRESS=$COMPRESS (命令行覆盖)"

        rm -f "$conf"
    else
        # TODO: 解析配置文件
        # while IFS='=' read -r key value; do
        #     [[ "$key" =~ ^# ]] && continue
        #     declare "$key=$value"
        # done < ~/.backup.conf
        echo "待实现..."
    fi
}

# ============================================================================
# 练习 2：差异备份
# 差异备份基于最近一次全量的快照
# ============================================================================
exercise_2() {
    echo -e "\n${YELLOW}━━━ 练习 2：差异备份 ━━━${NC}"

    if [[ "$MODE" == "answers" ]]; then
        echo -e "${GREEN}[参考答案]${NC}"
        local tmpdir
        tmpdir=$(mktemp -d)
        mkdir -p "$tmpdir/source" "$tmpdir/backup"

        # 创建初始文件
        echo "file1" > "$tmpdir/source/file1.txt"
        echo "file2" > "$tmpdir/source/file2.txt"
        echo "file3" > "$tmpdir/source/file3.txt"

        echo "  1. 全量备份:"
        tar czf "$tmpdir/backup/full.tar.gz" -C "$tmpdir/source" .
        local snapshot
        snapshot=$(mktemp)
        find "$tmpdir/source" -type f -exec md5sum {} \; | sort > "$snapshot"
        echo "    $(ls "$tmpdir/backup/full.tar.gz") ($(du -h "$tmpdir/backup/full.tar.gz" | cut -f1))"

        # 修改文件
        echo "file1 modified" > "$tmpdir/source/file1.txt"
        echo "file4 new" > "$tmpdir/source/file4.txt"

        echo ""
        echo "  2. 差异备份（只备份变化的文件）:"
        local changes
        changes=$(mktemp)
        find "$tmpdir/source" -type f -exec md5sum {} \; | sort > "$changes"
        diff --old-line-format='DEL %L' --new-line-format='ADD %L' --unchanged-line-format='' \
            "$snapshot" "$changes" | while read -r action line; do
            local file
            file=$(echo "$line" | awk '{print $2}')
            local rel="${file#$tmpdir/source/}"
            echo "    $action: $rel"
        done

        # 只打包变化的文件
        tar czf "$tmpdir/backup/diff-$(date +%H%M%S).tar.gz" \
            --newer-mtime "$tmpdir/backup/full.tar.gz" -C "$tmpdir/source" . 2>/dev/null
        echo "    差异包: $(ls "$tmpdir/backup"/diff-*.tar.gz | head -1)"

        rm -rf "$tmpdir"
    else
        # TODO: 记录全量快照 (md5sum)，差异时只打包变化文件
        # find source -type f -exec md5sum {} \; > snapshot.txt
        # diff snapshot.txt new_snapshot.txt | ...
        echo "待实现..."
    fi
}

# ============================================================================
# 练习 3：备份通知
# notify 函数支持 log/mail/notify-send/logger
# ============================================================================
exercise_3() {
    echo -e "\n${YELLOW}━━━ 练习 3：备份通知 ━━━${NC}"

    if [[ "$MODE" == "answers" ]]; then
        echo -e "${GREEN}[参考答案]${NC}"
        # 通知函数
        notify() {
            local level="$1" message="$2"
            local ts
            ts=$(date '+%Y-%m-%d %H:%M:%S')
            local log_line="[$ts] [$level] $message"

            # 1. 写日志
            echo "$log_line" >> /tmp/backup_notify.log
            echo "  📝 日志: $log_line"

            # 2. 系统日志
            if command -v logger &>/dev/null; then
                logger -t backup -p "user.$(echo "$level" | tr 'A-Z' 'a-z')" "$message" 2>/dev/null
                echo "  📋 logger: 已写入系统日志"
            fi

            # 3. 桌面通知
            if command -v notify-send &>/dev/null; then
                notify-send "备份通知" "$message" 2>/dev/null
                echo "  🔔 notify-send: 已发送桌面通知"
            fi

            # 4. 邮件（仅在配置了的情况下）
            if command -v mail &>/dev/null && [[ -n "${NOTIFY_EMAIL:-}" ]]; then
                echo "$message" | mail -s "备份通知 [$level]" "$NOTIFY_EMAIL"
                echo "  📧 邮件: 已发送到 $NOTIFY_EMAIL"
            else
                echo "  📧 邮件: 未配置 (跳过)"
            fi
        }

        notify "INFO" "备份开始: ~/documents"
        notify "SUCCESS" "备份完成: 156 个文件, 2.3GB"
        notify "ERROR" "备份失败: 磁盘空间不足"
    else
        # TODO: 实现 notify 函数
        # notify() { local level="$1" msg="$2"; echo "[$(date)] [$level] $msg" >> backup.log; }
        echo "待实现..."
    fi
}

# ============================================================================
# 练习 4：备份验证
# SHA256 校验和 + tar -tf 验证
# ============================================================================
exercise_4() {
    echo -e "\n${YELLOW}━━━ 练习 4：备份验证 ━━━${NC}"

    if [[ "$MODE" == "answers" ]]; then
        echo -e "${GREEN}[参考答案]${NC}"
        local tmpdir
        tmpdir=$(mktemp -d)
        mkdir -p "$tmpdir/source"
        echo "important data" > "$tmpdir/source/data.txt"
        echo "config" > "$tmpdir/source/config.cfg"

        # 创建备份
        local backup="$tmpdir/backup.tar.gz"
        tar czf "$backup" -C "$tmpdir/source" .

        # 验证函数
        verify_backup() {
            local archive="$1"

            echo "  1. SHA256 校验:"
            local hash
            hash=$(sha256sum "$archive" | cut -d' ' -f1)
            echo "    $hash"
            echo "    ${archive##*/}"

            echo ""
            echo "  2. tar -tf 列出内容:"
            tar tzf "$archive" | while IFS= read -r f; do
                echo "    ✓ $f"
            done

            echo ""
            echo "  3. 完整性测试 (tar -tzf):"
            if tar tzf "$archive" > /dev/null 2>&1; then
                echo -e "    ${GREEN}✓ 归档完整${NC}"
            else
                echo -e "    ${RED}✗ 归档损坏${NC}"
            fi

            echo ""
            echo "  4. 解压测试:"
            local test_dir
            test_dir=$(mktemp -d)
            tar xzf "$archive" -C "$test_dir"
            local src_count dst_count
            src_count=$(find "$tmpdir/source" -type f | wc -l)
            dst_count=$(find "$test_dir" -type f | wc -l)
            if ((src_count == dst_count)); then
                echo -e "    ${GREEN}✓ 文件数一致: $src_count${NC}"
            else
                echo -e "    ${RED}✗ 文件数不一致: 源=$src_count 解压=$dst_count${NC}"
            fi
            rm -rf "$test_dir"
        }

        verify_backup "$backup"
        rm -rf "$tmpdir"
    else
        # TODO: sha256sum + tar -tf 验证
        # hash=$(sha256sum backup.tar.gz | cut -d' ' -f1)
        # tar tzf backup.tar.gz > /dev/null && echo "完整" || echo "损坏"
        echo "待实现..."
    fi
}

# ============================================================================
# 练习 5：并行多目录备份
# 后台进程并行备份，wait 收集结果，flock 保护日志
# ============================================================================
exercise_5() {
    echo -e "\n${YELLOW}━━━ 练习 5：并行多目录备份 ━━━${NC}"

    if [[ "$MODE" == "answers" ]]; then
        echo -e "${GREEN}[参考答案]${NC}"
        local tmpdir
        tmpdir=$(mktemp -d)
        mkdir -p "$tmpdir"/{src1,src2,src3,backup}
        for i in 1 2 3; do echo "data $i" > "$tmpdir/src$i/file.txt"; done

        local logfile="$tmpdir/backup.log"
        local pids=()

        # 并行备份函数
        backup_one() {
            local src="$1" dest="$2" log="$3"
            local name
            name=$(basename "$src")
            local archive="$dest/${name}.tar.gz"

            tar czf "$archive" -C "$src" . 2>/dev/null
            local status=$?
            local size
            size=$(du -h "$archive" 2>/dev/null | cut -f1)

            # flock 保护日志写入
            (
                flock -n 9 || exit 1
                if ((status == 0)); then
                    echo "[$(date +%H:%M:%S)] ✓ $name → $size" >> "$log"
                else
                    echo "[$(date +%H:%M:%S)] ✗ $name 失败" >> "$log"
                fi
            ) 9>>"$log"
        }

        echo "  启动并行备份..."
        for dir in "$tmpdir"/src*; do
            backup_one "$dir" "$tmpdir/backup" "$logfile" &
            pids+=($!)
        done

        # 等待所有完成
        for pid in "${pids[@]}"; do
            wait "$pid"
        done

        echo ""
        echo "  日志:"
        cat "$logfile" | sed 's/^/    /'
        echo ""
        echo "  备份文件:"
        ls -lh "$tmpdir/backup/" | tail -n +2 | awk '{print "    " $NF " (" $5 ")"}'

        rm -rf "$tmpdir"
    else
        # TODO: 后台并行 + wait + flock
        # for dir in "$dirs"; do
        #     backup_one "$dir" "$dest" "$log" &
        #     pids+=($!)
        # done
        # for pid in "${pids[@]}"; do wait "$pid"; done
        echo "待实现..."
    fi
}

# ============================================================================
# 主菜单
# ============================================================================
if [[ "$MODE" == "answers" ]]; then
    echo -e "${CYAN}${BOLD}项目 05 参考答案 — 备份工具${NC}"
    exercise_1; exercise_2; exercise_3; exercise_4; exercise_5
    echo -e "\n${GREEN}全部完成！${NC}"
    exit 0
fi

echo -e "${CYAN}${BOLD}项目 05 练习题 — 备份工具${NC}"
echo ""
echo "选择练习 (1-5):"
echo "  提示: bash exercises.sh --answers 查看所有参考答案"
read -rp "编号: " choice
case "$choice" in
    1) exercise_1 ;; 2) exercise_2 ;; 3) exercise_3 ;;
    4) exercise_4 ;; 5) exercise_5 ;;
    *) echo "无效选择"; exit 1 ;;
esac
