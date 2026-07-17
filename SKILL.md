---
name: mac_cleaner
description: 针对 macOS 系统的磁盘存储空间智能诊断、分析及安全清理技能。当用户遇到 Mac 硬盘空间不足、系统缓存膨胀、需要排查“macOS（系统空间/系统数据）占用过大”、或者想要清理开发者工具临时文件（如 Xcode DerivedData, Homebrew, Docker, npm/pnpm 缓存等）时自动触发本技能。
---

# macOS 智能存储扫描与安全清理技能 (Mac Cleaner Skill)

本技能由 Antigravity 智能体与开发者共同构建，旨在提供安全、精准、高效的 macOS 系统空间排查与深度清理解决方案。

## 🎯 技能触发场景
当用户提出以下需求或遇到以下问题时，智能体需遵循本指导说明执行：
1. **硬盘容量告急**：提示 Mac 存储空间不足或系统变卡。
2. **“macOS / 系统数据”占用异常庞大**：在系统设置中发现“macOS”选项或“系统数据”占用了几十 GB 甚至上百 GB，不知道具体原因和清理办法。
3. **开发者工具缓存膨胀**：希望针对性清理开发相关的历史构建包（如 Xcode、Homebrew、Node.js/npm、Docker 等）。
4. **一键智能清理工具需求**：希望运行或调用内附的交互式清理工具。

---

## 🧭 核心排查流程与排查手册

### 步骤一：只读安全扫描 (Disk & Cache Diagnosis)
在对系统做出任何修改之前，应当**优先执行只读扫描**，向用户报告准确的数据分布状态：
```bash
# 1. 检查硬盘总体空间占比与剩余可用量
df -h /

# 2. 检查用户临时缓存总量及前 10 大应用占用
du -sh ~/Library/Caches 2>/dev/null && cd ~/Library/Caches && du -sm * 2>/dev/null | sort -nr | head -n 10 | awk '{print $1 " MB\t" $2}'

# 3. 排查用户主目录下的大文件夹
cd ~ && du -sm Library/Developer Library/Containers Library/Application\ Support Downloads Documents Desktop .Trash .npm .cache 2>/dev/null | sort -nr | awk '{print $1 " MB\t" $2}'
```

---

### 步骤二：“macOS / 系统空间”高达数十 GB 的深度排查法则
苹果《系统设置 -> 存储空间》中的“macOS（系统数据）”统计逻辑为：**总占用 - (常规 App 本体 + 普通文稿 + 媒体文件 + iCloud)**。因此，深层配置库、沙盒数据和本地快照都会被归入此项。
如遇到 `macOS 选项占用空间巨大` 的问题，必须逐一排查以下 5 大元凶：

#### 1. Time Machine 本地 APFS 快照 (Local Snapshots)
* **诊断命令**：`tmutil listlocalsnapshots /`
* **处理方案**：如果存在多条快照且占用极高，运行以下命令释放：
  ```bash
  sudo tmutil thinlocalsnapshots / 99000000000 4
  ```

#### 2. 沙盒应用巨无霸 (`~/Library/Containers`)
* **诊断目标**：例如微信 (`com.tencent.xinWeChat`)、企业微信 (`com.tencent.WeWorkMac`)、钉钉等。这些聊天数据存储在底层沙盒，被苹果算在“macOS”项下。
* **处理原则**：**禁止强行通过 `rm -rf` 命令行删除**（易损坏聊天记录！）。应指引用户打开聊天软件客户端 -> 【设置 -> 存储空间】中进行应用内安全精简。

#### 3. macOS 动态屏保与系统下载资源 (`/System/Library/AssetsV2`)
* **诊断目标**：后台自动下载的高清航拍屏保 (`Aerials 4K`)、高清 Siri 离线语音包、iOS 固件支持等。
* **处理方案**：指引用户前往 ` 系统设置 -> 墙纸/屏幕保护程序`，取消多个高清动态航拍视频下载并移除缓存，或精简 `com.apple.wallpaper`。

#### 4. macOS 底层临时沙盒堆积 (`/private/var/folders/`) & 交换内存 (`/private/var/vm/`)
* **处理方案**：**强烈建议用户彻底关机 (Shut Down) 并重新开机**。每次开机内核会自动刷写重置 `/private/var/folders/` 和 `swapfile` 虚拟内存，能直接释放 5~15 GB 系统空间。

#### 5. 应用程序全局持久库 (`~/Library/Application Support`)
* **诊断目标**：Chrome (`Google`)、JetBrains IDE 历史版本备份、飞书 (`LarkShell`) 等。

---

### 步骤三：调用交互式一键清理工具 `scripts/mac_cleaner.sh`

本技能包中自带了经过生产级验证的脚本工具 `scripts/mac_cleaner.sh`。当需要自动完成缓存清理并给予用户交互选择时，可以直接触发执行该脚本：

```bash
# 执行技能包内的交互式清理脚本
zsh <path_to_skill>/scripts/mac_cleaner.sh
```

**脚本覆盖清理的目标矩阵**：
- `[1]` 用户应用临时缓存 (`~/Library/Caches/*`)
- `[2]` npm 全局缓存及 `.cache` 前端开发临时包 (`npm cache clean --force` / `~/.npm/_cacache`)
- `[3]` Xcode 编译派生缓存 (`DerivedData`)
- `[4]` Homebrew 历史下载包与冗余依赖 (`brew cleanup --prune=all`)
- `[5]` `~/Downloads` 目录下的过时安装镜像 (`*.dmg`, `*.zip`)
- `[6]` 废纸篓清空 (`~/.Trash/*`)
- `[7]` Docker 悬空容器、废弃镜像与数据卷 (`docker system prune -a --volumes -f`)
- `[8]` Time Machine 本地 APFS 快照精简

---

## 🛡️ 安全承诺与设计原则
1. **绝不越权**：执行涉及文件删除的脚本操作前，必须向用户阐明具体清除的目标与预计释放大小，或通过交互菜单让用户自行决定。
2. **保护工作数据**：严禁直接从命令行强制递归删除用户可能保存文档的沙盒目录或未知的 `data_transfer` 中转数据。
3. **及时对比反馈**：在任何清理动作执行完毕后，立即运行 `df -h /` 打印最新剩余硬盘空间，增强可感知度。
