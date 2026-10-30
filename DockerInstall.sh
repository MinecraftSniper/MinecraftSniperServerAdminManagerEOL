#!/bin/bash

# ============================================================
# MinecraftSniper ServerAdmin Manager - Nuke 一键部署脚本
# ============================================================

# 检查 Docker 是否安装
if ! command -v docker &> /dev/null; then
    echo "❌ 错误: Docker 未安装，请先安装 Docker。"
    exit 1
fi

echo "=========================================="
echo "  MinecraftSniper ServerAdmin Manager - Nuke"
echo "  一键部署脚本"
echo "=========================================="
echo ""

# 询问是否确认安装
read -p "是否确认开始安装？(y/N): " confirm
if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
    echo "安装已取消。"
    exit 0
fi

# 询问宿主机端口号
read -p "请输入宿主机端口号 (默认 8553): " host_port
host_port=${host_port:-8553}

# 询问重启策略
echo ""
echo "请选择容器重启策略:"
echo "  1) no            - 不自动重启"
echo "  2) on-failure    - 非正常退出时重启"
echo "  3) always        - 总是重启"
echo "  4) unless-stopped - 除非手动停止，否则重启 (默认)"
read -p "输入选项 [1-4] (默认 4): " restart_choice
case $restart_choice in
    1) restart_policy="no" ;;
    2) restart_policy="on-failure" ;;
    3) restart_policy="always" ;;
    *) restart_policy="unless-stopped" ;;
esac

echo ""
echo "=========================================="
echo "  开始构建镜像..."
echo "=========================================="

docker build -t minecraftsniperserveradminmanager:nuke .

if [ $? -ne 0 ]; then
    echo "❌ 镜像构建失败，请检查错误信息。"
    exit 1
fi

echo "✅ 镜像构建成功。"

# 删除基础镜像 node:20-alpine
echo ""
echo "清理基础镜像 node:20-alpine ..."
docker image rm node:20-alpine 2>/dev/null || true


echo ""
echo "=========================================="
echo "  启动容器..."
echo "=========================================="


docker run -d \
  --name MinecraftSniperServerAdminManager \
  --restart "$restart_policy" \
  --privileged \
  --hostname MinecraftSniperServerAdminManager \
  -p "$host_port":8553 \
  -e TZ=Asia/Shanghai \
  minecraftsniperserveradminmanager:nuke

if [ $? -ne 0 ]; then
    echo "❌ 容器启动失败。"
    exit 1
fi

echo ""
echo "=========================================="
echo "  ✅ 部署完成！"
echo "  访问地址: http://<你的服务器IP>:$host_port/login.html"
echo "  容器名称: MinecraftSniperServerAdminManager"
echo "  查看日志: docker logs -f MinecraftSniperServerAdminManager"
echo "=========================================="