#!/usr/bin/env zsh
# ==============================================================================
# macOS 智能存储扫描与交互式清理工具 (Mac Cleaner)
# ==============================================================================

# 定义颜色
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BLUE='\033[0;34m'
BOLD='\033[1m'
NC='\033[0m' # No Color

# 辅助函数：计算文件夹或文件大小 (MB/GB/KB)
get_size() {
    local target="$1"
    if [ -e "$target" ]; then
        du -sh "$target" 2>/dev/null | awk '{print $1}'
    else
        echo "0B"
    fi
}

clear
echo -e "${CYAN}${BOLD}"
echo "================================================================================"
echo "               🍏 macOS 智能存储扫描与交互式清理工具 (Mac Cleaner)               "
echo "================================================================================${NC}"
echo ""

# 获取硬盘整体空间信息
echo -e "${BLUE}📡 正在读取当前硬盘空间状态...${NC}"
DISK_INFO=$(df -h / | tail -n 1)
DISK_TOTAL=$(echo $DISK_INFO | awk '{print $2}')
DISK_USED=$(echo $DISK_INFO | awk '{print $3}')
DISK_AVAIL=$(echo $DISK_INFO | awk '{print $4}')
DISK_CAP=$(echo $DISK_INFO | awk '{print $5}')

echo -e "💾 系统硬盘空间：总容量 ${BOLD}$DISK_TOTAL${NC} | 已用 ${YELLOW}$DISK_USED (${DISK_CAP})${NC} | 当前可用 ${GREEN}${BOLD}$DISK_AVAIL${NC}"
echo ""
echo -e "${YELLOW}🔍 正在深度扫描可安全清理的数据项，请稍候...${NC}"
echo "--------------------------------------------------------------------------------"

# 1. 计算各个待清理模块大小
SIZE_CACHES=$(get_size "$HOME/Library/Caches")
SIZE_DEV_CACHE=$(du -sh ~/.npm ~/.cache 2>/dev/null | awk '{sum+=$1} END {print sum " (合计)"}')
if [ -z "$SIZE_DEV_CACHE" ] || [ "$SIZE_DEV_CACHE" = " (合计)" ]; then SIZE_DEV_CACHE="0B"; fi

SIZE_XCODE=$(get_size "$HOME/Library/Developer/Xcode/DerivedData")
SIZE_BREW=$(get_size "$HOME/Library/Caches/Homebrew")

# 下载文件夹中的 .dmg 和 .zip
SIZE_DOWNLOADS_PKG="0B"
if ls "$HOME/Downloads/"*.dmg "$HOME/Downloads/"*.zip >/dev/null 2>&1; then
    SIZE_DOWNLOADS_PKG=$(du -ch "$HOME/Downloads/"*.dmg "$HOME/Downloads/"*.zip 2>/dev/null | tail -n 1 | awk '{print $1}')
fi

SIZE_TRASH=$(get_size "$HOME/.Trash")

# Docker 占用检查
SIZE_DOCKER="未检测或无占用"
if command -v docker >/dev/null 2>&1 && docker info >/dev/null 2>&1; then
    SIZE_DOCKER=$(docker system df 2>/dev/null | awk '/Images|Containers|Local Volumes/ {print $1 ": " $4}' | tr '\n' '  ')
fi

# Time Machine 快照
SNAP_COUNT=$(tmutil listlocalsnapshots / 2>/dev/null | grep -c "com.apple.TimeMachine" || echo "0")

# 打印扫描菜单
echo -e "${BOLD}可以进行安全清理的项目表：${NC}"
printf "  [1] %-36s ${CYAN}%s${NC}\n" "用户临时应用缓存 (~/Library/Caches/*)" "$SIZE_CACHES"
printf "  [2] %-36s ${CYAN}%s${NC}\n" "前端与开发构建缓存 (~/.npm, ~/.cache)" "$SIZE_DEV_CACHE"
printf "  [3] %-36s ${CYAN}%s${NC}\n" "Xcode 编译临时派生数据 (DerivedData)" "$SIZE_XCODE"
printf "  [4] %-36s ${CYAN}%s${NC}\n" "Homebrew 下载缓存与历史包" "$SIZE_BREW"
printf "  [5] %-36s ${CYAN}%s${NC}\n" "下载文件夹中的安装包 (*.dmg, *.zip)" "$SIZE_DOWNLOADS_PKG"
printf "  [6] %-36s ${CYAN}%s${NC}\n" "废纸篓全部内容 (~/.Trash/*)" "$SIZE_TRASH"
printf "  [7] %-36s ${CYAN}%s${NC}\n" "Docker 废弃镜像/容器与数据卷" "$SIZE_DOCKER"
printf "  [8] %-36s ${CYAN}%s${NC}\n" "Time Machine 本地快照" "$SNAP_COUNT 个快照"

echo "--------------------------------------------------------------------------------"
echo -e "${BOLD}📌 巨无霸文件夹特别提醒 (需要手动确认或应用内清理)：${NC}"
# 检查文稿中可能的巨大数据包
if [ -e "$HOME/Documents/data_transfer" ]; then
    SIZE_DT=$(get_size "$HOME/Documents/data_transfer")
    echo -e "  • ${YELLOW}~/Documents/data_transfer${NC} (占用 ${RED}${BOLD}$SIZE_DT${NC}) -> 如确认是已完成同步的数据备份，请手动删除！"
fi
# 检查微信占用
if [ -e "$HOME/Library/Containers/com.tencent.xinWeChat" ]; then
    SIZE_WX=$(get_size "$HOME/Library/Containers/com.tencent.xinWeChat")
    echo -e "  • ${YELLOW}微信聊天沙盒 (`xinWeChat`)${NC} (占用 ${RED}${BOLD}$SIZE_WX${NC}) -> 强力建议打开微信客户端【设置 -> 存储空间】中一键清理视频和原图！"
fi
echo "--------------------------------------------------------------------------------"
echo ""

# 互动选择
echo -e "${BOLD}👉 请输入您希望清理的项目序号 ${CYAN}(用空格分隔，例: 1 2 5 6)${NC}"
echo -e "   直接输入 ${GREEN}all${NC} 全选 1~8 项，或者输入 ${RED}q${NC} 退出工具："
read -r "CHOICES?选项 > "

if [[ "$CHOICES" == "q" || "$CHOICES" == "Q" || -z "$CHOICES" ]]; then
    echo -e "${YELLOW}🚫 已取消清理，退出工具。${NC}"
    exit 0
fi

SELECTED=()
if [[ "$CHOICES" == "all" || "$CHOICES" == "ALL" ]]; then
    SELECTED=(1 2 3 4 5 6 7 8)
else
    for item in $(echo "$CHOICES"); do
        if [[ "$item" =~ ^[1-8]$ ]]; then
            SELECTED+=("$item")
        fi
    done
fi

if [ ${#SELECTED[@]} -eq 0 ]; then
    echo -e "${RED}⚠️ 未检测到有效的项目序号，退出工具。${NC}"
    exit 1
fi

echo -e "\n您选择了清理以下项目序号：${GREEN}${BOLD}${SELECTED[*]}${NC}"
read -r "CONFIRM?❓ 是否最终确认立即清除选中项数据？(输入 y 确认，其他按键取消) > "

if [[ "$CONFIRM" != "y" && "$CONFIRM" != "Y" ]]; then
    echo -e "${YELLOW}🚫 用户取消执行，未做任何更改。${NC}"
    exit 0
fi

echo ""
echo -e "${BLUE}${BOLD}🚀 开始执行清理...${NC}"
echo "--------------------------------------------------------------------------------"

for item in "${SELECTED[@]}"; do
    case $item in
        1)
            echo -e "🧹 [1/8] 正在清理用户应用临时缓存 (~/Library/Caches)..."
            rm -rf "$HOME/Library/Caches/"* 2>/dev/null || true
            echo -e "   ${GREEN}✔ 完成${NC}"
            ;;
        2)
            echo -e "🧹 [2/8] 正在清理前端与开发构建缓存 (~/.npm, ~/.cache)..."
            npm cache clean --force 2>/dev/null || true
            rm -rf "$HOME/.npm/_cacache" "$HOME/.cache/"* 2>/dev/null || true
            echo -e "   ${GREEN}✔ 完成${NC}"
            ;;
        3)
            echo -e "🧹 [3/8] 正在清理 Xcode 派生缓存文件 (DerivedData)..."
            rm -rf "$HOME/Library/Developer/Xcode/DerivedData/"* 2>/dev/null || true
            echo -e "   ${GREEN}✔ 完成${NC}"
            ;;
        4)
            echo -e "🧹 [4/8] 正在执行 Homebrew 过期包与缓存清理..."
            if command -v brew >/dev/null 2>&1; then
                brew cleanup --prune=all 2>/dev/null || true
                echo -e "   ${GREEN}✔ 完成${NC}"
            else
                echo -e "   ${YELLOW}• 未检测到 Homebrew，已跳过${NC}"
            fi
            ;;
        5)
            echo -e "🧹 [5/8] 正在清理下载目录下的 .dmg 和 .zip 安装包..."
            rm -f "$HOME/Downloads/"*.dmg "$HOME/Downloads/"*.zip 2>/dev/null || true
            echo -e "   ${GREEN}✔ 完成${NC}"
            ;;
        6)
            echo -e "🧹 [6/8] 正在清空废纸篓 (~/.Trash)..."
            rm -rf "$HOME/.Trash/"* 2>/dev/null || true
            echo -e "   ${GREEN}✔ 完成${NC}"
            ;;
        7)
            echo -e "🧹 [7/8] 正在清理 Docker 悬空镜像/容器与数据卷..."
            if command -v docker >/dev/null 2>&1 && docker info >/dev/null 2>&1; then
                docker system prune -a --volumes -f 2>/dev/null || true
                echo -e "   ${GREEN}✔ 完成${NC}"
            else
                echo -e "   ${YELLOW}• 未运行 Docker 或未安装，已跳过${NC}"
            fi
            ;;
        8)
            echo -e "🧹 [8/8] 正在精简 Time Machine 本地 APFS 快照..."
            if [ "$SNAP_COUNT" -gt 0 ]; then
                sudo tmutil thinlocalsnapshots / 99000000000 4 2>/dev/null || true
                echo -e "   ${GREEN}✔ 完成${NC}"
            else
                echo -e "   ${YELLOW}• 当前无可精简快照，已跳过${NC}"
            fi
            ;;
    esac
done

echo "--------------------------------------------------------------------------------"
echo -e "${GREEN}${BOLD}✨ 所有选定项目清理完毕！${NC}"
echo ""

# 查看全新空间
NEW_DISK_AVAIL=$(df -h / | tail -n 1 | awk '{print $4}')
NEW_DISK_CAP=$(df -h / | tail -n 1 | awk '{print $5}')
echo -e "💾 最新可用硬盘空间：${GREEN}${BOLD}$NEW_DISK_AVAIL${NC} (总已用占比: $NEW_DISK_CAP)"
echo -e "${CYAN}感谢使用 Mac Cleaner，祝您工作顺心！${NC}"
echo ""
