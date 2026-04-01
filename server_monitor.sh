#!/bin/bash

# ==============================================================================
# Linux Server Health Monitoring and Alert Automation Script
# ==============================================================================

# Default threshold values (percentages)
CPU_THRESH=80
MEM_THRESH=80
DISK_THRESH=90

# File paths
LOG_FILE="monitor_activity.log"
PID_FILE="/tmp/server_monitor_bg.pid"



# ==============================================================================
# Metric Extraction Functions
# ==============================================================================

get_cpu_usage() {
    # Extracts idle CPU percentage from top and subtracts from 100
    # Uses a robust regex-like match to handle different versions of 'top'
    top -bn1 | awk '/Cpu\(s\)/ {
        for (i=1; i<=NF; i++) {
            if ($i == "id," || $i == "id" || $i=="id.") {
                print int(100 - $(i-1))
                exit
            }
        }
    }'
}

get_mem_usage() {
    # Extracts memory usage percentage from 'free -m'
    free -m 2>/dev/null | awk '/^Mem:/ { 
        if ($2 > 0) print int($3/$2 * 100); 
        else print 0 
    }'
}

get_disk_usage() {
    # Extracts disk usage percentage for the root partition '/'
    df -h / | awk 'NR==2 {print int($5)}'
}

get_active_procs() {
    # Counts the total number of running processes (subtracting the header)
    ps -e | wc -l | awk '{print $1 - 1}'
}

# ==============================================================================
# Core Features
# ==============================================================================

display_health() {
    echo ""
    echo "========== Current System Health =========="
    
    local cpu=$(get_cpu_usage)
    local mem=$(get_mem_usage)
    local disk=$(get_disk_usage)
    local procs=$(get_active_procs)

    # Output formatting
    printf " %-20s %s%%\n" "CPU Usage:" "${cpu:-N/A}"
    printf " %-20s %s%%\n" "Memory Usage:" "${mem:-N/A}"
    printf " %-20s %s%%\n" "Disk Usage (/):" "${disk:-N/A}"
    printf " %-20s %s\n" "Active Processes:" "${procs:-N/A}"
    echo "==========================================="
    echo ""
}

configure_thresholds() {
    echo ""
    echo "--- Configure Thresholds (Leave blank to keep current) ---"
    
    # Read CPU
    read -p " Enter CPU Threshold % (Current: $CPU_THRESH): " input_cpu
    if [[ "$input_cpu" =~ ^[0-9]+$ ]] && [ "$input_cpu" -ge 1 ] && [ "$input_cpu" -le 100 ]; then
        CPU_THRESH=$input_cpu
    elif [ -n "$input_cpu" ]; then
        echo " Invalid input. CPU Threshold kept at $CPU_THRESH%."
    fi

    # Read Memory
    read -p " Enter Memory Threshold % (Current: $MEM_THRESH): " input_mem
    if [[ "$input_mem" =~ ^[0-9]+$ ]] && [ "$input_mem" -ge 1 ] && [ "$input_mem" -le 100 ]; then
        MEM_THRESH=$input_mem
    elif [ -n "$input_mem" ]; then
        echo " Invalid input. Memory Threshold kept at $MEM_THRESH%."
    fi

    # Read Disk
    read -p " Enter Disk Threshold % (Current: $DISK_THRESH): " input_disk
    if [[ "$input_disk" =~ ^[0-9]+$ ]] && [ "$input_disk" -ge 1 ] && [ "$input_disk" -le 100 ]; then
        DISK_THRESH=$input_disk
    elif [ -n "$input_disk" ]; then
        echo " Invalid input. Disk Threshold kept at $DISK_THRESH%."
    fi
    
    echo "--- Thresholds configuration completed ---"
    
    # If the monitor is currently running, restart it to apply the new variables
    if [ -f "$PID_FILE" ] && kill -0 "$(cat "$PID_FILE")" 2>/dev/null; then
        echo " -> Automatically restarting background monitor to apply new thresholds..."
        toggle_monitoring
        toggle_monitoring
    fi
    echo ""
}

# The loop that runs in the background
background_monitor() {
    while true; do
        local cpu=$(get_cpu_usage)
        local mem=$(get_mem_usage)
        local disk=$(get_disk_usage)
        local procs=$(get_active_procs)
        
        local ts=$(date '+%Y-%m-%d %H:%M:%S')
        
        # Log routine system check
        echo "[$ts] PERIODIC CHECK | CPU: ${cpu:-0}% | RAM: ${mem:-0}% | DISK: ${disk:-0}% | PROCS: ${procs:-0}" >> "$LOG_FILE"
        
        # Log alerts if thresholds are exceeded
        if [ "${cpu:-0}" -ge "$CPU_THRESH" ]; then
            echo "[$ts] ALERT! CPU usage exceeded limit! Current: ${cpu}% (Limit: ${CPU_THRESH}%)" >> "$LOG_FILE"
        fi
        
        if [ "${mem:-0}" -ge "$MEM_THRESH" ]; then
            echo "[$ts] ALERT! Memory usage exceeded limit! Current: ${mem}% (Limit: ${MEM_THRESH}%)" >> "$LOG_FILE"
        fi
        
        if [ "${disk:-0}" -ge "$DISK_THRESH" ]; then
            echo "[$ts] ALERT! Disk usage exceeded limit! Current: ${disk}% (Limit: ${DISK_THRESH}%)" >> "$LOG_FILE"
        fi
        
        # Sleep for defined interval (60 seconds)
        sleep 60
    done
}

toggle_monitoring() {
    if [ -f "$PID_FILE" ] && kill -0 "$(cat "$PID_FILE")" 2>/dev/null; then
        # It's currently running, so stop it
        local pid=$(cat "$PID_FILE")
        kill "$pid" 2>/dev/null
        rm -f "$PID_FILE"
        echo " -> Background monitoring STOPPED (was PID: $pid)."
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] USER ACTION | Monitoring Stopped." >> "$LOG_FILE"
    else
        # It's not running, so start it
        background_monitor &
        local new_pid=$!
        echo "$new_pid" > "$PID_FILE"
        echo " -> Background monitoring STARTED (PID: $new_pid)."
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] USER ACTION | Monitoring Started with Thresholds - CPU: $CPU_THRESH%, RAM: $MEM_THRESH%, DISK: $DISK_THRESH%" >> "$LOG_FILE"
    fi
}

view_logs() {
    if [ -f "$LOG_FILE" ]; then
        echo ""
        echo "========== Displaying Activity Logs =========="
        cat "$LOG_FILE"
        echo "=============================================="
        echo ""
    else
        echo " -> Log file does not exist yet. Start monitoring to generate logs."
    fi
}

clear_logs() {
    > "$LOG_FILE"
    echo " -> Log file cleared successfully."
}

# ==============================================================================
# Interactive Menu
# ==============================================================================
main_menu() {
    while true; do
        # Check if monitor is running for UI display
        local status="[OFF]"
        if [ -f "$PID_FILE" ] && kill -0 "$(cat "$PID_FILE")" 2>/dev/null; then
            status="[ON]"
        fi

        echo ""
        echo "==============================================="
        echo "   Linux Server Health Monitor & Alert Bot     "
        echo "==============================================="
        echo " 1. Display current system health"
        echo " 2. Configure monitoring thresholds"
        echo " 3. View activity logs"
        echo " 4. Clear activity logs"
        echo " 5. Start/Stop background monitoring $status"
        echo " 6. Exit program"
        echo "==============================================="
        read -p " Select an option (1-6): " choice
        
        case $choice in
            1) display_health ;;
            2) configure_thresholds ;;
            3) view_logs ;;
            4) clear_logs ;;
            5) toggle_monitoring ;;
            6) 
                echo "Exiting program... Have a great day!"
                # Optionally, leave background monitor running or stop it.
                # Stopping it to be safe.
                if [ "$status" = "[ON]" ]; then
                    echo "Stopping running background monitor before exit."
                    toggle_monitoring
                fi
                exit 0 
                ;;
            *) 
                echo " Invalid choice. Please select a number between 1 and 6."
                ;;
        esac
    done
}

# ==============================================================================
# Script Initialization
# ==============================================================================


# Start interactive menu
main_menu
