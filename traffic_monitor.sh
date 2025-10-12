#!/bin/bash
# 流量监控和限速脚本 - Shell版本
# 功能：监控网络流量，当每日流量达到15GB时自动限速到3Mbps

# 配置文件路径
CONFIG_FILE="/etc/traffic_monitor.conf"

# 默认配置参数
DEFAULT_INTERFACE="ens5"
DEFAULT_DAILY_LIMIT_GB=15
DEFAULT_SPEED_LIMIT_MBPS=3

# 其他配置参数
DATA_FILE="/tmp/traffic_data.txt"
LOG_FILE="/var/log/traffic_monitor.log"
CHECK_INTERVAL=5
STATUS_INTERVAL=300  # 5分钟输出一次状态

# 从配置文件加载参数
load_config() {
    if [ -f "$CONFIG_FILE" ]; then
        source "$CONFIG_FILE"
        log "INFO" "已加载配置文件: $CONFIG_FILE"
    else
        log "WARNING" "配置文件不存在，使用默认配置"
        INTERFACE="$DEFAULT_INTERFACE"
        DAILY_LIMIT_GB="$DEFAULT_DAILY_LIMIT_GB"
        SPEED_LIMIT_MBPS="$DEFAULT_SPEED_LIMIT_MBPS"
    fi
    
    # 计算限制值（字节）
    DAILY_LIMIT_BYTES=$(echo "$DAILY_LIMIT_GB * 1024 * 1024 * 1024" | bc)
    SPEED_LIMIT_KBPS=$(echo "$SPEED_LIMIT_MBPS * 1024" | bc)
    
    log "INFO" "配置参数: 网口=$INTERFACE, 每日限制=${DAILY_LIMIT_GB}GB, 限速=${SPEED_LIMIT_MBPS}Mbps"
}

# 全局变量
IS_LIMITED=false
RUNNING=true

# 日志函数
log() {
    local level=$1
    shift
    local message="$*"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[$timestamp] [$level] $message" | tee -a "$LOG_FILE"
}

# 格式化字节显示
format_bytes() {
    local bytes=$1
    local units=("B" "KB" "MB" "GB" "TB")
    local unit_index=0
    
    while [ $bytes -ge 1024 ] && [ $unit_index -lt 4 ]; do
        bytes=$((bytes / 1024))
        unit_index=$((unit_index + 1))
    done
    
    echo "${bytes}.${unit_index} ${units[$unit_index]}"
}

# 获取网络统计信息
get_network_stats() {
    local rx_bytes=0
    local tx_bytes=0
    
    if [ -r "/sys/class/net/$INTERFACE/statistics/rx_bytes" ]; then
        rx_bytes=$(cat "/sys/class/net/$INTERFACE/statistics/rx_bytes")
    else
        log "ERROR" "无法读取网口 $INTERFACE 的接收统计"
        return 1
    fi
    
    if [ -r "/sys/class/net/$INTERFACE/statistics/tx_bytes" ]; then
        tx_bytes=$(cat "/sys/class/net/$INTERFACE/statistics/tx_bytes")
    else
        log "ERROR" "无法读取网口 $INTERFACE 的发送统计"
        return 1
    fi
    
    echo "$rx_bytes $tx_bytes"
}

# 加载每日数据
load_daily_data() {
    local today=$(date '+%Y-%m-%d')
    local daily_rx=0
    local daily_tx=0
    local last_rx=0
    local last_tx=0
    
    if [ -f "$DATA_FILE" ]; then
        while IFS='=' read -r key value; do
            case $key in
                "DATE") saved_date="$value" ;;
                "DAILY_RX") daily_rx="$value" ;;
                "DAILY_TX") daily_tx="$value" ;;
                "LAST_RX") last_rx="$value" ;;
                "LAST_TX") last_tx="$value" ;;
            esac
        done < "$DATA_FILE"
        
        if [ "$saved_date" != "$today" ]; then
            log "INFO" "新的一天开始，重置流量统计 (上次: $saved_date, 今天: $today)"
            daily_rx=0
            daily_tx=0
            last_rx=0
            last_tx=0
        fi
    fi
    
    echo "$daily_rx $daily_tx $last_rx $last_tx"
}

# 保存每日数据
save_daily_data() {
    local daily_rx=$1
    local daily_tx=$2
    local last_rx=$3
    local last_tx=$4
    local today=$(date '+%Y-%m-%d')
    
    cat > "$DATA_FILE" << EOF
DATE=$today
DAILY_RX=$daily_rx
DAILY_TX=$daily_tx
LAST_RX=$last_rx
LAST_TX=$last_tx
EOF
}

# 检查必需的命令是否可用
check_dependencies() {
    local missing_deps=()
    
    # 检查tc命令
    if ! command -v tc >/dev/null 2>&1; then
        missing_deps+=("iproute2 (tc命令)")
    fi
    
    # 检查bc命令
    if ! command -v bc >/dev/null 2>&1; then
        missing_deps+=("bc (计算器)")
    fi
    
    # 检查ip命令
    if ! command -v ip >/dev/null 2>&1; then
        missing_deps+=("iproute2 (ip命令)")
    fi
    
    if [ ${#missing_deps[@]} -gt 0 ]; then
        log "ERROR" "缺少以下依赖包:"
        for dep in "${missing_deps[@]}"; do
            log "ERROR" "  - $dep"
        done
        log "ERROR" "请安装: sudo apt-get install iproute2 bc"
        exit 1
    fi
    
    log "INFO" "所有依赖包已安装"
}

# 应用速度限制
apply_speed_limit() {
    log "WARNING" "开始应用速度限制: ${SPEED_LIMIT_KBPS}kbps (${SPEED_LIMIT_MBPS}Mbps)"
    
    # 删除现有的qdisc
    tc qdisc del dev "$INTERFACE" root 2>/dev/null
    
    # 添加新的qdisc和class
    if tc qdisc add dev "$INTERFACE" root handle 1: htb default 30 2>/dev/null; then
        if tc class add dev "$INTERFACE" parent 1: classid 1:30 htb rate "${SPEED_LIMIT_KBPS}kbit" 2>/dev/null; then
            IS_LIMITED=true
            log "WARNING" "已应用速度限制: ${SPEED_LIMIT_KBPS}kbps (${SPEED_LIMIT_MBPS}Mbps)"
        else
            log "ERROR" "添加限速类失败"
        fi
    else
        log "ERROR" "添加qdisc失败"
    fi
}

# 移除速度限制
remove_speed_limit() {
    if tc qdisc del dev "$INTERFACE" root 2>/dev/null; then
        if [ "$IS_LIMITED" = true ]; then
            IS_LIMITED=false
            log "INFO" "已移除速度限制"
        fi
    fi
}

# 信号处理函数
cleanup() {
    log "INFO" "接收到停止信号，正在清理..."
    RUNNING=false
    remove_speed_limit
    log "INFO" "流量监控已停止"
    exit 0
}

# 设置信号处理
trap cleanup SIGINT SIGTERM

# 检查网口是否存在
check_interface() {
    if ! ip link show "$INTERFACE" >/dev/null 2>&1; then
        log "WARNING" "网口 $INTERFACE 不存在"
        log "INFO" "当前可用网口:"
        ip link show | grep -E "^[0-9]+:" | awk '{print $2}' | sed 's/://' | while read -r iface; do
            log "INFO" "  - $iface"
        done
        log "ERROR" "请检查网口名称配置"
        exit 1
    fi
    log "INFO" "网口 $INTERFACE 存在"
}

# 主监控函数
monitor_traffic() {
    log "INFO" "开始监控网口 $INTERFACE 的流量"
    log "INFO" "每日限制: ${DAILY_LIMIT_GB}GB"
    log "INFO" "限速阈值: ${SPEED_LIMIT_MBPS}Mbps"
    log "INFO" "检查间隔: ${CHECK_INTERVAL}秒"
    
    # 获取初始统计
    local stats=$(get_network_stats)
    local last_rx=$(echo $stats | awk '{print $1}')
    local last_tx=$(echo $stats | awk '{print $2}')
    
    # 加载每日数据
    local daily_data=$(load_daily_data)
    local daily_rx=$(echo $daily_data | awk '{print $1}')
    local daily_tx=$(echo $daily_data | awk '{print $2}')
    
    local start_time=$(date +%s)
    
    while [ "$RUNNING" = true ]; do
        # 获取当前统计
        local current_stats=$(get_network_stats)
        local current_rx=$(echo $current_stats | awk '{print $1}')
        local current_tx=$(echo $current_stats | awk '{print $2}')
        
        # 计算增量（处理计数器重置）
        local rx_diff=$((current_rx - last_rx))
        local tx_diff=$((current_tx - last_tx))
        
        # 确保增量不为负数（处理计数器重置）
        if [ $rx_diff -lt 0 ]; then
            rx_diff=0
        fi
        if [ $tx_diff -lt 0 ]; then
            tx_diff=0
        fi
        
        # 更新每日统计
        daily_rx=$((daily_rx + rx_diff))
        daily_tx=$((daily_tx + tx_diff))
        local total_daily=$((daily_rx + daily_tx))
        
        # 保存数据
        save_daily_data "$daily_rx" "$daily_tx" "$current_rx" "$current_tx"
        
        # 检查是否需要限速
        if [ $total_daily -ge $DAILY_LIMIT_BYTES ] && [ "$IS_LIMITED" = false ]; then
            log "WARNING" "流量已达到限制! 已使用: $(format_bytes $total_daily)"
            apply_speed_limit
        elif [ $total_daily -lt $DAILY_LIMIT_BYTES ] && [ "$IS_LIMITED" = true ]; then
            log "INFO" "流量限制已解除"
            remove_speed_limit
        fi
        
        # 定期输出状态
        local current_time=$(date +%s)
        local elapsed=$((current_time - start_time))
        
        if [ $((elapsed % STATUS_INTERVAL)) -eq 0 ] && [ $elapsed -gt 0 ]; then
            local status="限速中"
            if [ "$IS_LIMITED" = false ]; then
                status="正常"
            fi
            
            local usage_percent=$((total_daily * 100 / DAILY_LIMIT_BYTES))
            log "INFO" "状态: $status | 今日已用: $(format_bytes $total_daily) (${usage_percent}%) | RX: $(format_bytes $daily_rx) | TX: $(format_bytes $daily_tx)"
        fi
        
        # 更新上次统计
        last_rx=$current_rx
        last_tx=$current_tx
        
        # 等待下次检查
        sleep $CHECK_INTERVAL
    done
}

# 主函数
main() {
    echo "流量监控和限速脚本 - Shell版本"
    echo "==============================="
    
    # 检查是否以root权限运行
    if [ "$EUID" -ne 0 ]; then
        echo "错误: 此脚本需要root权限运行"
        echo "请使用: sudo $0"
        exit 1
    fi
    
    # 创建日志目录
    mkdir -p "$(dirname "$LOG_FILE")"
    
    # 加载配置
    load_config
    
    # 检查环境
    check_dependencies
    check_interface
    
    # 开始监控
    monitor_traffic
}

# 运行主函数
main "$@"
