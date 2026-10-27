#!/bin/bash

# --- Operating system name ---
echo "Hostname: $(hostname)"

# --- Current user ---
echo "Current User: $(whoami)"

# --- Date and Time ---
echo "Date and Time: $(date)"

# --- Operating System ---
echo "Operating System: $(uname -s)"

# --- Kernel Version ---
echo "Kernel Version: $(uname -r)"

# --- Uptime ---
echo "Uptime: $(uptime)"

# --- CPU information ---
echo "CPU information: $(sysctl -n machdep.cpu.brand_string 2>/dev/null)"

# --- Memory information ---
echo "Memory information: $(sysctl -n hw.memsize) / 1073741824 )) GiB total"

# --- Current Working Directory ---
echo "Current Working Directory: $(pwd)"
