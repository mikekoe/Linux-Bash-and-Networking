#!/bin/bash

HOST="$1"
PORT="${2:-}"
RC=0
OS_TYPE="$(uname -s)"

# Host: hostname/IPv4 chars (not starting with '-'), or IPv6 (hex and colons)
if ! [[ "$HOST" =~ ^[A-Za-z0-9]([A-Za-z0-9.-]*[A-Za-z0-9])?$ ]] && \
   ! [[ "$HOST" =~ ^[0-9A-Fa-f:]*:[0-9A-Fa-f:]*$ ]]; then
    die_input "'$HOST' is not a valid hostname or IP address."
fi


# Port: digits only, 1-65535
if [ -n "$PORT" ]; then
    if ! [[ "$PORT" =~ ^[0-9]{1,5}$ ]]; then
        die_input "port must be an integer from 1 to 65535."
    fi
    PORT=$((10#$PORT))
    if [ "$PORT" -lt 1 ] || [ "$PORT" -gt 65535 ]; then
        die_input "port must be an integer from 1 to 65535."
    fi
fi

# ---------- Resolve host ----------
resolve_host() {
    local h="$1" ip=""
    if [[ "$h" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]] || [[ "$h" == *:* ]]; then
        echo "$h"; return 0                      # already an IP literal
    fi
    if command -v getent >/dev/null 2>&1; then
        ip="$(getent ahosts "$h" 2>/dev/null | awk 'NR==1 {print $1}')"
    fi
    if [ -z "$ip" ] && command -v dscacheutil >/dev/null 2>&1; then
        ip="$(dscacheutil -q host -a name "$h" 2>/dev/null | awk '/^(ip_address|ipv6_address):/ {print $2; exit}')"
    fi
    if [ -z "$ip" ] && command -v host >/dev/null 2>&1; then
        ip="$(host "$h" 2>/dev/null | awk '/has (IPv6 )?address/ {print $NF; exit}')"
    fi
    [ -n "$ip" ] && echo "$ip"
}

echo "=== Host Resolution ==="
ADDR="$(resolve_host "$HOST")"
if [ -z "$ADDR" ]; then
    echo "Could not resolve '$HOST'."
    exit 1
fi
echo "Host: $HOST"
echo "Resolved address: $ADDR"

# ---------- Connectivity check (ping) ----------
echo
echo "=== Connectivity Check ==="
if command -v ping >/dev/null 2>&1; then
    if [ "$OS_TYPE" = "Darwin" ]; then
        PING_CMD=(ping -c 1 -t 3 "$ADDR")
    else
        PING_CMD=(ping -c 1 -W 3 "$ADDR")
    fi
    if "${PING_CMD[@]}" >/dev/null 2>&1; then
        echo "Ping to $HOST ($ADDR): SUCCESS"
    else
        echo "Ping to $HOST ($ADDR): FAILED (host may block ICMP)"
        RC=1
    fi
else
    echo "ping not installed; skipping."
fi


# ---------- Network interfaces ----------
echo
echo "=== Network Interfaces ==="
if command -v ip >/dev/null 2>&1; then
    ip -brief address 2>/dev/null || ip address
elif command -v ifconfig >/dev/null 2>&1; then
    ifconfig | grep -E '^[a-z0-9]+:|inet ' 
else
    echo "Neither 'ip' nor 'ifconfig' is available."
fi

# ---------- TCP port check ----------
if [ -n "$PORT" ]; then
    echo
    echo "=== TCP Port Check ==="
    if command -v nc >/dev/null 2>&1; then
        nc -z -w 3 "$ADDR" "$PORT" >/dev/null 2>&1
        PORT_RC=$?
    elif command -v timeout >/dev/null 2>&1; then
        timeout 3 bash -c "exec 3<>/dev/tcp/$ADDR/$PORT" >/dev/null 2>&1
        PORT_RC=$?
    else
        echo "No 'nc' or 'timeout' available to test the port."
        exit 1
    fi
    if [ "$PORT_RC" -eq 0 ]; then
        echo "TCP port $PORT on $HOST ($ADDR): OPEN"
    else
        echo "TCP port $PORT on $HOST ($ADDR): CLOSED or unreachable"
        RC=1
    fi
fi

