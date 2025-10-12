#!/bin/bash
# 流量监控配置工具

CONFIG_FILE="/etc/traffic_monitor.conf"

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

show_message() {
    local color=$1
    local message=$2
    echo -e "${color}${message}${NC}"
}

# 显示当前配置
show_config() {
    echo ""
    show_message $BLUE "当前配置："
    echo "=================="
    
    if [ -f "$CONFIG_FILE" ]; then
        source "$CONFIG_FILE"
        echo "网络接口: $INTERFACE"
        echo "每日限制: ${DAILY_LIMIT_GB}GB"
        echo "限速值: ${SPEED_LIMIT_MBPS}Mbps"
    else
        show_message $YELLOW "未找到配置文件，使用默认配置"
        echo "默认网口: ens5"
        echo "默认限制: 15GB"
        echo "默认限速: 3Mbps"
    fi
}

# 保存配置
save_config() {
    local interface=$1
    local daily_limit=$2
    local speed_limit=$3
    
    mkdir -p "$(dirname "$CONFIG_FILE")"
    
    cat > "$CONFIG_FILE" << EOF
# 流量监控配置文件
# 生成时间: $(date)

INTERFACE=$interface
DAILY_LIMIT_GB=$daily_limit
SPEED_LIMIT_MBPS=$speed_limit

# 配置说明:
# INTERFACE - 要监控的网络接口名称
# DAILY_LIMIT_GB - 每日流量限制（GB）
# SPEED_LIMIT_MBPS - 超限后的速度限制（Mbps）
EOF
    
    show_message $GREEN "配置已保存到: $CONFIG_FILE"
}

# 快速配置向导
quick_config() {
    echo ""
    show_message $GREEN "流量监控配置向导"
    show_message $GREEN "=================="
    
    # 显示当前配置
    show_config
    
    # 直接提供选项，不进行网络检测
    echo ""
    show_message $BLUE "常用网络接口选项："
    echo "1. ens5 (默认)"
    echo "2. ens3"
    echo "3. ens33"
    echo "4. eth0"
    echo "5. 手动输入"
    echo ""
    
    # 选择网口
    while true; do
        echo -n "请选择网口 (1-5): "
        read -r choice
        
        case $choice in
            1)
                selected_interface="ens5"
                break
                ;;
            2)
                selected_interface="ens3"
                break
                ;;
            3)
                selected_interface="ens33"
                break
                ;;
            4)
                selected_interface="eth0"
                break
                ;;
            5)
                echo -n "请输入网口名称: "
                read -r selected_interface
                if [ -n "$selected_interface" ]; then
                    break
                else
                    show_message $RED "网口名称不能为空"
                    continue
                fi
                ;;
            *)
                show_message $RED "请输入 1-5"
                continue
                ;;
        esac
    done
    
    show_message $GREEN "已选择网口: $selected_interface"
    
    # 设置每日限制
    echo ""
    show_message $BLUE "每日流量限制选项："
    echo "1. 10GB"
    echo "2. 15GB (默认)"
    echo "3. 20GB"
    echo "4. 30GB"
    echo "5. 自定义"
    echo ""
    
    while true; do
        echo -n "请选择每日限制 (1-5): "
        read -r choice
        
        case $choice in
            1)
                daily_limit="10"
                break
                ;;
            2)
                daily_limit="15"
                break
                ;;
            3)
                daily_limit="20"
                break
                ;;
            4)
                daily_limit="30"
                break
                ;;
            5)
                while true; do
                    echo -n "请输入每日限制 (GB，1-1000): "
                    read -r limit
                    if [[ "$limit" =~ ^[0-9]+(\.[0-9]+)?$ ]]; then
                        local limit_num=$(echo "$limit" | awk '{print int($1)}')
                        if [ $limit_num -ge 1 ] && [ $limit_num -le 1000 ]; then
                            daily_limit="$limit"
                            break 2
                        else
                            show_message $RED "限制必须在1-1000GB之间"
                            continue
                        fi
                    else
                        show_message $RED "请输入有效数字"
                        continue
                    fi
                done
                ;;
            *)
                show_message $RED "请输入 1-5"
                continue
                ;;
        esac
    done
    
    show_message $GREEN "已设置每日限制: ${daily_limit}GB"
    
    # 设置限速值
    echo ""
    show_message $BLUE "限速值选项："
    echo "1. 1Mbps"
    echo "2. 2Mbps"
    echo "3. 3Mbps (默认)"
    echo "4. 5Mbps"
    echo "5. 自定义"
    echo ""
    
    while true; do
        echo -n "请选择限速值 (1-5): "
        read -r choice
        
        case $choice in
            1)
                speed_limit="1"
                break
                ;;
            2)
                speed_limit="2"
                break
                ;;
            3)
                speed_limit="3"
                break
                ;;
            4)
                speed_limit="5"
                break
                ;;
            5)
                while true; do
                    echo -n "请输入限速值 (Mbps，0.1-100): "
                    read -r speed
                    if [[ "$speed" =~ ^[0-9]+(\.[0-9]+)?$ ]]; then
                        local speed_num=$(echo "$speed" | awk '{print $1}')
                        if (( $(echo "$speed >= 0.1" | bc -l 2>/dev/null || echo "0") )) && (( $(echo "$speed <= 100" | bc -l 2>/dev/null || echo "0") )); then
                            speed_limit="$speed"
                            break 2
                        else
                            show_message $RED "限速值必须在0.1-100Mbps之间"
                            continue
                        fi
                    else
                        show_message $RED "请输入有效数字"
                        continue
                    fi
                done
                ;;
            *)
                show_message $RED "请输入 1-5"
                continue
                ;;
        esac
    done
    
    show_message $GREEN "已设置限速值: ${speed_limit}Mbps"
    
    # 确认配置
    echo ""
    show_message $BLUE "配置确认："
    echo "=================="
    echo "网络接口: $selected_interface"
    echo "每日限制: ${daily_limit}GB"
    echo "限速值: ${speed_limit}Mbps"
    echo ""
    
    while true; do
        echo -n "确认保存此配置？(Y/n): "
        read -r confirm
        case $confirm in
            [Yy]|"")
                save_config "$selected_interface" "$daily_limit" "$speed_limit"
                echo ""
                show_message $GREEN "配置完成！现在可以启动流量监控了"
                echo ""
                show_message $BLUE "启动命令："
                echo "  sudo ./run_background.sh"
                return 0
                ;;
            [Nn])
                show_message $YELLOW "配置已取消"
                return 1
                ;;
            *)
                show_message $RED "请输入 Y 或 n"
                continue
                ;;
        esac
    done
}

# 主函数
main() {
    case "${1:-config}" in
        config)
            quick_config
            ;;
        show)
            show_config
            ;;
        reset)
            if [ -f "$CONFIG_FILE" ]; then
                rm -f "$CONFIG_FILE"
                show_message $GREEN "配置已重置为默认值"
            else
                show_message $YELLOW "配置文件不存在"
            fi
            ;;
        *)
            echo "用法: $0 [config|show|reset]"
            echo ""
            echo "选项:"
            echo "  config  快速配置（默认）"
            echo "  show    显示当前配置"
            echo "  reset   重置配置"
            ;;
    esac
}

# 检查root权限
if [ "$EUID" -ne 0 ]; then
    show_message $RED "错误: 此脚本需要root权限运行"
    echo "请使用: sudo $0"
    exit 1
fi

# 运行主函数
main "$@"
