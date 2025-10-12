#!/bin/bash
# 流量监控脚本管理工具

show_help() {
    echo "流量监控脚本管理工具"
    echo "===================="
    echo ""
    echo "用法: $0 [选项]"
    echo ""
    echo "选项:"
    echo "  start     启动后台监控"
    echo "  stop      停止监控"
    echo "  restart   重启监控"
    echo "  status    查看状态"
    echo "  logs      查看日志"
    echo "  follow    实时查看日志"
    echo "  help      显示此帮助信息"
    echo ""
    echo "示例:"
    echo "  sudo $0 start    # 启动后台监控"
    echo "  sudo $0 status   # 查看运行状态"
    echo "  sudo $0 logs     # 查看日志"
}

start_monitor() {
    echo "启动流量监控..."
    
    if pgrep -f "traffic_monitor.sh" > /dev/null; then
        echo "流量监控已经在运行中"
        show_status
        return 0
    fi
    
    if [ ! -f "traffic_monitor.sh" ]; then
        echo "错误: 找不到 traffic_monitor.sh 脚本"
        exit 1
    fi
    
    # 创建日志目录
    mkdir -p /var/log
    
    # 后台启动
    nohup ./traffic_monitor.sh > /var/log/traffic_monitor_output.log 2>&1 &
    
    sleep 2
    
    if pgrep -f "traffic_monitor.sh" > /dev/null; then
        echo "✅ 流量监控已启动"
        echo "现在您可以安全地关闭SSH连接"
    else
        echo "❌ 启动失败，请检查日志"
        exit 1
    fi
}

stop_monitor() {
    echo "停止流量监控..."
    
    if ! pgrep -f "traffic_monitor.sh" > /dev/null; then
        echo "流量监控未在运行"
        return 0
    fi
    
    pkill -f traffic_monitor.sh
    
    sleep 2
    
    if ! pgrep -f "traffic_monitor.sh" > /dev/null; then
        echo "✅ 流量监控已停止"
        echo "速度限制已自动移除"
    else
        echo "⚠️  停止失败，尝试强制终止..."
        pkill -9 -f traffic_monitor.sh
        sleep 1
        if ! pgrep -f "traffic_monitor.sh" > /dev/null; then
            echo "✅ 流量监控已强制停止"
        else
            echo "❌ 无法停止流量监控"
            exit 1
        fi
    fi
}

restart_monitor() {
    echo "重启流量监控..."
    stop_monitor
    sleep 2
    start_monitor
}

show_status() {
    echo "流量监控状态"
    echo "============"
    
    if pgrep -f "traffic_monitor.sh" > /dev/null; then
        echo "状态: ✅ 运行中"
        echo "进程信息:"
        ps aux | grep traffic_monitor.sh | grep -v grep
        echo ""
        
        # 显示限速状态
        if tc qdisc show dev ens5 | grep -q "htb"; then
            echo "限速状态: 🔴 已限速"
            echo "限速规则:"
            tc qdisc show dev ens5
        else
            echo "限速状态: 🟢 正常"
        fi
        
        # 显示今日流量
        if [ -f "/tmp/traffic_data.txt" ]; then
            echo ""
            echo "今日流量统计:"
            if grep -q "DAILY_RX" /tmp/traffic_data.txt; then
                daily_rx=$(grep "DAILY_RX" /tmp/traffic_data.txt | cut -d'=' -f2)
                daily_tx=$(grep "DAILY_TX" /tmp/traffic_data.txt | cut -d'=' -f2)
                total=$((daily_rx + daily_tx))
                echo "  接收: $(numfmt --to=iec $daily_rx)"
                echo "  发送: $(numfmt --to=iec $daily_tx)"
                echo "  总计: $(numfmt --to=iec $total)"
            fi
        fi
        
    else
        echo "状态: ❌ 未运行"
    fi
}

show_logs() {
    echo "流量监控日志 (最近50行)"
    echo "========================"
    
    if [ -f "/var/log/traffic_monitor.log" ]; then
        tail -n 50 /var/log/traffic_monitor.log
    else
        echo "日志文件不存在"
    fi
    
    echo ""
    echo "输出日志 (最近20行)"
    echo "===================="
    
    if [ -f "/var/log/traffic_monitor_output.log" ]; then
        tail -n 20 /var/log/traffic_monitor_output.log
    else
        echo "输出日志文件不存在"
    fi
}

follow_logs() {
    echo "实时查看流量监控日志 (按 Ctrl+C 退出)"
    echo "===================================="
    
    if [ -f "/var/log/traffic_monitor.log" ]; then
        tail -f /var/log/traffic_monitor.log
    else
        echo "日志文件不存在"
    fi
}

# 主逻辑
case "${1:-help}" in
    start)
        start_monitor
        ;;
    stop)
        stop_monitor
        ;;
    restart)
        restart_monitor
        ;;
    status)
        show_status
        ;;
    logs)
        show_logs
        ;;
    follow)
        follow_logs
        ;;
    help|--help|-h)
        show_help
        ;;
    *)
        echo "未知选项: $1"
        show_help
        exit 1
        ;;
esac
