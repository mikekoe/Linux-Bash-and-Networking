#!/bin/bash

THRESHOLD="$1"
TARGET="${2:-/}"

# --- Validate arguments ---
if [ $# -lt 1 ] || [ $# -gt 2 ]; then
    echo "Error: expected 1 or 2 arguments." >&2
    usage
    exit 2
fi

# Threshold: digits only, at most 3 chars, value 1-100
if ! [[ "$THRESHOLD" =~ ^[0-9]{1,3}$ ]]; then
    echo "Error: threshold must be an integer from 1 to 100." >&2
    usage
    exit 2
fi

if [ "$THRESHOLD" -lt 1 ] || [ "$THRESHOLD" -gt 100 ]; then
    echo "Error: threshold must be an integer from 1 to 100." >&2
    usage
    exit 2
fi

if [ ! -e "$TARGET" ]; then
    echo "Error: path '$TARGET' does not exist." >&2
    exit 2
fi

# --- Get disk usage percentage at runtime ---
USAGE="$(df -P "$TARGET" 2>/dev/null | awk 'NR==2 {gsub(/%/,"",$5); print $5}')"

echo "Path: $TARGET"
echo "Disk usage: ${USAGE}%"
echo "Threshold: ${THRESHOLD}%"

if [ "$USAGE" -ge "$THRESHOLD" ]; then
    echo "STATUS: ALERT - usage has reached or exceeded the threshold."
    exit 1
fi
 
echo "STATUS: The Usage is below the threshold."
