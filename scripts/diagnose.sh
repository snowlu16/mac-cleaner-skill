#!/usr/bin/env zsh
# ==============================================================================
# macOS 存储空间只读诊断脚本 (macOS Storage Diagnostic Script)
# 纯只读设计：不修改、不删除任何文件，专供 AI 智能体与开发者进行系统空间排查
# ==============================================================================
set -u

# 格式化输出大小辅助函数
size() {
  local target="$1"
  local val=""
  if [[ -e "$target" ]]; then
    val=$(du -sh "$target" 2>/dev/null | awk '{print $1}')
  fi
  [[ -n "$val" ]] && print -- "$val" || print -- "0B"
}

# 检查命令是否存在
has() { command -v "$1" >/dev/null 2>&1; }

# 输出特定目录前 N 项占用
top_subdirs() {
  local target="$1"
  local label="$2"
  local limit="${3:-8}"
  print -- "\n📁 $label (Top $limit):"
  if [[ -d "$target" ]]; then
    (cd "$target" && du -sm * 2>/dev/null | sort -nr | head -n "$limit" | awk '{print "   " $1 " MB\t" $2}') || true
  else
    print -- "   （路径不存在或无权限）"
  fi
}

DEEP_SCAN=0
while (( $# > 0 )); do
  case "$1" in
    --deep|-d) DEEP_SCAN=1; shift ;;
    *) shift ;;
  esac
done

print -- "================================================================================"
print -- "               🍏 macOS 存储空间只读诊断报告 (Storage Diagnosis)                 "
print -- "================================================================================"
print -- ""

# 1. 系统根分区使用情况
print -- "💾 磁盘根卷整体空间 (Root Volume Status):"
df -h / | sed 's/^/   /'
print -- ""

# 2. 关键用户目录概览
print -- "📊 关键个人目录空间分布 (High-Level Overview):"
printf "   %-36s %s\n" "用户临时缓存 (~/Library/Caches)" "$(size "$HOME/Library/Caches")"
printf "   %-36s %s\n" "应用沙盒数据 (~/Library/Containers)" "$(size "$HOME/Library/Containers")"
printf "   %-36s %s\n" "应用持久数据 (~/Library/Application Support)" "$(size "$HOME/Library/Application Support")"
printf "   %-36s %s\n" "开发者目录 (~/Library/Developer)" "$(size "$HOME/Library/Developer")"
printf "   %-36s %s\n" "下载文件夹 (~/Downloads)" "$(size "$HOME/Downloads")"
printf "   %-36s %s\n" "废纸篓内容 (~/.Trash)" "$(size "$HOME/.Trash")"

# 3. 常见可安全回收的开发与构建缓存
print -- "\n🛠️ 常见开发构建与依赖缓存 (Developer Caches):"
printf "   %-36s %s\n" "Xcode DerivedData" "$(size "$HOME/Library/Developer/Xcode/DerivedData")"
printf "   %-36s %s\n" "Xcode iOS DeviceSupport" "$(size "$HOME/Library/Developer/Xcode/iOS DeviceSupport")"
printf "   %-36s %s\n" "npm 全局缓存 (~/.npm/_cacache)" "$(size "$HOME/.npm/_cacache")"
printf "   %-36s %s\n" "Gradle 依赖缓存 (~/.gradle/caches)" "$(size "$HOME/.gradle/caches")"
printf "   %-36s %s\n" "用户级诊断日志 (~/Library/Logs)" "$(size "$HOME/Library/Logs")"
printf "   %-36s %s\n" "Homebrew 下载缓存" "$(size "$HOME/Library/Caches/Homebrew")"

# 4. 下载目录中的安装包检查
PKG_COUNT=$(find "$HOME/Downloads" -maxdepth 1 -type f \( -name "*.dmg" -o -name "*.pkg" -o -name "*.iso" \) 2>/dev/null | wc -l | tr -d ' ')
if [[ "$PKG_COUNT" -gt 0 ]]; then
  PKG_SIZE=$(find "$HOME/Downloads" -maxdepth 1 -type f \( -name "*.dmg" -o -name "*.pkg" -o -name "*.iso" \) -exec du -ch {} + 2>/dev/null | tail -n 1 | awk '{print $1}')
  printf "   %-36s %s (%s 个安装包)\n" "下载文件夹中的安装镜像 (*.dmg/*.pkg)" "$PKG_SIZE" "$PKG_COUNT"
fi

# 5. Docker 资源占用
if has docker && docker info >/dev/null 2>&1; then
  print -- "\n🐳 Docker 运行时资源占用 (Docker System DF):"
  docker system df | sed 's/^/   /'
fi

# 6. APFS 快照情况
print -- "\n📸 APFS 本地快照检查 (Local Snapshots):"
SNAP_LIST=$(tmutil listlocalsnapshots / 2>/dev/null || true)
if [[ -n "$SNAP_LIST" ]]; then
  print -- "$SNAP_LIST" | sed 's/^/   /'
else
  print -- "   （未检测到 Time Machine 本地快照）"
fi

# 7. 各大目录前 N 大子项
top_subdirs "$HOME/Library/Caches" "用户应用缓存最占空间项 (~/Library/Caches)" 8
top_subdirs "$HOME/Library/Containers" "沙盒应用最占空间项 (~/Library/Containers - 请在 App 内清理)" 6
top_subdirs "$HOME/Library/Application Support" "应用支持库最占空间项 (~/Library/Application Support)" 6

# 8. 深度扫描（如果指定了 --deep）
if [[ "$DEEP_SCAN" -eq 1 ]]; then
  print -- "\n🔍 个人主目录各文件夹总占用深度扫描 (Home Top Dirs):"
  (cd "$HOME" && du -sm Library Downloads Documents Desktop Movies Music Pictures .Trash .npm .gradle .cache 2>/dev/null | sort -nr | head -n 10 | awk '{print "   " $1 " MB\t" $2}') || true
fi

print -- "\n================================================================================"
print -- "诊断完成。提示：智能体或管理员应根据此报告在获得用户确认后针对性清理。"
print -- "================================================================================"
