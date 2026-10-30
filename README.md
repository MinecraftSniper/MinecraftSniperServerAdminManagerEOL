# 🚀 MinecraftSniper ServerAdmin Manager - EOL（最终版）

**MinecraftSniper ServerAdmin Manager EOL** 是本项目的最终形态（最终版），也是 **End Of Life (EOL)** 版本。在融合了此前所有版本（含 Nuke 核弹版）的经验后，最终版为服务器运维带来了一套极致轻量且权限极高的管理方案。

> ⚠️ **最终版警告**：本面板拥有极高的系统权限（包括终端、磁盘操作等），设计定位为**内网环境**或 **VPN** 下使用，严禁直接暴露在公网。

---

## ✨ 最终版核心特性

### 1. 精简聚焦的性能监控
*   **📊 四大核心指标**：CPU 使用率、系统已用内存、网卡使用率、CPU 温度，界面简洁直观。
*   **容量解析上限提升**：后端磁盘解析逻辑全面重构，容量单位支持至 YB（Yottabyte），配合 BigInt 处理海量数据。

### 2. 企业级安全认证
*   拒绝传统的明文密码，采用 **RSA 私钥签名 + JWT** 进行身份验证。
*   首次启动自动生成密钥对，私钥仅在客户端下载保存，服务器只留公钥，杜绝中间人攻击与暴力破解。

### 3. 全功能运维面板
*   **📊 性能监控**：CPU 使用率、系统已用内存、网卡使用率、CPU 温度。
*   **📁 文件管理**：基于全盘路径的浏览、上传、下载、删除操作，突破常规 Web 面板的目录限制。
*   **💾 磁盘管理**：支持物理磁盘的挂载、卸载、格式化，并集成 SMART 与 eMMC 健康检测，系统盘自动识别并加入安全锁（仅允许健康检测）。开启开机自动挂载时，通过 `blkid` 读取磁盘 UUID 写入 `/etc/fstab`，避免设备路径漂移导致开机挂载失败。
*   **🖥️ 交互式终端**：基于 PTY 和 xterm.js 提供完整的 WebSocket 全功能终端，支持 vim、top、nano 等交互式命令。

---

## 🛠️ 技术架构与界面

*   **后端核心**：Node.js + Express + WebSocket + Multer
*   **终端能力**：@homebridge/node-pty-prebuilt-multiarch + xterm.js
*   **前端界面**：原生 HTML/CSS/JS（无框架），轻量级、响应式、支持深色/浅色主题无缝切换
*   **数据持久化**：本地 JSON 文件驱动，无额外数据库依赖

---

## 🛡️ 安全与维护指南（必读）

1.  **私钥丢失无法找回**：RSA 私钥仅限登录使用，一旦丢失将无法登录管理面板，请务必妥善备份（建议保存到密码管理器或离线加密存储）。
2.  **敏感文件保护**：请勿将 `sslkey/`（HTTPS 私钥）、`admin.pub`、`adminconfig.json`、`traffic.json` 上传至公开 Git 仓库。
3.  **HTTPS 证书**：`sslkey/` 目录下的证书用于 HTTPS 加密访问。自签名证书会导致浏览器提示不安全，点击继续访问即可。
4.  **环境隔离**：建议配合 Nginx 反向代理并设置 IP 白名单使用，不要把管理端口直接通过路由器端口转发到公网。

---

## 📜 项目状态与版权

本项目现已进入 **EOL (End Of Life)** 阶段，不再增加新功能。

*   © 林鋆成 All Rights Reserved.
*   前作（Nuke 核弹版）：[MinecraftSniperServerAdminManagerNuke](https://gitee.com/Minecraft-Sniper/MinecraftSniperServerAdminManagerNuke)
*   原项目：[MinecraftSniperServerAdminManager](https://gitee.com/Minecraft-Sniper/MinecraftSniperServerAdminManager)
