#!/usr/bin/env bash

# 方法3：使用mpstat命令，记录带时间戳的CPU使用率到文件
log_cpu_usage_mpstat() {
    local log_file="$HOME/cpu.log"

    # 检查mpstat是否安装
    if ! command -v mpstat &>/dev/null; then
        echo "$(date '+%Y-%m-%d %H:%M:%S') - 错误: 请先安装sysstat: sudo apt-get install sysstat" | tee -a "$log_file"
        exit 1
    fi

    # 获取当前时间戳
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')

    # 获取CPU使用率（采样1秒）
    local cpu_usage=$(mpstat 1 1 | awk '/Average:/ && $12 ~ /^[0-9.]+$/ {print 100 - $12}')

    # 如果获取失败，尝试另一种方式
    if [ -z "$cpu_usage" ]; then
        cpu_usage=$(mpstat 1 1 | tail -1 | awk '{print 100 - $NF}')
    fi

    # 格式化输出
    if [ -n "$cpu_usage" ]; then
        local log_entry="$timestamp - CPU使用率: ${cpu_usage}%"
        echo "$log_entry" | tee -a "$log_file"
    else
        echo "$timestamp - 错误: 无法获取CPU使用率" | tee -a "$log_file"
    fi
}

# 持续监控版本（可选）
monitor_cpu_mpstat() {
    local interval=${1:-5} # 监控间隔，默认5秒
    local log_file="$HOME/cpu.log"

    echo "开始监控CPU使用率，间隔${interval}秒..."
    echo "日志文件: $log_file"
    echo "按Ctrl+C停止监控"
    echo "------------------------"

    # 检查mpstat是否安装
    if ! command -v mpstat &>/dev/null; then
        echo "$(date '+%Y-%m-%d %H:%M:%S') - 错误: 请先安装sysstat: sudo apt-get install sysstat" | tee -a "$log_file"
        exit 1
    fi

    # 创建日志文件（如果不存在）
    touch "$log_file"

    # 写入启动信息
    echo "$(date '+%Y-%m-%d %H:%M:%S') - CPU监控启动，间隔${interval}秒" >>"$log_file"

    # 监控循环
    while true; do
        # 记录循环开始时间
        local loop_start=$(date +%s)
        local timestamp=$(date '+%Y-%m-%d %H:%M:%S')

        # 使用mpstat获取CPU使用率，采样1秒
        local cpu_usage=$(mpstat 1 1 | awk '/Average:/ && $12 ~ /^[0-9.]+$/ {print 100 - $12}')

        if [ -z "$cpu_usage" ]; then
            cpu_usage=$(mpstat 1 1 | tail -1 | awk '{print 100 - $NF}')
        fi

        if [ -n "$cpu_usage" ]; then
            # 格式化CPU使用率（保留2位小数）
            cpu_usage=$(printf "%.2f" "$cpu_usage")

            # 创建日志条目
            local log_entry="$timestamp - CPU使用率: ${cpu_usage}%"

            # 输出到屏幕并记录到文件
            echo "$log_entry" | tee -a "$log_file"
        else
            echo "$timestamp - 错误: 无法获取CPU使用率" | tee -a "$log_file"
        fi

        # 计算需要睡眠的时间
        local loop_end=$(date +%s)
        local elapsed=$((loop_end - loop_start))
        local sleep_time=$((interval - elapsed))

        # 确保sleep_time不为负数
        if [ $sleep_time -gt 0 ]; then
            sleep $sleep_time
        else
            # 如果执行时间超过了间隔，立即开始下一次循环
            echo "$(date '+%Y-%m-%d %H:%M:%S') - 警告: 采集超时，跳过等待" | tee -a "$log_file"
        fi
    done
}


# 单次运行版本（简单）
single_run_mpstat() {
    local log_file="$HOME/cpu.log"

    # 检查mpstat是否安装
    if ! command -v mpstat &>/dev/null; then
        echo "错误: 请先安装sysstat: sudo apt-get install sysstat"
        echo "Ubuntu/Debian: sudo apt-get install sysstat"
        echo "CentOS/RHEL: sudo yum install sysstat"
        echo "Arch: sudo pacman -S sysstat"
        exit 1
    fi

    # 获取CPU使用率
    local cpu_usage=$(mpstat 1 1 | awk '/Average:/ && $12 ~ /^[0-9.]+$/ {print 100 - $12}')

    if [ -z "$cpu_usage" ]; then
        cpu_usage=$(mpstat 1 1 | tail -1 | awk '{print 100 - $NF}')
    fi

    # 格式化输出
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    if [ -n "$cpu_usage" ]; then
        # 保留2位小数
        cpu_usage=$(printf "%.2f" "$cpu_usage")
        local log_entry="$timestamp - CPU使用率: ${cpu_usage}%"

        # 输出到屏幕并追加到日志文件
        echo "$log_entry"
        echo "$log_entry" >>"$log_file"
    else
        local error_msg="$timestamp - 错误: 无法获取CPU使用率"
        echo "$error_msg"
        echo "$error_msg" >>"$log_file"
    fi
}

# 检查日志文件并显示最近记录
show_recent_logs() {
    local log_file="$HOME/cpu.log"

    if [ -f "$log_file" ]; then
        echo "最近10条CPU使用率记录:"
        echo "------------------------"
        tail -10 "$log_file"
        echo "------------------------"
        echo "日志文件: $log_file"
        echo "总记录数: $(wc -l <"$log_file")"
    else
        echo "日志文件不存在: $log_file"
    fi
}

# 主函数
main() {
    # 如果没有参数，使用单次运行模式
    if [ $# -eq 0 ]; then
        single_run_mpstat
        exit 0
    fi

    # 处理参数
    case "$1" in
    "monitor")
        # 持续监控模式
        monitor_cpu_mpstat "${2:-5}"
        ;;
    "single")
        # 单次运行
        single_run_mpstat
        ;;
    "log")
        # 查看日志
        show_recent_logs
        ;;
    "install")
        # 安装sysstat
        echo "正在安装sysstat..."
        if command -v apt-get &>/dev/null; then
            sudo apt-get update && sudo apt-get install -y sysstat
        elif command -v yum &>/dev/null; then
            sudo yum install -y sysstat
        elif command -v dnf &>/dev/null; then
            sudo dnf install -y sysstat
        elif command -v pacman &>/dev/null; then
            sudo pacman -S --noconfirm sysstat
        else
            echo "无法确定包管理器，请手动安装sysstat"
            exit 1
        fi
        echo "sysstat安装完成！"
        ;;
    "help")
        # 显示帮助
        echo "使用方法: $0 [选项]"
        echo ""
        echo "选项:"
        echo "  (无参数)    单次运行并记录CPU使用率"
        echo "  monitor [间隔]  持续监控模式，可选间隔秒数（默认5秒）"
        echo "  single        单次运行模式"
        echo "  log           显示最近10条记录"
        echo "  install       安装sysstat工具"
        echo "  help          显示此帮助信息"
        echo ""
        echo "示例:"
        echo "  $0               # 单次记录CPU使用率"
        echo "  $0 monitor 10    # 每10秒记录一次CPU使用率"
        echo "  $0 monitor       # 每5秒记录一次CPU使用率"
        echo "  $0 log           # 查看最近的CPU使用率记录"
        ;;
    *)
        echo "未知选项: $1"
        echo "使用 '$0 help' 查看帮助"
        exit 1
        ;;
    esac
}

# 运行主函数
main "$@"
