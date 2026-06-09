# Bash 学习教程 — 从零到实战

[English](README.md) | [简体中文](README_zh.md)

---

[![License: GPL v3](https://img.shields.io/badge/License-GPLv3-blue.svg)](LICENSE)

> 一个面向初学者的、循序渐进的项目式 Bash 教程。包含六个实战项目，配有详细文档、可运行示例、带参考答案的交互式练习，以及基于网页的阅读界面。

## 目录

- [简介](#简介)
- [项目列表](#项目列表)
- [快速开始](#快速开始)
- [项目结构](#项目结构)
- [网页界面](#网页界面)
- [练习](#练习)
- [参与贡献](#参与贡献)
- [许可证](#许可证)

## 简介

**Bash Learn** 是一个结构化的学习路径，通过六个难度递增的项目来教授 Bash 脚本编程。每个项目都独立存放在自己的目录中，包含：

- 一份**详细 README**，讲解核心概念、数据结构和语法
- **可运行的示例脚本**（基础 + 进阶），演示真实场景中的常见模式
- **交互式练习**，使用 `--answers` 标志可查看可运行的参考答案

课程内容涵盖从 `echo "Hello World"` 到构建完整的系统监控仪表盘——全部使用纯 Bash 实现，无任何外部依赖。

## 项目列表

| # | 项目 | 难度 | 核心知识点 |
|---|------|------|-----------|
| 1 | [Hello Bash](01-hello-bash/) | ⭐ | 变量、字符串、`echo`/`printf`、`read`、算术运算 |
| 2 | [猜数字游戏](02-guessing-game/) | ⭐⭐ | `if`/`else`、比较运算符、`while` 循环、`case`、`$RANDOM` |
| 3 | [文件整理器](03-file-organizer/) | ⭐⭐⭐ | `find`、文件测试、关联数组、`mv`/`cp`、路径操作 |
| 4 | [日志分析器](04-log-analyzer/) | ⭐⭐⭐⭐ | `grep`、`awk`、`sed`、管道、`sort`/`uniq`/`wc` |
| 5 | [备份工具](05-backup-tool/) | ⭐⭐⭐⭐⭐ | 函数、`getopts`、`trap`、`tar`、配置文件 |
| 6 | [系统监控](06-system-monitor/) | ⭐⭐⭐⭐⭐⭐ | `/proc` 文件系统、`tput`、后台进程、`bc` |

## 快速开始

无需安装任何依赖——只需要 Bash（4.0 及以上版本）。

```bash
# 克隆或下载项目
cd bash_learn

# 从项目 1 开始
cd 01-hello-bash
bash hello.sh

# 运行练习
bash exercises.sh

# 查看参考答案
bash exercises.sh --answers
```

## 项目结构

```
bash_learn/
├── 01-hello-bash/          # 项目 1：变量与输出
│   ├── README.md           # 详细文档
│   ├── hello.sh            # 基础示例
│   ├── greeting_card.sh    # 进阶示例
│   └── exercises.sh        # 练习题
├── 02-guessing-game/       # 项目 2：条件判断与循环
│   ├── README.md
│   ├── game.sh             # 基础游戏
│   ├── game_advanced.sh    # 增强版本
│   └── exercises.sh
├── 03-file-organizer/      # 项目 3：文件操作
│   ├── README.md
│   ├── organizer.sh        # 基础整理器
│   ├── organizer_advanced.sh
│   ├── test_setup.sh       # 测试数据生成器
│   └── exercises.sh
├── 04-log-analyzer/        # 项目 4：文本处理
│   ├── README.md
│   ├── generate_logs.sh    # 示例日志生成器
│   ├── analyzer.sh         # 基础分析器
│   ├── analyzer_advanced.sh
│   └── exercises.sh
├── 05-backup-tool/         # 项目 5：函数与信号
│   ├── README.md
│   ├── lib.sh              # 共享库
│   ├── backup.sh           # 基础备份
│   ├── backup_advanced.sh  # 增量备份
│   ├── backup.conf         # 配置文件
│   └── exercises.sh
├── 06-system-monitor/      # 项目 6：系统编程
│   ├── README.md
│   ├── monitor.sh          # 基础监控
│   ├── monitor_advanced.sh # 完整仪表盘
│   ├── mini_tools.sh       # 独立工具
│   └── exercises.sh
├── index.html              # 基于网页的阅读界面
├── content.js              # 网页 UI 的预构建内容
├── build_content.sh        # 从 README 重新生成 content.js
└── LICENSE
```

## 网页界面

项目包含一个静态网页界面，提供更好的阅读体验：

```bash
# 启动本地服务器
python3 -m http.server 8080

# 在浏览器中打开
# http://localhost:8080
```

功能特性：
- **侧边栏导航** — 快速访问全部 6 个项目
- **全文搜索** — 跨所有章节搜索主题
- **语法高亮** — 由 highlight.js 提供支持
- **深色/浅色主题** — 一键切换
- **阅读进度** — 在 localStorage 中跟踪已完成的章节
- **移动端适配** — 支持手机和平板设备

## 练习

每个项目包含 5 道练习题。每道练习提供任务描述和 TODO 提示，以及可运行的参考答案。

```bash
# 交互模式 — 查看任务描述
bash exercises.sh

# 答案模式 — 运行所有参考答案
bash exercises.sh --answers
```

练习内容概览：

| 项目 | 练习主题 |
|------|---------|
| 01 | 自定义问候语、彩色输出、菜单系统、计算器、名片 |
| 02 | 智能提示、多人模式、自定义范围、AI 二分搜索、排行榜 |
| 03 | 日志撤销、配置文件解析、定时任务调度、统计报告、递归扫描 |
| 04 | `grep` 计数、`awk` 提取、`sed` 替换、管道组合、浏览器统计 |
| 05 | 配置解析、差异备份、通知系统、备份验证、并行备份 |
| 06 | 进程树、CPU 图表、网络监控、告警系统、HTML 报告 |

## 参与贡献

欢迎参与贡献！以下是你可以提供帮助的方式：

1. **报告问题** — 发现了 Bug 或不清晰的说明？请提交 Issue。
2. **改进文档** — 更好的说明、修复错别字、添加示例。
3. **添加练习** — 为每个项目增加更多练习题。
4. **翻译** — 帮助将文档翻译成其他语言。

## 许可证

本项目基于 [GNU 通用公共许可证 v3.0](LICENSE) 开源。
