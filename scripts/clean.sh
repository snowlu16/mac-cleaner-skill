#!/usr/bin/env zsh
# ==============================================================================
# macOS 定向安全清理脚本 (macOS Targeted Surgical Cleaner)
# 支持指定选项、组合多选、Dry-run 预览与自动化非交互执行 (-y)
# ==============================================================================
set -u

# 定义颜色
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BLUE='\033[0;34m'
BOLD='\033[1m'
NC='\033[0m' # No Color

# 辅助函数：获取文件/文件夹大小
size() {
  local target="$1"
  local val=""
  if [[ -e "$target" ]]; then
    val=$(du -sh "$target" 2>/dev/null | awk '{print $1}')
  fi
  [[ -n "$val" ]] && print -- "$val" || print -- "0B"
}

has() { command -v "$1" >/dev/null 2>&1; }

# 打印帮助手册
usage() {
  cat << EOF
${BOLD}macOS 定向安全清理脚本 (Targeted Surgical Cleaner)${NC}

${CYAN}用法：${NC}
  zsh scripts/clean.sh [选项...]

${CYAN}清理目标选项 (支持组合指定)：${NC}
  --caches, -c            清理所有用户应用临时缓存 (~/Library/Caches/*)
  --cache-dir <name>      仅清理指定应用的缓存目录 (~/Library/Caches/<name>)
  --dev                   一键清理所有开发相关缓存 (npm, yarn, pip, go, cargo, gradle, xcode, brew)
  --npm                   清理 npm 全局缓存 (~/.npm/_cacache)
  --yarn                  清理 yarn 缓存
  --pip                   清理 pip 缓存 (~/Library/Caches/pip)
  --gradle                清理 Gradle 构建依赖缓存 (~/.gradle/caches)
  --xcode                 清理 Xcode 编译派生文件 (DerivedData)
  --go                    清理 Go 语言缓存
  --cargo                 清理 Rust Cargo 缓存
  --homebrew, --brew      清理 Homebrew 过期包与下载缓存 (brew cleanup)
  --docker                清理 Docker 悬空镜像/容器/网络 (保留命名数据卷)
  --ios                   清理 iOS 设备备份与系统固件更新缓存
  --downloads-pkg, --pkg  清理下载目录中的安装包 (*.dmg, *.pkg, *.iso)
  --trash                 清空当前用户废纸篓 (~/.Trash)
  --logs                  清理用户级诊断日志 (~/Library/Logs)
  --all-safe              安全全选 (caches + dev + brew + pkg + ios)

${CYAN}控制选项：${NC}
  --dry-run, -n           试运行模式：仅计算并预览将释放的空间，不执行任何实际删除
  --yes, -y               非交互执行：跳过确认提示 (专供 AI Agent 自动化调用)
  --help, -h              显示本帮助信息

${CYAN}示例：${NC}
  zsh scripts/clean.sh --caches --npm --dry-run      # 预览清理 caches 和 npm 可释放的空间
  zsh scripts/clean.sh --dev --pkg -y                # 自动化清理开发缓存和下载安装包
  zsh scripts/clean.sh --cache-dir Google            # 仅针对 Google Chrome 缓存进行清理
EOF
}

# 标记与变量
DO_CACHES=0
SPECIFIC_CACHE_DIR=""
DO_NPM=0
DO_YARN=0
DO_PIP=0
DO_GRADLE=0
DO_XCODE=0
DO_GO=0
DO_CARGO=0
DO_BREW=0
DO_DOCKER=0
DO_IOS=0
DO_PKG=0
DO_TRASH=0
DO_LOGS=0

DRY_RUN=0
AUTO_YES=0

# 解析参数
if (( $# == 0 )); then
  usage
  exit 0
fi

while (( $# > 0 )); do
  case "$1" in
    --caches|-c|caches) DO_CACHES=1; shift ;;
    --cache-dir)
      if (( $# < 2 )) || [[ "$2" == -* ]]; then
        print -u2 -- "${RED}错误：--cache-dir 需要指定缓存子目录名称 (如 Google, JetBrains)${NC}"
        exit 1
      fi
      SPECIFIC_CACHE_DIR="$2"
      shift 2 ;;
    --dev|dev)
      DO_NPM=1; DO_YARN=1; DO_PIP=1; DO_GRADLE=1; DO_XCODE=1; DO_GO=1; DO_CARGO=1; DO_BREW=1; shift ;;
    --npm|npm) DO_NPM=1; shift ;;
    --yarn|yarn) DO_YARN=1; shift ;;
    --pip|pip) DO_PIP=1; shift ;;
    --gradle|gradle) DO_GRADLE=1; shift ;;
    --xcode|xcode) DO_XCODE=1; shift ;;
    --go|go) DO_GO=1; shift ;;
    --cargo|cargo) DO_CARGO=1; shift ;;
    --homebrew|--brew|brew) DO_BREW=1; shift ;;
    --docker|docker) DO_DOCKER=1; shift ;;
    --ios|ios) DO_IOS=1; shift ;;
    --downloads-pkg|--pkg|pkg) DO_PKG=1; shift ;;
    --trash|trash) DO_TRASH=1; shift ;;
    --logs|logs) DO_LOGS=1; shift ;;
    --all-safe|all-safe)
      DO_CACHES=1; DO_NPM=1; DO_YARN=1; DO_PIP=1; DO_GRADLE=1; DO_XCODE=1; DO_GO=1; DO_CARGO=1; DO_BREW=1; DO_IOS=1; DO_PKG=1; shift ;;
    --dry-run|-n) DRY_RUN=1; shift ;;
    --yes|-y) AUTO_YES=1; shift ;;
    --help|-h) usage; exit 0 ;;
    *)
      print -u2 -- "${RED}未知选项：$1${NC} (运行 --help 查看支持的选项)"
      exit 1 ;;
  esac
done

print -- ""
print -- "================================================================================"
if [[ "$DRY_RUN" -eq 1 ]]; then
  print -- "             🔍 macOS 定向清理【试运行/空间预估模式 (Dry-Run)】                 "
else
  print -- "             🧹 macOS 定向安全清理执行中 (Targeted Cleaner)                    "
fi
print -- "================================================================================"

# 汇总待操作列表
print -- "\n${BOLD}📋 本次选定的清理项及其当前占用：${NC}"
TOTAL_ITEMS=0

if [[ "$DO_CACHES" -eq 1 ]]; then
  TOTAL_ITEMS=$((TOTAL_ITEMS + 1))
  printf "  [%d] %-36s ${CYAN}%s${NC}\n" "$TOTAL_ITEMS" "用户临时应用缓存 (~/Library/Caches/*)" "$(size "$HOME/Library/Caches")"
fi

if [[ -n "$SPECIFIC_CACHE_DIR" ]]; then
  TARGET_PATH="$HOME/Library/Caches/$SPECIFIC_CACHE_DIR"
  TOTAL_ITEMS=$((TOTAL_ITEMS + 1))
  printf "  [%d] %-36s ${CYAN}%s${NC}\n" "$TOTAL_ITEMS" "指定应用缓存 (~/Library/Caches/$SPECIFIC_CACHE_DIR)" "$(size "$TARGET_PATH")"
fi

if [[ "$DO_NPM" -eq 1 ]]; then
  TOTAL_ITEMS=$((TOTAL_ITEMS + 1))
  printf "  [%d] %-36s ${CYAN}%s${NC}\n" "$TOTAL_ITEMS" "npm 全局依赖缓存 (~/.npm/_cacache)" "$(size "$HOME/.npm/_cacache")"
fi

if [[ "$DO_YARN" -eq 1 ]]; then
  TOTAL_ITEMS=$((TOTAL_ITEMS + 1))
  printf "  [%d] %-36s ${CYAN}%s${NC}\n" "$TOTAL_ITEMS" "Yarn 缓存 (~/Library/Caches/Yarn)" "$(size "$HOME/Library/Caches/Yarn")"
fi

if [[ "$DO_PIP" -eq 1 ]]; then
  TOTAL_ITEMS=$((TOTAL_ITEMS + 1))
  printf "  [%d] %-36s ${CYAN}%s${NC}\n" "$TOTAL_ITEMS" "pip 缓存 (~/Library/Caches/pip)" "$(size "$HOME/Library/Caches/pip")"
fi

if [[ "$DO_GRADLE" -eq 1 ]]; then
  TOTAL_ITEMS=$((TOTAL_ITEMS + 1))
  printf "  [%d] %-36s ${CYAN}%s${NC}\n" "$TOTAL_ITEMS" "Gradle 依赖构建缓存 (~/.gradle/caches)" "$(size "$HOME/.gradle/caches")"
fi

if [[ "$DO_XCODE" -eq 1 ]]; then
  TOTAL_ITEMS=$((TOTAL_ITEMS + 1))
  printf "  [%d] %-36s ${CYAN}%s${NC}\n" "$TOTAL_ITEMS" "Xcode 编译派生数据 (DerivedData)" "$(size "$HOME/Library/Developer/Xcode/DerivedData")"
fi

if [[ "$DO_GO" -eq 1 ]]; then
  TOTAL_ITEMS=$((TOTAL_ITEMS + 1))
  printf "  [%d] %-36s ${CYAN}%s${NC}\n" "$TOTAL_ITEMS" "Go 构建及依赖缓存 (~/Library/Caches/go-build 等)" "$(size "$HOME/Library/Caches/go-build")"
fi

if [[ "$DO_CARGO" -eq 1 ]]; then
  TOTAL_ITEMS=$((TOTAL_ITEMS + 1))
  printf "  [%d] %-36s ${CYAN}%s${NC}\n" "$TOTAL_ITEMS" "Cargo 注册表及 Git 缓存 (~/.cargo/registry 等)" "$(size "$HOME/.cargo/registry")"
fi

if [[ "$DO_BREW" -eq 1 ]]; then
  TOTAL_ITEMS=$((TOTAL_ITEMS + 1))
  printf "  [%d] %-36s ${CYAN}%s${NC}\n" "$TOTAL_ITEMS" "Homebrew 下载缓存与历史旧包" "$(size "$HOME/Library/Caches/Homebrew")"
fi

if [[ "$DO_IOS" -eq 1 ]]; then
  TOTAL_ITEMS=$((TOTAL_ITEMS + 1))
  printf "  [%d] %-36s ${CYAN}%s${NC}\n" "$TOTAL_ITEMS" "iOS 设备备份 (~/Library/Application Support/MobileSync/Backup)" "$(size "$HOME/Library/Application Support/MobileSync/Backup")"
fi

if [[ "$DO_PKG" -eq 1 ]]; then
  PKG_COUNT=$(find "$HOME/Downloads" -maxdepth 1 -type f \( -name "*.dmg" -o -name "*.pkg" -o -name "*.iso" \) 2>/dev/null | wc -l | tr -d ' ')
  PKG_SIZE="0B"
  if [[ "$PKG_COUNT" -gt 0 ]]; then
    PKG_SIZE=$(find "$HOME/Downloads" -maxdepth 1 -type f \( -name "*.dmg" -o -name "*.pkg" -o -name "*.iso" \) -exec du -ch {} + 2>/dev/null | tail -n 1 | awk '{print $1}')
  fi
  TOTAL_ITEMS=$((TOTAL_ITEMS + 1))
  printf "  [%d] %-36s ${CYAN}%s (%s 个镜像)${NC}\n" "$TOTAL_ITEMS" "下载目录中的安装包 (*.dmg/*.pkg)" "$PKG_SIZE" "$PKG_COUNT"
fi

if [[ "$DO_DOCKER" -eq 1 ]]; then
  TOTAL_ITEMS=$((TOTAL_ITEMS + 1))
  printf "  [%d] %-36s ${CYAN}%s${NC}\n" "$TOTAL_ITEMS" "Docker 悬空未使用资源 (容器/镜像/网络)" "需运行 docker system prune"
fi

if [[ "$DO_TRASH" -eq 1 ]]; then
  TOTAL_ITEMS=$((TOTAL_ITEMS + 1))
  printf "  [%d] %-36s ${CYAN}%s${NC}\n" "$TOTAL_ITEMS" "废纸篓全部内容 (~/.Trash/*)" "$(size "$HOME/.Trash")"
fi

if [[ "$DO_LOGS" -eq 1 ]]; then
  TOTAL_ITEMS=$((TOTAL_ITEMS + 1))
  printf "  [%d] %-36s ${CYAN}%s${NC}\n" "$TOTAL_ITEMS" "用户级诊断日志 (~/Library/Logs/*)" "$(size "$HOME/Library/Logs")"
fi

if [[ "$TOTAL_ITEMS" -eq 0 ]]; then
  print -- "${YELLOW}未选定任何有效的清理项，退出。${NC}"
  exit 0
fi

# 如果是 Dry-run 模式，直接完成汇报并退出
if [[ "$DRY_RUN" -eq 1 ]]; then
  print -- "\n${GREEN}✔ 试运行扫描完成。上述为各选定项的当前占用大小（未修改或删除任何文件）。${NC}"
  print -- "如需真正执行清理，请去掉 --dry-run 选项。"
  exit 0
fi

# 检查是否需要交互确认
if [[ "$AUTO_YES" -eq 0 ]]; then
  print -- ""
  read -r "CONFIRM?❓ 是否确认执行以上 $TOTAL_ITEMS 项定向清理？(输入 y 确认，其他键取消) > "
  if [[ "$CONFIRM" != "y" && "$CONFIRM" != "Y" ]]; then
    print -- "${YELLOW}🚫 操作已取消。未进行任何修改。${NC}"
    exit 0
  fi
fi

# 开始执行实际清理
print -- "\n${BLUE}${BOLD}🚀 开始逐项执行定向清理：${NC}"
print -- "--------------------------------------------------------------------------------"

if [[ "$DO_CACHES" -eq 1 ]]; then
  print -n -- "🧹 正在清理用户应用临时缓存 (~/Library/Caches)... "
  rm -rf "$HOME/Library/Caches/"* 2>/dev/null || true
  print -- "${GREEN}✔ 完成${NC}"
fi

if [[ -n "$SPECIFIC_CACHE_DIR" ]]; then
  TARGET_PATH="$HOME/Library/Caches/$SPECIFIC_CACHE_DIR"
  if [[ -d "$TARGET_PATH" ]]; then
    print -n -- "🧹 正在清理应用缓存 ($SPECIFIC_CACHE_DIR)... "
    rm -rf "$TARGET_PATH" 2>/dev/null || true
    print -- "${GREEN}✔ 完成${NC}"
  else
    print -- "${YELLOW}• 缓存目录不存在：$SPECIFIC_CACHE_DIR (已跳过)${NC}"
  fi
fi

if [[ "$DO_NPM" -eq 1 ]]; then
  print -n -- "🧹 正在清理 npm 全局缓存... "
  if has npm; then
    npm cache clean --force 2>/dev/null || true
  fi
  rm -rf "$HOME/.npm/_cacache" 2>/dev/null || true
  print -- "${GREEN}✔ 完成${NC}"
fi

if [[ "$DO_YARN" -eq 1 ]]; then
  print -n -- "🧹 正在清理 Yarn 缓存... "
  if has yarn; then
    yarn cache clean 2>/dev/null || true
  fi
  rm -rf "$HOME/Library/Caches/Yarn" 2>/dev/null || true
  print -- "${GREEN}✔ 完成${NC}"
fi

if [[ "$DO_PIP" -eq 1 ]]; then
  print -n -- "🧹 正在清理 pip 缓存... "
  rm -rf "$HOME/Library/Caches/pip" 2>/dev/null || true
  print -- "${GREEN}✔ 完成${NC}"
fi

if [[ "$DO_GRADLE" -eq 1 ]]; then
  print -n -- "🧹 正在清理 Gradle 依赖构建缓存... "
  rm -rf "$HOME/.gradle/caches/"* 2>/dev/null || true
  print -- "${GREEN}✔ 完成${NC}"
fi

if [[ "$DO_XCODE" -eq 1 ]]; then
  print -n -- "🧹 正在清理 Xcode 派生构建产物 (DerivedData)... "
  rm -rf "$HOME/Library/Developer/Xcode/DerivedData/"* 2>/dev/null || true
  print -- "${GREEN}✔ 完成${NC}"
fi

if [[ "$DO_GO" -eq 1 ]]; then
  print -n -- "🧹 正在清理 Go 缓存... "
  if has go; then
    go clean -cache -modcache 2>/dev/null || true
  fi
  rm -rf "$HOME/Library/Caches/go-build" 2>/dev/null || true
  rm -rf "$HOME/go/pkg/mod/cache" 2>/dev/null || true
  print -- "${GREEN}✔ 完成${NC}"
fi

if [[ "$DO_CARGO" -eq 1 ]]; then
  print -n -- "🧹 正在清理 Cargo 缓存... "
  rm -rf "$HOME/.cargo/registry/cache/"* 2>/dev/null || true
  rm -rf "$HOME/.cargo/git/db/"* 2>/dev/null || true
  print -- "${GREEN}✔ 完成${NC}"
fi

if [[ "$DO_BREW" -eq 1 ]]; then
  print -n -- "🧹 正在执行 Homebrew 历史包与下载清理... "
  if has brew; then
    brew cleanup --prune=all 2>/dev/null || true
    print -- "${GREEN}✔ 完成${NC}"
  else
    print -- "${YELLOW}• 未安装 Homebrew (已跳过)${NC}"
  fi
fi

if [[ "$DO_IOS" -eq 1 ]]; then
  print -n -- "🧹 正在清理 iOS 设备备份与固件... "
  rm -rf "$HOME/Library/Application Support/MobileSync/Backup/"* 2>/dev/null || true
  rm -rf "$HOME/Library/iTunes/iPhone Software Updates/"* 2>/dev/null || true
  print -- "${GREEN}✔ 完成${NC}"
fi

if [[ "$DO_PKG" -eq 1 ]]; then
  print -n -- "🧹 正在清理下载目录中的 .dmg / .pkg 安装包... "
  find "$HOME/Downloads" -maxdepth 1 -type f \( -name "*.dmg" -o -name "*.pkg" -o -name "*.iso" \) -delete 2>/dev/null || true
  print -- "${GREEN}✔ 完成${NC}"
fi

if [[ "$DO_DOCKER" -eq 1 ]]; then
  print -n -- "🧹 正在清理 Docker 悬空资源 (保留 Volume 数据卷)... "
  if has docker && docker info >/dev/null 2>&1; then
    docker system prune -f 2>/dev/null || true
    print -- "${GREEN}✔ 完成${NC}"
  else
    print -- "${YELLOW}• Docker 未运行或未安装 (已跳过)${NC}"
  fi
fi

if [[ "$DO_TRASH" -eq 1 ]]; then
  print -n -- "🧹 正在清空废纸篓... "
  rm -rf "$HOME/.Trash/"* 2>/dev/null || true
  print -- "${GREEN}✔ 完成${NC}"
fi

if [[ "$DO_LOGS" -eq 1 ]]; then
  print -n -- "🧹 正在清理用户级诊断日志... "
  rm -rf "$HOME/Library/Logs/"* 2>/dev/null || true
  print -- "${GREEN}✔ 完成${NC}"
fi

print -- "--------------------------------------------------------------------------------"
print -- "${GREEN}${BOLD}✨ 所选清理任务执行完毕！${NC}\n"

print -- "💾 ${BOLD}最新硬盘根卷可用空间：${NC}"
df -h / | sed 's/^/   /'
print -- ""
