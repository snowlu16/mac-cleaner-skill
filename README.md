# 🍏 Mac Cleaner Skill for Antigravity & AI Agents

[![Platform](https://img.shields.io/badge/Platform-macOS%2012%2B-000000.svg?style=flat-square&logo=apple)](https://www.apple.com/macos)
[![License](https://img.shields.io/badge/License-MIT-blue.svg?style=flat-square)](LICENSE)
[![Skill Type](https://img.shields.io/badge/Antigravity-Agent%20Skill-00BCD4.svg?style=flat-square)](https://github.com/google/antigravity)

**Mac Cleaner Skill** 是专为 **Google Antigravity、Claude Code 及现代 AI 智能体** 打造的系统级存储诊断、根因排查与安全清理技能包。

彻底摒弃传统“独立应用程序（.app / .command / GUI 仪表盘）”的粗暴与冗余设计，将专业系统维护经验转化为**智能体可理解的心智模型、诊断协议与人机协同执行标准**。

---

## 🎯 解决的核心痛点

1. **破译“系统数据 / macOS 占用过大”之谜**  
   苹果设置中的“系统数据”并非实体文件夹，而是动态归纳的剩余空间。本技能总结了 5 大排查法则（APFS 快照、沙盒数据、应用持久配置、底层临时区、系统交换内存），指导智能体进行科学归因。

2. **零误删安全红线 (Zero Data Loss)**  
   - 绝不通过命令行强删聊天软件（微信、企业微信、飞书等）沙盒，避免数据库损坏；
   - 绝不碰系统保护区（`/System`、`/Library`、`/private/var`）；
   - 区分系统更新快照 (`com.apple.os.update-*`) 与 Time Machine 快照，防止误操作。

3. **非交互式、非阻塞的智能体协同流程**  
   - 提供 100% 只读的诊断脚本 `scripts/diagnose.sh`，智能体可在 2 秒内完成全盘空间分布扫描；
   - 智能体在对话中向用户呈现清晰的结构化诊断表格并提供建议；
   - 经用户批准后，智能体直接调用透明、安全的原子级命令完成定向清理，无任何终端交互挂起。

---

## 📂 项目结构

```text
mac-cleaner-skill/
├── SKILL.md                 # 核心：给智能体阅读的系统级专业知识库、诊断协议与安全操作规范
├── README.md                # 技能说明文档
├── .gitignore
└── scripts/
    └── diagnose.sh          # 辅助工具：非破坏性、纯只读的秒级系统空间诊断脚本
```

---

## 🚀 安装与加载

### 作为 Antigravity 全局技能安装
只需克隆或软连接本仓库至您的 Antigravity 技能配置目录：

```bash
git clone git@github.com:snowlu16/mac-cleaner-skill.git ~/.gemini/config/skills/mac_cleaner
```

安装完成后，当您对 AI 助手说：
- *“我的 Mac 提示空间不足，帮我诊断排查一下”*
- *“为什么系统设置里系统数据占了 70 个 G？”*
- *“帮我清理一下开发依赖和应用缓存”*

AI 智能体将自动激活本技能，执行快速只读排查，为您生成清晰的诊断报告并协助您安全清理！

---

## 📝 诊断报告效果范例

```text
================================================================================
               🍏 macOS 存储空间只读诊断报告 (Storage Diagnosis)                 
================================================================================

💾 磁盘根卷整体空间 (Root Volume Status):
   Filesystem        Size    Used   Avail Capacity iused ifree %iused  Mounted on
   /dev/disk3s1s1   460Gi    12Gi   8.8Gi    58%    459k   93M    0%   /

📊 关键个人目录空间分布 (High-Level Overview):
   用户临时缓存 (~/Library/Caches)            9.5G
   应用沙盒数据 (~/Library/Containers)        34G
   应用持久数据 (~/Library/Application Support) 26G
   开发者目录 (~/Library/Developer)          208K
   下载文件夹 (~/Downloads)                  8.9G
   废纸篓内容 (~/.Trash)                     0B

🛠️ 常见开发构建与依赖缓存 (Developer Caches):
   Xcode DerivedData                    0B
   npm 全局缓存 (~/.npm/_cacache)           484M
   用户级诊断日志 (~/Library/Logs)             155M
   下载文件夹中的安装镜像 (*.dmg/*.pkg)            4.2G (7 个安装包)

📁 用户应用缓存最占空间项 (~/Library/Caches) (Top 8):
   3315 MB	com.workbuddy.workbuddy.BundleMigration
   1880 MB	com.tencent.xinWeChat
   1582 MB	Google
   1548 MB	JetBrains
   ...
================================================================================
```

---

## 📄 License
MIT License © [snowlu16](https://github.com/snowlu16)
