# 流量监控和限速脚本

一个功能完整的Ubuntu流量监控和自动限速工具，当每日流量达到设定值时自动限速，并在每天0点重置流量统计。

## 🌟 主要功能

- ✅ **实时流量监控** - 每5秒更新一次流量统计
- ✅ **自动限速** - 达到限制时自动限速到指定速度
- ✅ **每日重置** - 每天0点自动重置流量统计
- ✅ **智能配置** - 用户友好的配置向导
- ✅ **后台运行** - 支持SSH断开后继续运行
- ✅ **系统服务** - 支持开机自启动
- ✅ **完整管理** - 启动、停止、重启、状态查看

## 📋 系统要求

- Ubuntu/Debian Linux
- Bash Shell
- root权限
- iproute2包（包含tc和ip命令）
- bc包（数学计算器）

## 🚀 快速开始

### 一键安装和配置

```bash
# 一键安装配置和启动
sudo ./setup.sh
```

这个命令会：
1. 自动检查系统环境
2. 安装必需的软件包
3. 启动配置向导
4. 选择运行模式
5. 自动启动流量监控

### 手动配置

```bash
# 运行配置向导
sudo ./config.sh

# 查看当前配置
sudo ./config.sh show

# 重置配置
sudo ./config.sh reset
```

## 📁 脚本文件说明

### 核心脚本
- **`traffic_monitor.sh`** - 主监控脚本，负责流量监控和限速
- **`config.sh`** - 配置工具，设置网口、流量限制、限速值
- **`setup.sh`** - 一键安装配置向导

### 运行管理
- **`run_background.sh`** - 后台启动工具
- **`manage_traffic.sh`** - 完整管理工具
- **`install_service.sh`** - 系统服务安装

### 备用工具
- **`basic_config.sh`** - 基础配置工具（备用）

## 🔧 配置选项

### 1. 网络接口选择
- ens5 (默认)
- ens3
- ens33
- eth0
- 自定义输入

### 2. 每日流量限制
- 10GB
- 15GB (默认)
- 20GB
- 30GB
- 自定义 (1-1000GB)

### 3. 限速设置
- 1Mbps
- 2Mbps
- 3Mbps (默认)
- 5Mbps
- 自定义 (0.1-100Mbps)

## 🎯 三种运行模式

### 模式1: 后台运行（推荐）

```bash
# 启动后台监控
sudo ./run_background.sh

# 管理命令
sudo ./manage_traffic.sh start    # 启动
sudo ./manage_traffic.sh stop     # 停止
sudo ./manage_traffic.sh status   # 查看状态
sudo ./manage_traffic.sh logs     # 查看日志
sudo ./manage_traffic.sh restart  # 重启
```

### 模式2: 系统服务（生产环境）

```bash
# 安装为系统服务
sudo ./install_service.sh

# 服务管理
sudo systemctl start traffic-monitor    # 启动
sudo systemctl stop traffic-monitor     # 停止
sudo systemctl status traffic-monitor   # 查看状态
sudo journalctl -u traffic-monitor -f   # 查看日志
```

### 模式3: 前台运行（测试用）

```bash
# 前台运行
sudo ./traffic_monitor.sh
```

## 📊 配置示例

### 配置文件格式 (`/etc/traffic_monitor.conf`)

```bash
# 流量监控配置文件
INTERFACE=ens5
DAILY_LIMIT_GB=15
SPEED_LIMIT_MBPS=3
```

### 流量数据格式 (`/tmp/traffic_data.txt`)

```
DATE=2024-01-15
DAILY_RX=4509715456
DAILY_TX=8204816384
LAST_RX=1234567890
LAST_TX=9876543210
```

## 📝 日志示例

### 监控日志 (`/var/log/traffic_monitor.log`)

```
[2024-01-15 10:30:00] [INFO] 已加载配置文件: /etc/traffic_monitor.conf
[2024-01-15 10:30:00] [INFO] 配置参数: 网口=ens5, 每日限制=15GB, 限速=3Mbps
[2024-01-15 10:30:00] [INFO] 开始监控网口 ens5 的流量
[2024-01-15 10:35:00] [INFO] 状态: 正常 | 今日已用: 8.5.2 GB (56%) | RX: 4.2.1 GB | TX: 4.3.1 GB
[2024-01-15 14:45:00] [WARNING] 流量已达到限制! 已使用: 15.0.0 GB
[2024-01-15 14:45:00] [WARNING] 已应用速度限制: 3072kbps (3Mbps)
```

## 🔍 故障排除

### 1. 配置问题

```bash
# 查看当前配置
sudo ./config.sh show

# 重新配置
sudo ./config.sh

# 重置配置
sudo ./config.sh reset
```

### 2. 网口问题

```bash
# 查看所有网口
ip link show

# 查看网口统计
cat /sys/class/net/ens5/statistics/rx_bytes
cat /sys/class/net/ens5/statistics/tx_bytes
```

### 3. 限速问题

```bash
# 查看限速规则
tc qdisc show dev ens5

# 查看限速统计
tc -s qdisc show dev ens5

# 手动移除限速
sudo tc qdisc del dev ens5 root
```

### 4. 服务问题

```bash
# 查看服务状态
sudo systemctl status traffic-monitor

# 查看服务日志
sudo journalctl -u traffic-monitor --no-pager

# 重启服务
sudo systemctl restart traffic-monitor
```

## 📈 性能监控

### 查看流量使用情况

```bash
# 查看今日流量
sudo ./manage_traffic.sh status

# 查看历史日志
sudo tail -n 100 /var/log/traffic_monitor.log
```

### 系统资源使用

```bash
# 查看脚本进程
ps aux | grep traffic_monitor

# 查看内存使用
free -h

# 查看网络状态
ss -tuln
```

## 🔄 升级和维护

### 更新配置

```bash
# 运行配置向导
sudo ./config.sh

# 重启监控以应用新配置
sudo ./manage_traffic.sh restart
```

### 查看运行状态

```bash
# 查看详细状态
sudo ./manage_traffic.sh status

# 实时查看日志
sudo ./manage_traffic.sh follow
```

### 数据备份

```bash
# 备份配置文件
sudo cp /etc/traffic_monitor.conf /backup/

# 备份流量数据
sudo cp /tmp/traffic_data.txt /backup/
```

## ⚠️ 注意事项

1. **权限要求**: 所有脚本都需要root权限运行
2. **配置持久化**: 配置文件保存在 `/etc/` 目录，重启后保留
3. **数据持久化**: 流量数据保存在 `/tmp/` 目录，重启后丢失
4. **网络影响**: tc限速会降低网络速度，请合理设置限速值
5. **日志轮转**: 建议配置日志轮转以避免日志文件过大

## 🆘 技术支持

如果遇到问题，请按以下顺序检查：

1. **配置文件**: `sudo ./config.sh show`
2. **运行状态**: `sudo ./manage_traffic.sh status`
3. **系统日志**: `sudo ./manage_traffic.sh logs`
4. **服务日志**: `sudo journalctl -u traffic-monitor`

## 📄 许可证

此脚本为开源软件，可自由使用和修改。

---

## 🎉 快速使用指南

### 首次使用
```bash
# 1. 一键安装配置
sudo ./setup.sh

# 2. 查看状态
sudo ./manage_traffic.sh status

# 3. 查看日志
sudo ./manage_traffic.sh logs
```

### 日常管理
```bash
# 查看运行状态
sudo ./manage_traffic.sh status

# 实时查看日志
sudo ./manage_traffic.sh follow

# 重启监控
sudo ./manage_traffic.sh restart
```

### 重新配置
```bash
# 修改配置
sudo ./config.sh

# 重启以应用新配置
sudo ./manage_traffic.sh restart
```
