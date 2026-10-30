#!/bin/bash

# ============================================================
# MinecraftSniper ServerAdmin Manager - Nuke 一键卸载脚本
# ============================================================

CONTAINER_NAME="MinecraftSniperServerAdminManager"
IMAGE_NAME="minecraftsniperserveradminmanager:nuke"

echo "=========================================="
echo "  MinecraftSniper ServerAdmin Manager - Nuke"
echo "  一键卸载脚本"
echo "=========================================="
echo ""

# 检查 Docker 是否安装
if ! command -v docker &> /dev/null; then
    echo "❌ 错误: Docker 未安装。"
    exit 1
fi

# 确认卸载
read -p "⚠️  确认卸载？将强制停止并删除容器，同时删除镜像 ($IMAGE_NAME) (y/N): " confirm
if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
    echo "已取消卸载。"
    exit 0
fi

echo ""
echo "=========================================="
echo "  开始卸载..."
echo "=========================================="

# 强制停止并删除容器
if docker ps -a --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
    echo "停止并删除容器: $CONTAINER_NAME"
    docker rm -f "$CONTAINER_NAME"
else
    echo "容器 $CONTAINER_NAME 不存在，跳过。"
fi

# 删除镜像
if docker images --format '{{.Repository}}:{{.Tag}}' | grep -q "^${IMAGE_NAME}$"; then
    echo "删除镜像: $IMAGE_NAME"
    docker image rm -f "$IMAGE_NAME"
else
    echo "镜像 $IMAGE_NAME 不存在，跳过。"
fi

echo ""
echo "=========================================="
echo "  ✅ 卸载完成"
echo "=========================================="