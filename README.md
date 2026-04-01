# Linux Server Health Monitor & Alert Automation Script

Thi is an interactive Bash script designed to monitor system vitals and provide automated threshold-based alerts for Linux servers.

## 🚀 Features

- **Real-time Health Dashboard**: It allows to check the resources instantly..
- **Continueous Monitoring**: It continuously checks the system's health in the background.
- **Customizable Thresholds**: you can now stay to change the alert limits for the CPU and memory usage, and also the disk space.
- **Automated Logging**: Periodically records alerts to the `monitor_activity.log`.
- **Easy Management**: It is easy to manage logs using the simple terminal-based menu.

## 🛠️ Usage

### Quick Start

1. **Make the script executable**:
   ```bash
   chmod +x server_monitor.sh
   ```

2. **Run the monitor**:
   ```bash
   ./server_monitor.sh
   ```

### Menu Options

- **1. Display current system health**: Immediately snapshots the how much resource is being used at the time.
- **2. Configure monitoring thresholds**: Set or change your limits for the alerts ( the defaults is: CPU 80%, RAM 80%, Disk 90%).
- **3. View activity logs**: Read the `monitor_activity.log` file directly from menu.
- **4. Clear activity logs**: clear log file.
- **5. Start/Stop background monitoring**: Toggles the background process that logs data and alerts every 60 seconds.
- **6. Exit**: Quits the program.

## 📂 Files

- `server_monitor.sh`: The main execution script.
- `monitor_activity.log`: Generated log file containing system checks and alerts.
- `/tmp/server_monitor_bg.pid`: Temporary file to track the background process ID.

## 📋 Prerequisites

- Linux-based operating system.
- Standard utilities: `top`, `free`, `df`, `ps`, `awk`.
