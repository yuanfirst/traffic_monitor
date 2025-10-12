#!/bin/bash
# 流量监控完整安装和配置向导

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m' # No Color

# 显示带颜色的消息
show_message() {
    local color=$1
    local message=$2
    echo -e "${color}${message}${NC}"
}

# 显示标题
show_title() {
    echo ""
    show_message $PURPLE "=========================================="
    show_message $PURPLE "$1"
    show_message $PURPLE "=========================================="
    echo ""
}

# 检查root权限
check_root() {
    if [ "$EUID" -ne 0 ]; then
        show_message $RED "错误: 此脚本需要root权限运行"
        echo "请使用: sudo $0"
        exit 1
    fi
}

# 检查系统环境
check_system() {
    show_title "系统环境检查"
    
    # 检查操作系统
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        show_message $GREEN "操作系统: $NAME $VERSION"
    else
        show_message $YELLOW "警告: 无法确定操作系统版本"
    fi
    
    # 检查网络工具
    local missing_tools=()
    
    if ! command -v ip >/dev/null 2>&1; then
        missing_tools+=("iproute2")
    fi
    
    if ! command -v tc >/dev/null 2>&1; then
        missing_tools+=("iproute2")
    fi
    
    if ! command -v bc >/dev/null 2>&1; then
        missing_tools+=("bc")
    fi
    
    if [ ${#missing_tools[@]} -gt 0 ]; then
        show_message $YELLOW "需要安装以下软件包:"
        for tool in "${missing_tools[@]}"; do
            echo "  - $tool"
        done
        echo ""
        
        read -p "是否现在安装？(Y/n): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Nn]$ ]]; then
            apt-get update
            apt-get install -y iproute2 bc
            show_message $GREEN "软件包安装完成"
        else
            show_message $RED "请手动安装所需软件包后重新运行此脚本"
            exit 1
        fi
    else
        show_message $GREEN "✅ 所有必需软件包已安装"
    fi
}

# 配置流量监控
configure_traffic_monitor() {
    show_title "流量监控配置"
    
    if [ -f "./config.sh" ]; then
        show_message $BLUE "启动配置向导..."
        ./config.sh
    else
        show_message $RED "错误: 找不到配置脚本文件"
        exit 1
    fi
}

# 选择运行方式
select_run_mode() {
    show_title "选择运行方式"
    
    echo "请选择流量监控的运行方式："
    echo ""
    echo "1. 前台运行（测试用，关闭终端会停止）"
    echo "2. 后台运行（推荐，关闭SSH仍继续运行）"
    echo "3. 系统服务（开机自启动，最稳定）"
    echo ""
    
    while true; do
        echo -n "请选择 (1-3): "
        read -r choice
        
        case $choice in
            1)
                show_message $GREEN "选择前台运行模式"
                run_foreground
                break
                ;;
            2)
                show_message $GREEN "选择后台运行模式"
                run_background
                break
                ;;
            3)
                show_message $GREEN "选择系统服务模式"
                run_as_service
                break
                ;;
            *)
                show_message $RED "请输入 1、2 或 3"
                continue
                ;;
        esac
    done
}

# 前台运行
run_foreground() {
    show_title "前台运行模式"
    
    show_message $BLUE "正在启动流量监控（前台模式）..."
    echo "按 Ctrl+C 停止监控"
    echo ""
    
    if [ -f "./traffic_monitor.sh" ]; then
        ./traffic_monitor.sh
    else
        show_message $RED "错误: 找不到traffic_monitor.sh文件"
        exit 1
    fi
}

# 后台运行
run_background() {
    show_title "后台运行模式"
    
    if [ -f "./run_background.sh" ]; then
        ./run_background.sh
        echo ""
        show_message $GREEN "✅ 后台运行启动完成！"
        echo ""
        show_message $BLUE "管理命令："
        echo "  查看状态: sudo ./manage_traffic.sh status"
        echo "  查看日志: sudo ./manage_traffic.sh logs"
        echo "  停止监控: sudo ./manage_traffic.sh stop"
    else
        show_message $RED "错误: 找不到run_background.sh文件"
        exit 1
    fi
}

# 系统服务模式
run_as_service() {
    show_title "系统服务模式"
    
    if [ -f "./install_service.sh" ]; then
        ./install_service.sh
        echo ""
        show_message $GREEN "✅ 系统服务安装完成！"
        echo ""
        show_message $BLUE "服务管理命令："
        echo "  启动服务: sudo systemctl start traffic-monitor"
        echo "  停止服务: sudo systemctl stop traffic-monitor"
        echo "  查看状态: sudo systemctl status traffic-monitor"
        echo "  查看日志: sudo journalctl -u traffic-monitor -f"
    else
        show_message $RED "错误: 找不到install_service.sh文件"
        exit 1
    fi
}

# 显示使用说明
show_usage_info() {
    show_title "使用说明"
    
    echo "流量监控脚本已配置完成！"
    echo ""
    echo "主要功能："
    echo "  ✅ 实时监控网络流量"
    echo "  ✅ 达到限制自动限速"
    echo "  ✅ 每日0点自动重置"
    echo "  ✅ 详细日志记录"
    echo ""
    echo "重要文件："
    echo "  📁 配置文件: /etc/traffic_monitor.conf"
    echo "  📁 监控日志: /var/log/traffic_monitor.log"
    echo "  📁 流量数据: /tmp/traffic_data.txt"
    echo ""
    echo "常用命令："
    echo "  🔧 重新配置: sudo ./config.sh"
    echo "  📊 查看状态: sudo ./manage_traffic.sh status"
    echo "  📝 查看日志: sudo ./manage_traffic.sh logs"
    echo "  ⏹️  停止监控: sudo ./manage_traffic.sh stop"
    echo ""
    show_message $GREEN "现在您可以安全地关闭SSH连接，流量监控将继续运行！"
}

# 主函数
main() {
    show_title "流量监控安装和配置向导"
    
    echo "欢迎使用流量监控脚本！"
    echo "此向导将帮助您完成安装、配置和启动。"
    echo ""
    
    # 检查root权限
    check_root
    
    # 检查系统环境
    check_system
    
    # 配置流量监控
    configure_traffic_monitor
    
    # 选择运行方式
    select_run_mode
    
    # 显示使用说明
    show_usage_info
}

# 运行主函数
main "$@"
