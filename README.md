# 🍏 Mac Cleaner Skill for Antigravity & AI Agents

[![Platform](https://img.shields.io/badge/Platform-macOS%2012%2B-000000.svg?style=flat-square&logo=apple)](https://www.apple.com/macos)
[![License](https://img.shields.io/badge/License-MIT-blue.svg?style=flat-square)](LICENSE)
[![Skill Type](https://img.shields.io/badge/Antigravity-Agent%20Skill-00BCD4.svg?style=flat-square)](https://github.com/google/antigravity)

**Mac Cleaner Skill** 是专为 **Google Antigravity、Claude Code 及现代 AI 智能体** 打造的系统级存储诊断、根因排查与定向安全清理专家技能包。

彻底摒弃传统“独立桌面应用（.app / .command）”的冗余设计，将专业系统维护经验转化为**智能体可理解的心智模型、只读诊断协议与颗粒化选项清理标准**。

---

## 🎯 核心功能与特色

1. **秒级非破坏性只读诊断 (`scripts/diagnose.sh`)**  
   - 2 秒内全面扫描全盘容量、APFS 快照、各大用户目录及 Top 占用项，100% 只读、不产生任何修改。

2. **多维度颗粒化选项清理 (`scripts/clean.sh`)**  
   - 支持根据用户指定选项按需清理（如应用缓存、单个指定应用、开发缓存、下载安装包、废纸篓等）；
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
| `--dev` | npm + gradle + xcode + brew | **一键清理所有开发工具与依赖构建缓存** |
| `--npm` | `~/.npm/_cacache` | 清理 npm 全局包缓存 |
| `--xcode` | Xcode `DerivedData` | 清理 Xcode 编译派生缓存文件 |
| `--gradle` | `~/.gradle/caches` | 清理 Gradle 依赖与构建中间产物 |
| `--homebrew`, `--brew` | `brew cleanup --prune=all` | 清理 Homebrew 历史下载包与过期版本 |
| `--downloads-pkg`, `--pkg` | `~/Downloads/*.dmg, *.pkg` | 清理下载文件夹中的历史安装镜像 |
| `--trash` | `~/.Trash/*` | 清空废纸篓 |
| `--docker` | `docker system prune -f` | 清理 Docker 悬空未使用的容器与镜像（保留 Volumes） |
| `--logs` | `~/Library/Logs/*` | 清理用户应用诊断日志 |
| `--all-safe` | caches + dev + brew + pkg | **安全全选**（一键清理所有低风险常规垃圾） |

### 控制参数：
- `--dry-run`, `-n`：**试运行模式**，仅统计预估将释放的空间，不执行任何实际删除。
- `--yes`, `-y`：**非交互模式**，跳过终端二次确认，专供 AI Agent 获准后自动化执行。

---

## 💡 使用范例

### 1. 配合 AI 助手使用（自然语言交互）
当技能安装至 `~/.gemini/config/skills/mac_cleaner` 后，您只需直接对话：
- *“帮我诊断一下现在的 Mac 硬盘空间”* ➡️ Agent 自动调用 `diagnose.sh` 并生成报表。
- *“帮我清理一下开发依赖和下载目录里的安装包”* ➡️ Agent 自动匹配 `--dev --pkg -y` 执行。
- *“如果把微信和浏览器的缓存删了能腾出多少地方？”* ➡️ Agent 自动调用 `--dry-run` 给出预估。

### 2. 在终端中手动调用
```bash
# 1. 运行系统空间只读诊断
zsh scripts/diagnose.sh

# 2. 试运行预估：查看如果清理缓存和安装包能腾出多大空间
zsh scripts/clean.sh --caches --pkg --dry-run

# 3. 定向清理开发依赖与下载镜像
zsh scripts/clean.sh --dev --pkg

# 4. 仅清理 Google Chrome 的缓存
zsh scripts/clean.sh --cache-dir Google
```

---

## 📄 License
MIT License © [snowlu16](https://github.com/snowlu16)
