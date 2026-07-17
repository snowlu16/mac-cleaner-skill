# 🍏 Mac Cleaner Skill for Antigravity

[![Platform](https://img.shields.io/badge/Platform-macOS%2012%2B-000000.svg?style=flat-square&logo=apple)](https://www.apple.com/macos)
[![License](https://img.shields.io/badge/License-MIT-blue.svg?style=flat-square)](LICENSE)
[![Skill Type](https://img.shields.io/badge/Antigravity-Agent%20Skill-00BCD4.svg?style=flat-square)](https://github.com/google/antigravity)

**Mac Cleaner Skill** 是专为 macOS 系统打造的开源智能存储扫描、诊断与交互式安全清理技能包。既可作为 **Google Antigravity / AI 智能体** 的即插即用技能 (`SKILL.md`)，也可由普通开发者在终端中独立作为实用脚本运行 (`mac_cleaner.sh`)。

---

## ✨ 核心特性 & 解决痛点

1. **破译“macOS / 系统数据”膨胀之谜**  
   针对系统设置中常见“macOS 选项占用 60GB~100GB+”的难题，本技能总结了 **5 大深度排查法则**（Time Machine 本地 APFS 快照、沙盒聊天软件缓存、系统屏保下载库 `AssetsV2`、`/private/var/folders` 及虚拟内存交换），并指引智能体进行安全清理。

2. **8 大常规垃圾源一键扫描**  
   - 用户应用临时缓存 (`~/Library/Caches`)
   - Node.js 与前端开发包缓存 (`~/.npm`, `~/.cache`)
   - Xcode 派生构建数据 (`DerivedData`)
   - Homebrew 历史下载与依赖 (`brew cleanup`)
   - 过期下载镜像与安装包 (`*.dmg`, `*.zip`)
   - 废纸篓清空 (`~/.Trash`)
   - Docker 悬空容器、镜像与数据卷 (`docker system prune`)
   - Time Machine 本地快照瘦身

3. **安全防呆交互机制**  
   - 支持数字编号多选（如 `1 2 5`）或 `all` 全选；
   - **绝对不强删重要沙盒或文稿中转数据**，针对巨无霸文件夹（如微信 `xinWeChat` 沙盒、个人大容量数据传输目录）给予明确的官方客户端内部清理建议；
   - 强行需要二次输入 `y` 确认才动刀，清理完后即时反馈新增剩余空间。

---

## 🛠️ 安装与使用方法

### 方式 A：作为 AI 智能体技能 (Antigravity Skill 使用)
将本仓库克隆或软连接至您的 Antigravity 技能配置目录：
```bash
git clone git@github.com:snowlu16/mac-cleaner-skill.git ~/.gemini/config/skills/mac_cleaner
```
当您对 AI 助手说：*“帮我清理 Mac 缓存”、“分析一下为什么 macOS 系统数据占了七八十个 G”* 时，智能体即可自动加载本技能的手册和工具为您排查！

### 方式 B：作为独立终端脚本直接执行
可以直接运行 `scripts/mac_cleaner.sh`：
```bash
# 赋予可执行权限并运行
chmod +x scripts/mac_cleaner.sh
./scripts/mac_cleaner.sh
```

您还可以将其设置为系统全局便捷指令：
```bash
cp scripts/mac_cleaner.sh ~/mac_cleaner.sh && chmod +x ~/mac_cleaner.sh
# 之后随时在终端键入 ~/mac_cleaner.sh 即可开启智能诊断！
```

---

## 📋 诊断对比范例

```text
================================================================================
               🍏 macOS 智能存储扫描与交互式清理工具 (Mac Cleaner)               
================================================================================

💾 系统硬盘空间：总容量 460Gi | 已用 12Gi (29%) | 当前可用 29Gi

🔍 正在深度扫描可安全清理的数据项，请稍候...
--------------------------------------------------------------------------------
可以进行安全清理的项目表：
  [1] 用户临时应用缓存 (~/Library/Caches/*)         66M
  [2] 前端与开发构建缓存 (~/.npm, ~/.cache)         2.1G (合计)
  [3] Xcode 编译临时派生数据 (DerivedData)          0B
  [4] Homebrew 下载缓存与历史包                     0B
  [5] 下载文件夹中的安装包 (*.dmg, *.zip)           0B
  [6] 废纸篓全部内容 (~/.Trash/*)                   0B
  [7] Docker 废弃镜像/容器与数据卷                  未运行 Docker 或未安装，已跳过
  [8] Time Machine 本地快照                         0 个快照
--------------------------------------------------------------------------------
📌 巨无霸文件夹特别提醒 (需要手动确认或应用内清理)：
  • ~/Documents/data_transfer (占用 84G) -> 如确认是已完成同步的数据备份，请手动删除！
  • 微信聊天沙盒 (`xinWeChat`) (占用 23G) -> 强力建议打开微信客户端【设置 -> 存储空间】中一键清理视频和原图！
--------------------------------------------------------------------------------
```

---

## 📝 License
MIT License. Created by [snowlu16](https://github.com/snowlu16) & Antigravity.
