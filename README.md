# 🍏 Mac Cleaner Skill for Antigravity & AI Agents

[![Platform](https://img.shields.io/badge/Platform-macOS%2012%2B-000000.svg?style=flat-square&logo=apple)](https://www.apple.com/macos)
[![License](https://img.shields.io/badge/License-MIT-blue.svg?style=flat-square)](LICENSE)
[![Skill Type](https://img.shields.io/badge/Antigravity-Agent%20Skill-00BCD4.svg?style=flat-square)](https://github.com/google/antigravity)

**Mac Cleaner Skill** 是专为 **Google Antigravity、Claude Code 及现代 AI 智能体** 打造的系统级存储诊断、根因排查与定向安全清理专家技能包。

彻底摒弃传统“独立桌面应用（.app / .command）”的冗余设计，将专业系统维护经验转化为**智能体可理解的心智模型、只读诊断协议与颗粒化选项清理标准**。

---

## 🎯 核心功能与特色

1. **秒级非破坏性只读诊断 (`scripts/diagnose.sh`)**  
   - 2 秒内全面扫描全盘容量、APFS 快照、各大用户目录、隐藏开发目录（`~/.cache`, `~/.m2`, `~/.android` 等）及 Top 占用项，100% 只读、不产生任何修改。

2. **多维度颗粒化选项清理 (`scripts/clean.sh`)**  
   - 支持根据用户指定选项按需清理（如应用缓存、XDG 缓存、WebKit 缓存、单个指定应用、开发缓存、Maven、Parallels 安装镜像、AI 编程助手日志缓存、下载安装包、废纸篓等）；
   - 支持多选项自由组合（例如同时清理缓存和安装包：`--caches --pkg`）；
   - 支持 `--dry-run` 空间预估模式；
   - 支持 `-y` / `--yes` 自动化非交互执行，供 AI 智能体获得授权后无缝调用。

3. **零误删安全红线 (Zero Data Loss)**  
   - 绝不通过命令行强删聊天软件（微信、企业微信、飞书等）沙盒，指导用户应用内清理，保护本地数据库；
   - 绝不触碰系统保护区（`/System`、`/Library`、`/private/var`）；
   - 区分系统更新快照与 Time Machine 本地快照，避免误删。

---

## 📂 项目结构

```text
mac-cleaner-skill/
├── SKILL.md                 # 核心：AI 智能体专属的存储诊断、安全矩阵与选项清理规范
├── README.md                # 技能说明与使用文档
├── .gitignore
└── scripts/
    ├── diagnose.sh          # 辅助工具：非破坏性、秒级系统空间只读诊断脚本
    └── clean.sh             # 核心工具：支持指定选项、试运行与自动化的定向清理脚本
```

---

## 🛠️ 定向清理选项清单 (`scripts/clean.sh`)

| 命令行选项 | 对应目标 | 说明 |
| :--- | :--- | :--- |
| `--caches`, `-c` | `~/Library/Caches/*` | 清理所有用户应用临时缓存 |
| `--cache-dir <name>` | `~/Library/Caches/<name>` | **精准指定单一应用缓存**（如 `Google`, `JetBrains`） |
| `--xdg-cache` | `~/.cache/*` | 清理 XDG 通用工具与运行时缓存（如 `uv`, `codex-runtimes`） |
| `--webkit` | `~/Library/WebKit/*` | 清理 WebKit 网页内核缓存 |
| `--dev` | npm, yarn, pnpm, pod, pip, go, cargo, gradle, xcode, brew, agent-caches | **一键清理所有主流开发工具与依赖构建缓存** |
| `--npm` / `--yarn` / `--pnpm` | `~/.npm/_cacache`, `Yarn`, `.pnpm-store` | 清理前端包管理器全局缓存 |
| `--pip` / `--go` / `--cargo` | `pip`, `go-build`, `.cargo/registry` | 清理 Python / Go / Rust 缓存 |
| `--cocoapods`, `--pod` | `~/Library/Caches/CocoaPods` | 清理 CocoaPods 缓存 |
| `--xcode` / `--xcode-sim` / `--xcode-archives` | `DerivedData`, `xcrun simctl`, `Archives` | 清理 Xcode 编译派生数据、无效模拟器与历史归档 |
| `--gradle` | `~/.gradle/caches` | 清理 Gradle 依赖与构建中间产物 |
| `--maven`, `--m2` | `~/.m2/repository/*` | 清理 Maven 本地依赖仓库缓存 |
| `--agent-caches` | `~/.codex/cache`, `~/.workbuddy/logs,traces,cache` | 清理 AI 编程助手运行缓存与追踪日志 |
| `--homebrew`, `--brew` | `brew cleanup --prune=all` | 清理 Homebrew 历史下载包与过期版本 |
| `--downloads-pkg`, `--pkg` | `~/Downloads/*.dmg, *.pkg, *.iso` | 清理下载文件夹中的历史安装镜像 |
| `--parallels-pkg` | `~/Library/Parallels/Downloads/*` | 清理 Parallels Desktop 下载的系统安装镜像 ISO |
| `--ios` | `MobileSync/Backup`, `iPhone Software Updates` | 清理 iOS 设备备份与系统固件更新缓存 |
| `--trash` | `~/.Trash/*` | 清空废纸篓 |
| `--docker` | `docker system prune -f` | 清理 Docker 悬空未使用的容器与镜像（保留 Volumes） |
| `--logs` | `~/Library/Logs/*` | 清理用户应用诊断日志 |
| `--all-safe` | caches + xdg-cache + webkit + dev + brew + pkg + parallels-pkg + ios + logs | **安全全选**（一键清理所有低风险常规垃圾） |

### 控制参数：
- `--dry-run`, `-n`：**试运行模式**，仅统计预估将释放的空间，不执行任何实际删除。
- `--yes`, `-y`：**非交互模式**，跳过终端二次确认，专供 AI Agent 获准后自动化执行。

---

## 💡 使用范例

### 1. 配合 AI 助手使用（自然语言交互）
当技能安装至 `~/.gemini/config/skills/mac_cleaner` 后，您只需直接对话：
- *“帮我诊断一下现在的 Mac 硬盘空间”* ➡️ Agent 自动调用 `diagnose.sh` 并生成报表。
- *“查看当前可清除的文件有哪些”* ➡️ Agent 自动调用 `clean.sh --all-safe --maven --dry-run` 给出完整预估清单。
- *“帮我清理一下开发依赖、Parallels 安装镜像和日志”* ➡️ Agent 自动匹配 `--dev --parallels-pkg --logs -y` 执行。

### 2. 在终端中手动调用
```bash
# 1. 运行系统空间只读深度诊断
zsh scripts/diagnose.sh --deep

# 2. 试运行预估：查看所有当前可清除的文件能腾出多大空间
zsh scripts/clean.sh --all-safe --maven --dry-run

# 3. 定向清理全部常规安全项
zsh scripts/clean.sh --all-safe -y

# 4. 仅清理 Google Chrome 的缓存
zsh scripts/clean.sh --cache-dir Google
```

---

## 📄 License
MIT License © [snowlu16](https://github.com/snowlu16)
