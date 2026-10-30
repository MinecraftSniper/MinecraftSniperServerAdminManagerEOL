#!/bin/bash
# MinecraftSniperServerAdminManager - 卸载脚本
# 功能：停止服务 → 禁用服务 → 询问是否卸载 mmc-utils → 询问是否卸载 Node.js → 删除整个项目目录
# 注意：此脚本会删除脚本所在目录及其所有内容，请谨慎使用！

set -e

# ============================================================
# 颜色和样式
# ============================================================
RESET="\033[0m"
RED="\033[0;31m"
GREEN="\033[0;32m"
YELLOW="\033[0;33m"
CYAN="\033[0;36m"
WHITE="\033[0;37m"
BOLD="\033[1m"

# ============================================================
# 获取脚本自身所在目录（项目根目录）
# ============================================================
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$SCRIPT_DIR"

# 服务名称（与 install.sh 保持一致）
SERVICE_NAME="MinecraftSniperServerAdminManager"

# ============================================================
# 彩色输出函数
# ============================================================
cprint() {
    local color=""
    local text=""
    local styles=""
    local disable_prefix=false

    while [[ $# -gt 1 ]]; do
        case "$1" in
            red|green|yellow|cyan|white)
                color="$1"
                ;;
            bold)
                styles="${BOLD}"
                ;;
            noprefix)
                disable_prefix=true
                ;;
        esac
        shift
    done

    text="$1"

    local prefix_text=""
    if [[ "$disable_prefix" != true ]]; then
        prefix_text="[$(date +%H:%M:%S)] [Uninstaller] "
    fi

    local color_code=""
    case "$color" in
        red) color_code="$RED" ;;
        green) color_code="$GREEN" ;;
        yellow) color_code="$YELLOW" ;;
        cyan) color_code="$CYAN" ;;
        white) color_code="$WHITE" ;;
    esac

    printf "%s%s%s%s%s\n" "$prefix_text" "$styles" "$color_code" "$text" "$RESET"
}

# ============================================================
# 检查 root 权限
# ============================================================
check_root() {
    if [ "$EUID" -ne 0 ]; then
        cprint red "错误: 此脚本需要 root 权限运行"
        cprint yellow "请使用: sudo bash uninstall.sh"
        exit 1
    fi
}

# ============================================================
# 安全检查
# ============================================================
safety_check() {
    local dangerous_paths=(
        "/" "/bin" "/boot" "/dev" "/etc" "/home"
        "/lib" "/lib64" "/mnt" "/opt" "/proc" "/root"
        "/run" "/sbin" "/srv" "/sys" "/tmp" "/usr" "/var"
    )

    for dangerous in "${dangerous_paths[@]}"; do
        if [[ "$PROJECT_DIR" == "$dangerous" ]] || [[ "$PROJECT_DIR" == "$dangerous/"* ]]; then
            cprint red "严重错误: 检测到危险路径 '$PROJECT_DIR'"
            cprint red "此路径可能是系统目录，脚本拒绝执行"
            exit 1
        fi
    done

    if [[ ! -f "$PROJECT_DIR/adminserver.js" ]] && [[ ! -f "$PROJECT_DIR/package.json" ]]; then
        cprint red "错误: 当前目录不是 MinecraftSniper 项目目录"
        cprint red "未找到 adminserver.js 或 package.json"
        cprint yellow "当前目录: $PROJECT_DIR"
        exit 1
    fi

    cprint green "安全检查通过"
}

# ============================================================
# 检测系统包管理器
# ============================================================
detect_pkg_manager() {
    if command -v apt >/dev/null 2>&1; then
        PKG_MANAGER="apt"
        PKG_REMOVE="apt remove -y"
        PKG_PURGE="apt purge -y"
    elif command -v dnf >/dev/null 2>&1; then
        PKG_MANAGER="dnf"
        PKG_REMOVE="dnf remove -y"
        PKG_PURGE="dnf remove -y"
    elif command -v yum >/dev/null 2>&1; then
        PKG_MANAGER="yum"
        PKG_REMOVE="yum remove -y"
        PKG_PURGE="yum remove -y"
    elif command -v pacman >/dev/null 2>&1; then
        PKG_MANAGER="pacman"
        PKG_REMOVE="pacman -R --noconfirm"
        PKG_PURGE="pacman -Rns --noconfirm"
    else
        PKG_MANAGER="unknown"
    fi
    cprint cyan "包管理器: $PKG_MANAGER"
}

# ============================================================
# 停止服务
# ============================================================
stop_service() {
    cprint cyan "正在停止服务 $SERVICE_NAME ..."

    if systemctl is-active --quiet "$SERVICE_NAME" 2>/dev/null; then
        if systemctl stop "$SERVICE_NAME" 2>/dev/null; then
            cprint green "服务已停止"
        else
            cprint yellow "停止服务失败（可能已停止）"
        fi
    else
        cprint yellow "服务未运行"
    fi

    local pids=$(pgrep -f "node server.js" 2>/dev/null || true)
    if [ -n "$pids" ]; then
        cprint yellow "发现残留进程: $pids"
        cprint cyan "正在清理残留进程..."
        pkill -f "node server.js" 2>/dev/null || true
        sleep 1
        cprint green "残留进程已清理"
    fi
}

# ============================================================
# 禁用并删除服务文件
# ============================================================
disable_service() {
    cprint cyan "正在禁用并删除服务..."

    if systemctl is-enabled --quiet "$SERVICE_NAME" 2>/dev/null; then
        if systemctl disable "$SERVICE_NAME" 2>/dev/null; then
            cprint green "服务已禁用"
        else
            cprint yellow "禁用服务失败"
        fi
    else
        cprint yellow "服务未启用或不存在"
    fi

    local service_file="/etc/systemd/system/${SERVICE_NAME}.service"
    if [ -f "$service_file" ]; then
        cprint cyan "正在删除服务文件: $service_file"
        rm -f "$service_file" 2>/dev/null
        systemctl daemon-reload 2>/dev/null || true
        cprint green "服务文件已删除"
    fi
}

# ============================================================
# 卸载 mmc-utils（用户选择）
# ============================================================
uninstall_mmc_utils() {
    # 检查 mmc-utils 是否已安装
    local mmc_installed=false
    if command -v mmc >/dev/null 2>&1; then
        mmc_installed=true
    fi

    # 检查包管理器是否已安装 mmc-utils
    if [ "$PKG_MANAGER" != "unknown" ]; then
        case "$PKG_MANAGER" in
            apt)
                if dpkg -l mmc-utils 2>/dev/null | grep -q "^ii"; then
                    mmc_installed=true
                fi
                ;;
            dnf|yum)
                if rpm -q mmc-utils 2>/dev/null; then
                    mmc_installed=true
                fi
                ;;
            pacman)
                if pacman -Q mmc-utils 2>/dev/null; then
                    mmc_installed=true
                fi
                ;;
        esac
    fi

    if [ "$mmc_installed" = false ]; then
        cprint yellow "mmc-utils 未安装或未被检测到，跳过"
        return 0
    fi

    echo ""
    cprint yellow "检测到 mmc-utils 已安装（用于 eMMC 健康检测）"
    read -p "$(cprint yellow noprefix "是否卸载 mmc-utils? (y/N): ")" confirm_mmc

    if [[ "$confirm_mmc" != "y" && "$confirm_mmc" != "Y" ]]; then
        cprint green "保留 mmc-utils"
        return 0
    fi

    cprint cyan "正在卸载 mmc-utils..."

    case "$PKG_MANAGER" in
        apt)
            $PKG_PURGE mmc-utils 2>/dev/null || $PKG_REMOVE mmc-utils 2>/dev/null || {
                cprint yellow "卸载 mmc-utils 失败，请手动卸载"
            }
            ;;
        dnf|yum)
            $PKG_REMOVE mmc-utils 2>/dev/null || {
                cprint yellow "卸载 mmc-utils 失败，请手动卸载"
            }
            ;;
        pacman)
            $PKG_PURGE mmc-utils 2>/dev/null || {
                cprint yellow "卸载 mmc-utils 失败，请手动卸载"
            }
            ;;
        *)
            cprint yellow "无法自动卸载，请手动执行:"
            cprint yellow "  - Debian/Ubuntu: apt purge mmc-utils"
            cprint yellow "  - RHEL/CentOS: yum remove mmc-utils"
            cprint yellow "  - Arch: pacman -Rns mmc-utils"
            ;;
    esac

    # 验证是否卸载成功
    if command -v mmc >/dev/null 2>&1; then
        cprint yellow "mmc-utils 可能仍存在，请手动检查"
    else
        cprint green "mmc-utils 已卸载"
    fi
}

# ============================================================
# 卸载 Node.js（用户选择）
# ============================================================
uninstall_nodejs() {
    # 检查 Node.js 是否已安装
    if ! command -v node >/dev/null 2>&1; then
        cprint yellow "Node.js 未安装或未被检测到，跳过"
        return 0
    fi

    local node_version=$(node -v 2>/dev/null || echo "未知")
    local node_path=$(which node 2>/dev/null || echo "未知")
    echo ""
    cprint yellow "检测到 Node.js: $node_version"
    cprint yellow "安装路径: $node_path"
    cprint red "⚠️  卸载 Node.js 可能影响其他依赖 Node.js 的应用！"
    read -p "$(cprint yellow noprefix "是否卸载 Node.js? (y/N): ")" confirm_node

    if [[ "$confirm_node" != "y" && "$confirm_node" != "Y" ]]; then
        cprint green "保留 Node.js"
        return 0
    fi

    cprint red "正在卸载 Node.js..."

    # 尝试通过包管理器卸载
    local uninstalled=false

    case "$PKG_MANAGER" in
        apt)
            # 尝试多种 Node.js 包名
            for pkg in nodejs nodejs-dev; do
                if dpkg -l $pkg 2>/dev/null | grep -q "^ii"; then
                    cprint cyan "卸载: $pkg"
                    $PKG_PURGE $pkg 2>/dev/null && uninstalled=true
                fi
            done
            # 清理 NodeSource 仓库
            if [ -f /etc/apt/sources.list.d/nodesource.list ]; then
                cprint cyan "删除 NodeSource 仓库配置..."
                rm -f /etc/apt/sources.list.d/nodesource.list
                apt update 2>/dev/null || true
            fi
            ;;
        dnf|yum)
            for pkg in nodejs nodejs-devel; do
                if rpm -q $pkg 2>/dev/null; then
                    cprint cyan "卸载: $pkg"
                    $PKG_REMOVE $pkg 2>/dev/null && uninstalled=true
                fi
            done
            if [ -f /etc/yum.repos.d/nodesource-el*.repo ]; then
                cprint cyan "删除 NodeSource 仓库配置..."
                rm -f /etc/yum.repos.d/nodesource-el*.repo
            fi
            ;;
        pacman)
            if pacman -Q nodejs 2>/dev/null; then
                cprint cyan "卸载: nodejs"
                $PKG_PURGE nodejs 2>/dev/null && uninstalled=true
            fi
            if pacman -Q npm 2>/dev/null; then
                cprint cyan "卸载: npm"
                $PKG_PURGE npm 2>/dev/null
            fi
            ;;
        *)
            cprint yellow "无法自动卸载 Node.js，请手动卸载"
            cprint yellow "  访问: https://nodejs.org/ 查看卸载指南"
            return 0
            ;;
    esac

    # 检查通过包管理器是否卸载成功
    if command -v node >/dev/null 2>&1; then
        cprint yellow "包管理器卸载未完全成功，尝试删除残留文件..."

        # 尝试删除 Node.js 相关文件和目录
        local node_dirs=(
            "/usr/local/bin/node"
            "/usr/local/bin/npm"
            "/usr/local/bin/npx"
            "/usr/local/lib/node_modules"
            "/usr/local/include/node"
            "/usr/share/doc/nodejs"
            "/usr/share/man/man1/node*"
        )

        for dir in "${node_dirs[@]}"; do
            if [ -e "$dir" ]; then
                cprint cyan "删除: $dir"
                rm -rf "$dir" 2>/dev/null || true
            fi
        done

        if command -v node >/dev/null 2>&1; then
            cprint yellow "Node.js 可能仍存在: $(which node)"
            cprint yellow "请手动检查并卸载"
        else
            cprint green "Node.js 已卸载"
            uninstalled=true
        fi
    else
        cprint green "Node.js 已通过包管理器卸载"
        uninstalled=true
    fi

    # 清理 npm 缓存
    if [ "$uninstalled" = true ] || command -v npm >/dev/null 2>&1; then
        cprint cyan "清理 npm 缓存..."
        if command -v npm >/dev/null 2>&1; then
            npm cache clean --force 2>/dev/null || true
        fi
        rm -rf ~/.npm 2>/dev/null || true
        rm -rf ~/.node-gyp 2>/dev/null || true
        rm -rf /tmp/npm-* 2>/dev/null || true
    fi

    cprint green "Node.js 卸载处理完成"
}

# ============================================================
# 删除项目目录
# ============================================================
delete_project() {
    cprint cyan "正在准备删除项目目录: $PROJECT_DIR"

    cprint yellow "目录内容:"
    ls -la "$PROJECT_DIR" 2>/dev/null | head -20

    echo ""
    cprint red bold "⚠️  警告: 此操作将永久删除以上目录及其所有内容！"
    cprint red bold "⚠️  此操作不可恢复！"
    echo ""

    read -p "$(cprint yellow noprefix "确认删除? 请输入 'yes' 确认: ")" confirm

    if [[ "$confirm" != "yes" ]]; then
        cprint yellow "操作已取消"
        exit 0
    fi

    echo ""
    cprint red bold "正在删除目录..."
    cd /tmp || exit 1

    if rm -rf "$PROJECT_DIR"; then
        cprint green "目录已删除: $PROJECT_DIR"
    else
        cprint red "删除目录失败"
        exit 1
    fi
}

# ============================================================
# 打印卸载结果
# ============================================================
print_result() {
    clear 2>/dev/null || true

    cprint white noprefix "============================================"
    cprint white noprefix "  MinecraftSniper ServerAdmin Manager"
    cprint white noprefix "  卸载完成"
    cprint white noprefix "============================================"
    echo ""

    cprint green "✅ 已停止并禁用服务: $SERVICE_NAME"
    cprint green "✅ 已删除项目目录: $PROJECT_DIR"
    echo ""

    cprint yellow noprefix "如果还有残留文件，请手动检查:"
    cprint white noprefix "  ls -la /etc/systemd/system/ | grep ${SERVICE_NAME}"
    cprint white noprefix "  ps aux | grep node | grep server.js"
    echo ""

    cprint green noprefix "============================================"
    cprint green noprefix "  卸载完成"
    cprint green noprefix "============================================"
}

# ============================================================
# 主函数
# ============================================================
main() {
    cprint cyan bold "MinecraftSniper ServerAdmin Manager - 卸载脚本"
    cprint cyan "项目目录: $PROJECT_DIR"
    echo ""

    check_root
    safety_check
    detect_pkg_manager

    echo ""
    cprint yellow "即将执行以下操作:"
    cprint yellow "  1. 停止服务 $SERVICE_NAME"
    cprint yellow "  2. 禁用并删除服务"
    cprint yellow "  3. 询问是否卸载 mmc-utils（可选）"
    cprint yellow "  4. 询问是否卸载 Node.js（可选）"
    cprint yellow "  5. 删除目录: $PROJECT_DIR"
    echo ""

    read -p "$(cprint yellow noprefix "继续? 请输入 'yes' 确认: ")" confirm

    if [[ "$confirm" != "yes" ]]; then
        cprint yellow "操作已取消"
        exit 0
    fi

    echo ""
    stop_service
    disable_service

    # 询问是否卸载 mmc-utils
    uninstall_mmc_utils

    # 询问是否卸载 Node.js
    uninstall_nodejs

    # 删除项目目录
    delete_project

    print_result
}

main "$@"