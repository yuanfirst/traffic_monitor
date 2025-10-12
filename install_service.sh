#!/bin/bash
# 安装systemd服务，实现开机自启动

echo "流量监控服务安装工具"
echo "===================="

# 检查是否以root权限运行
if [ "$EUID" -ne 0 ]; then
    echo "错误: 此脚本需要root权限运行"
    echo "请使用: sudo ./install_service.sh"
    exit 1
fi

# 获取当前脚本目录
SCRIPT_DIR=$(pwd)
MONITOR_SCRIPT="$SCRIPT_DIR/traffic_monitor.sh"

# 检查脚本是否存在
if [ ! -f "$MONITOR_SCRIPT" ]; then
    echo "错误: 找不到 traffic_monitor.sh 脚本"
    echo "请确保在正确的目录中运行此脚本"
    exit 1
fi

# 创建服务文件
SERVICE_FILE="/etc/systemd/system/traffic-monitor.service"

echo "正在创建systemd服务文件..."

cat > "$SERVICE_FILE" << EOF
[Unit]
Description=Traffic Monitor and Limiter
Documentation=https://github.com/your-repo/traffic-monitor
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
User=root
Group=root
WorkingDirectory=$SCRIPT_DIR
ExecStart=/bin/bash $MONITOR_SCRIPT
Restart=always
RestartSec=10
StandardOutput=journal
StandardError=journal
SyslogIdentifier=traffic-monitor

# 安全设置
NoNewPrivileges=false
PrivateTmp=false
ProtectSystem=false

[Install]
WantedBy=multi-user.target
EOF

echo "服务文件已创建: $SERVICE_FILE"

# 重新加载systemd
echo "重新加载systemd配置..."
systemctl daemon-reload

# 启用服务
echo "启用服务..."
systemctl enable traffic-monitor.service

echo ""
echo "✅ 服务安装完成！"
echo ""
echo "管理命令:"
echo "  启动服务: sudo systemctl start traffic-monitor"
echo "  停止服务: sudo systemctl stop traffic-monitor"
echo "  重启服务: sudo systemctl restart traffic-monitor"
echo "  查看状态: sudo systemctl status traffic-monitor"
echo "  查看日志: sudo journalctl -u traffic-monitor -f"
echo ""
echo "开机自启动已启用，系统重启后会自动启动流量监控"

# 询问是否立即启动
read -p "是否现在启动服务？(Y/n): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Nn]$ ]]; then
    echo "正在启动服务..."
    systemctl start traffic-monitor
    sleep 2
    
    if systemctl is-active --quiet traffic-monitor; then
        echo "✅ 服务启动成功"
        echo "查看状态: sudo systemctl status traffic-monitor"
    else
        echo "❌ 服务启动失败"
        echo "查看日志: sudo journalctl -u traffic-monitor --no-pager"
    fi
fi
