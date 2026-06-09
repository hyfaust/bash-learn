# Bash Learn — From Zero to Hero

[English](README.md) | [简体中文](README_zh.md)

---

[![License: GPL v3](https://img.shields.io/badge/License-GPLv3-blue.svg)](LICENSE)

> A progressive, project-based Bash tutorial for beginners. Six hands-on projects with detailed documentation, runnable examples, interactive exercises with reference answers, and a web-based reading interface.

## Table of Contents

- [Introduction](#introduction)
- [Projects](#projects)
- [Quick Start](#quick-start)
- [Project Structure](#project-structure)
- [Web Interface](#web-interface)
- [Exercises](#exercises)
- [Contributing](#contributing)
- [License](#license)

## Introduction

**Bash Learn** is a structured learning path that teaches Bash scripting through six progressively challenging projects. Each project is self-contained in its own directory with:

- A **detailed README** explaining key concepts, data structures, and syntax
- **Runnable example scripts** (basic + advanced) demonstrating real-world patterns
- **Interactive exercises** with a `--answers` flag to reveal runnable reference solutions

The curriculum covers everything from `echo "Hello World"` to building a full system monitoring dashboard — all in pure Bash with no external dependencies.

## Projects

| # | Project | Difficulty | Key Concepts |
|---|---------|------------|--------------|
| 1 | [Hello Bash](01-hello-bash/) | ⭐ | Variables, strings, `echo`/`printf`, `read`, arithmetic |
| 2 | [Guessing Game](02-guessing-game/) | ⭐⭐ | `if`/`else`, comparison operators, `while` loops, `case`, `$RANDOM` |
| 3 | [File Organizer](03-file-organizer/) | ⭐⭐⭐ | `find`, file tests, associative arrays, `mv`/`cp`, path manipulation |
| 4 | [Log Analyzer](04-log-analyzer/) | ⭐⭐⭐⭐ | `grep`, `awk`, `sed`, pipelines, `sort`/`uniq`/`wc` |
| 5 | [Backup Tool](05-backup-tool/) | ⭐⭐⭐⭐⭐ | Functions, `getopts`, `trap`, `tar`, configuration files |
| 6 | [System Monitor](06-system-monitor/) | ⭐⭐⭐⭐⭐⭐ | `/proc` filesystem, `tput`, background processes, `bc` |

## Quick Start

No installation required — just Bash (version 4.0+).

```bash
# Clone or download the project
cd bash_learn

# Start with Project 1
cd 01-hello-bash
bash hello.sh

# Run the exercises
bash exercises.sh

# View reference answers
bash exercises.sh --answers
```

## Project Structure

```
bash_learn/
├── 01-hello-bash/          # Project 1: Variables & Output
│   ├── README.md           # Detailed documentation
│   ├── hello.sh            # Basic example
│   ├── greeting_card.sh    # Advanced example
│   └── exercises.sh        # Practice exercises
├── 02-guessing-game/       # Project 2: Conditionals & Loops
│   ├── README.md
│   ├── game.sh             # Basic game
│   ├── game_advanced.sh    # Enhanced version
│   └── exercises.sh
├── 03-file-organizer/      # Project 3: File Operations
│   ├── README.md
│   ├── organizer.sh        # Basic organizer
│   ├── organizer_advanced.sh
│   ├── test_setup.sh       # Test data generator
│   └── exercises.sh
├── 04-log-analyzer/        # Project 4: Text Processing
│   ├── README.md
│   ├── generate_logs.sh    # Sample log generator
│   ├── analyzer.sh         # Basic analyzer
│   ├── analyzer_advanced.sh
│   └── exercises.sh
├── 05-backup-tool/         # Project 5: Functions & Signals
│   ├── README.md
│   ├── lib.sh              # Shared library
│   ├── backup.sh           # Basic backup
│   ├── backup_advanced.sh  # Incremental backup
│   ├── backup.conf         # Configuration file
│   └── exercises.sh
├── 06-system-monitor/      # Project 6: System Programming
│   ├── README.md
│   ├── monitor.sh          # Basic monitor
│   ├── monitor_advanced.sh # Full dashboard
│   ├── mini_tools.sh       # Standalone tools
│   └── exercises.sh
├── index.html              # Web-based reading interface
├── content.js              # Pre-built content for web UI
├── build_content.sh        # Regenerate content.js from READMEs
└── LICENSE
```

## Web Interface

The project includes a static web interface for a better reading experience:

```bash
# Start a local server
python3 -m http.server 8080

# Open in browser
# http://localhost:8080
```

Features:
- **Sidebar navigation** — quick access to all 6 projects
- **Full-text search** — find topics across all chapters
- **Syntax highlighting** — powered by highlight.js
- **Dark/Light theme** — toggle with one click
- **Reading progress** — tracks completed chapters in localStorage
- **Mobile responsive** — works on phones and tablets

## Exercises

Every project includes 5 practice exercises. Each exercise provides a task description with TODO hints, and a runnable reference answer.

```bash
# Interactive mode — see task descriptions
bash exercises.sh

# Answer mode — run all reference solutions
bash exercises.sh --answers
```

Exercises cover:

| Project | Exercise Topics |
|---------|----------------|
| 01 | Customizable greeting, colored output, menu system, calculator, name card |
| 02 | Smart hints, multiplayer mode, custom ranges, AI binary search, leaderboard |
| 03 | Undo by log, config file parsing, cron scheduling, statistics report, recursive scan |
| 04 | `grep` counting, `awk` extraction, `sed` replacement, pipeline composition, browser stats |
| 05 | Config parsing, differential backup, notification system, backup verification, parallel backup |
| 06 | Process tree, CPU chart, network monitor, alert system, HTML report |

## Contributing

Contributions are welcome! Here's how you can help:

1. **Report issues** — Found a bug or unclear explanation? Open an issue.
2. **Improve docs** — Better explanations, fix typos, add examples.
3. **Add exercises** — More practice problems for each project.
4. **Translations** — Help translate documentation to other languages.

## License

This project is licensed under the [GNU General Public License v3.0](LICENSE).
