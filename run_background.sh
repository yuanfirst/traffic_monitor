#!/bin/bash
# 后台运行流量监控脚本

echo "流量监控脚本后台运行工具"
echo "========================"

# 检查是否以root权限运行
if [ "$EUID" -ne 0 ]; then
    echo "错误: 此脚本需要root权限运行"
    echo "请使用: sudo ./run_background.sh"
    exit 1
fi

# 检查脚本是否存在
if [ ! -f "traffic_monitor.sh" ]; then
    echo "错误: 找不到 traffic_monitor.sh 脚本"
    exit 1
fi

# 检查是否已经在运行
if pgrep -f "traffic_monitor.sh" > /dev/null; then
    echo "警告: 流量监控脚本已经在运行"
    echo "当前运行的进程:"
    ps aux | grep traffic_monitor.sh | grep -v grep
    echo ""
    read -p "是否要停止现有进程并重新启动？(y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo "正在停止现有进程..."
        pkill -f traffic_monitor.sh
        sleep 2
    else
        echo "保持现有进程运行"
        exit 0
    fi
fi

# 创建日志目录
mkdir -p /var/log

echo "正在后台启动流量监控脚本..."

# 后台运行脚本，输出重定向到日志文件
nohup ./traffic_monitor.sh > /var/log/traffic_monitor_output.log 2>&1 &

# 获取进程ID
PID=$!
echo "脚本已在后台启动，进程ID: $PID"
echo "输出日志: /var/log/traffic_monitor_output.log"
echo "监控日志: /var/log/traffic_monitor.log"

# 等待一下确保脚本正常启动
sleep 3

# 检查脚本是否正常运行
if ps -p $PID > /dev/null; then
    echo "✅ 流量监控脚本运行正常"
    echo ""
    echo "管理命令:"
    echo "  查看状态: ps aux | grep traffic_monitor"
    echo "  查看输出: tail -f /var/log/traffic_monitor_output.log"
    echo "  查看监控日志: tail -f /var/log/traffic_monitor.log"
    echo "  停止脚本: sudo pkill -f traffic_monitor.sh"
    echo ""
    echo "现在您可以安全地关闭SSH连接，脚本将继续在后台运行"
else
    echo "❌ 脚本启动失败，请检查日志: /var/log/traffic_monitor_output.log"
    exit 1
fi
