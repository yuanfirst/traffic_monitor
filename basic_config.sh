#!/bin/bash
# 流量监控基础配置工具

CONFIG_FILE="/etc/traffic_monitor.conf"

echo "流量监控配置创建工具"
echo "===================="
echo ""

# 检查是否以root权限运行
if [ "$EUID" -ne 0 ]; then
    echo "错误: 此脚本需要root权限运行"
    echo "请使用: sudo $0"
    exit 1
fi

# 显示当前配置
if [ -f "$CONFIG_FILE" ]; then
    echo "当前配置："
    cat "$CONFIG_FILE"
    echo ""
    read -p "是否要重新配置？(y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "配置保持不变"
        exit 0
    fi
fi

echo "请按提示输入配置信息（直接回车使用默认值）"
echo ""

# 网口配置
echo "网络接口选择："
echo "1. ens5 (默认)"
echo "2. ens3"
echo "3. ens33"
echo "4. eth0"
echo "5. 自定义"
echo ""
read -p "请选择 (1-5): " choice

case $choice in
    1)
        INTERFACE="ens5"
        ;;
    2)
        INTERFACE="ens3"
        ;;
    3)
        INTERFACE="ens33"
        ;;
    4)
        INTERFACE="eth0"
        ;;
    5)
        read -p "请输入网口名称: " INTERFACE
        ;;
    *)
        INTERFACE="ens5"
        echo "使用默认网口: ens5"
        ;;
esac

echo "已选择网口: $INTERFACE"
echo ""

# 每日限制配置
echo "每日流量限制："
echo "1. 10GB"
echo "2. 15GB (默认)"
echo "3. 20GB"
echo "4. 30GB"
echo "5. 自定义"
echo ""
read -p "请选择 (1-5): " choice

case $choice in
    1)
        DAILY_LIMIT_GB="10"
        ;;
    2)
        DAILY_LIMIT_GB="15"
        ;;
    3)
        DAILY_LIMIT_GB="20"
        ;;
    4)
        DAILY_LIMIT_GB="30"
        ;;
    5)
        read -p "请输入每日限制 (GB): " DAILY_LIMIT_GB
        ;;
    *)
        DAILY_LIMIT_GB="15"
        echo "使用默认限制: 15GB"
        ;;
esac

echo "已设置每日限制: ${DAILY_LIMIT_GB}GB"
echo ""

# 限速配置
echo "限速值设置："
echo "1. 1Mbps"
echo "2. 2Mbps"
echo "3. 3Mbps (默认)"
echo "4. 5Mbps"
echo "5. 自定义"
echo ""
read -p "请选择 (1-5): " choice

case $choice in
    1)
        SPEED_LIMIT_MBPS="1"
        ;;
    2)
        SPEED_LIMIT_MBPS="2"
        ;;
    3)
        SPEED_LIMIT_MBPS="3"
        ;;
    4)
        SPEED_LIMIT_MBPS="5"
        ;;
    5)
        read -p "请输入限速值 (Mbps): " SPEED_LIMIT_MBPS
        ;;
    *)
        SPEED_LIMIT_MBPS="3"
        echo "使用默认限速: 3Mbps"
        ;;
esac

echo "已设置限速值: ${SPEED_LIMIT_MBPS}Mbps"
echo ""

# 确认配置
echo "配置确认："
echo "=================="
echo "网络接口: $INTERFACE"
echo "每日限制: ${DAILY_LIMIT_GB}GB"
echo "限速值: ${SPEED_LIMIT_MBPS}Mbps"
echo ""

read -p "确认保存此配置？(Y/n): " -n 1 -r
echo

if [[ $REPLY =~ ^[Nn]$ ]]; then
    echo "配置已取消"
    exit 1
fi

# 创建配置目录
mkdir -p "$(dirname "$CONFIG_FILE")"

# 保存配置
cat > "$CONFIG_FILE" << EOF
# 流量监控配置文件
# 生成时间: $(date)

INTERFACE=$INTERFACE
DAILY_LIMIT_GB=$DAILY_LIMIT_GB
SPEED_LIMIT_MBPS=$SPEED_LIMIT_MBPS

# 配置说明:
# INTERFACE - 要监控的网络接口名称
# DAILY_LIMIT_GB - 每日流量限制（GB）
# SPEED_LIMIT_MBPS - 超限后的速度限制（Mbps）
EOF

echo ""
echo "✅ 配置已保存到: $CONFIG_FILE"
echo ""
echo "现在可以启动流量监控："
echo "  sudo ./run_background.sh"
