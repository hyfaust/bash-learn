#!/bin/bash
# =============================================================================
# test_setup.sh — 创建测试文件供整理器使用
# =============================================================================

TEST_DIR="${1:-/tmp/test_organizer}"

echo "创建测试目录: ${TEST_DIR}"
mkdir -p "$TEST_DIR"

# 图片文件
touch "$TEST_DIR/photo_001.jpg"
touch "$TEST_DIR/screenshot.png"
touch "$TEST_DIR/logo.svg"
touch "$TEST_DIR/animation.gif"

# 文档文件
touch "$TEST_DIR/report.pdf"
touch "$TEST_DIR/notes.txt"
touch "$TEST_DIR/readme.md"
touch "$TEST_DIR/data.csv"
touch "$TEST_DIR/presentation.pptx"

# 视频文件
touch "$TEST_DIR/clip.mp4"
touch "$TEST_DIR/movie.mkv"

# 音频文件
touch "$TEST_DIR/song.mp3"
touch "$TEST_DIR/recording.wav"

# 压缩包
touch "$TEST_DIR/archive.zip"
touch "$TEST_DIR/backup.tar.gz"

# 代码文件
touch "$TEST_DIR/script.sh"
touch "$TEST_DIR/app.py"
touch "$TEST_DIR/index.html"

# 其他文件
touch "$TEST_DIR/unknown_file.xyz"

echo ""
echo "已创建以下测试文件:"
ls -la "$TEST_DIR"
echo ""
echo "现在可以运行整理器:"
echo "  bash organizer.sh --dry-run ${TEST_DIR}"
echo "  bash organizer.sh ${TEST_DIR}"
