# Linux Bash and Networking

A small collection of Bash scripts for system information, disk monitoring and
basic network diagnostics. All scripts share one logging helper that records
every run to a log file inside the repository.

Works on **Linux** and **macOS** (Bash 3.2 or newer).

## Contents

| File | Purpose |
|------|---------|
| `sysinfo.sh` | Display hostname, user, date/time, OS, kernel, uptime, CPU, memory and working directory |
| `disk-check.sh` | Check disk usage against a threshold and exit with a status code |
| `net-check.sh` | Validate a host, resolve it, check connectivity, show interfaces and optionally test a TCP port |
| `logger.sh` | Shared logging helper used by all three scripts (sourced, not run directly) |
| `logs/` | Log output folder (`scripts.log`) |

## Repository layout

```
.
├── README.md
├── logger.sh        # must sit in the same folder as the scripts
├── sysinfo.sh
├── disk-check.sh
├── net-check.sh
└── logs/
    ├── README.md
    └── scripts.log  # created automatically on the first run
```

> `logger.sh` must be in the **same folder as the scripts**, not inside `logs/`.
> If it is missing, the scripts still run but print a warning and do not log.

## Setup

```bash
git clone <your-repo-url>
cd Linux-Bash-and-Networking
chmod +x *.sh
```

No extra packages are required. The scripts use standard tools and fall back
gracefully when an optional tool is missing.

## Scripts

### sysinfo.sh

Displays system information gathered at runtime.

```bash
./sysinfo.sh
```

Shows: hostname, current user, date/time, operating system, kernel version,
uptime, CPU (model, cores, architecture), memory (total, used, available) and
the current working directory.

| Platform | How values are collected |
|----------|--------------------------|
| Linux | `/etc/os-release`, `/proc/uptime`, `/proc/cpuinfo`, `/proc/meminfo` |
| macOS | `sw_vers`, `sysctl`, `vm_stat` (there is no `/proc` on macOS) |

Exit code: `0`.

### disk-check.sh

Compares disk usage of a path against a threshold.

```bash
./disk-check.sh <threshold> [path]

./disk-check.sh 80          # checks / (default path)
./disk-check.sh 80 /home    # checks /home
```

| Argument | Description |
|----------|-------------|
| `threshold` | Integer from 1 to 100 (percent). Required. |
| `path` | Path to check. Optional, defaults to `/`. |

Prints the path, the disk usage percentage and the threshold.

| Exit code | Meaning |
|-----------|---------|
| `0` | Usage is below the threshold |
| `1` | Usage reaches or exceeds the threshold |
| `2` | Invalid input (bad threshold, missing path, wrong number of arguments) |

Use it in cron jobs or pipelines:

```bash
./disk-check.sh 80 || echo "Disk alert!"
```

### net-check.sh

Runs basic network diagnostics for a host and an optional TCP port.

```bash
./net-check.sh <host> [port]

./net-check.sh google.com
./net-check.sh google.com 443
./net-check.sh 192.168.1.1 22
```

| Argument | Description |
|----------|-------------|
| `host` | Hostname, IPv4 address or IPv6 address. Required. |
| `port` | TCP port from 1 to 65535. Optional. |

Steps, in order:

1. **Validate input:** the host and port are checked before anything runs.
2. **Resolve the host:** prints the resolved address (`getent`, `dscacheutil` or `host`).
3. **Connectivity check:** one `ping`.
4. **Network interfaces:** `ip -brief address`, or `ifconfig` on macOS.
5. **TCP port check:** only if a port is given (`nc -z`, or bash `/dev/tcp`).

| Exit code | Meaning |
|-----------|---------|
| `0` | All checks passed |
| `1` | A check failed (host did not resolve, ping failed, port closed) |
| `2` | Invalid input |

> A failed ping does not always mean the host is down, because many hosts block
> ICMP. The port check is often the more reliable test.

## Logging

All three scripts log through `logger.sh`. Each run appends to a single file:

```
logs/scripts.log
```

### Entry format

```
YYYY-MM-DD HH:MM:SS +ZZZZ [LEVEL] [script-name] [PID] description
```

Example:

```
2026-10-27 13:48:05 +0000 [INFO]  [disk-check.sh] [145] Disk usage for '/' is 47% (threshold 80%)
2026-10-27 13:48:05 +0000 [ERROR] [disk-check.sh] [169] Input validation failed: threshold must be an integer from 1 to 100.
2026-10-27 13:48:05 +0000 [WARN]  [net-check.sh]  [186] TCP port 22 on localhost (127.0.0.1) is CLOSED or unreachable
```

### Levels

| Level | Meaning |
|-------|---------|
| `INFO` | Normal progress: validation passed, a value was collected, a check succeeded |
| `WARN` | A check failed or a tool was missing, but the script continued |
| `ERROR` | Invalid input, or a failure that stopped the run |

### What is logged

Every run records:

- the start of the run: platform, user, working directory and arguments
- each validation step, and the reason for any rejection
- each major operation (resolution, ping, interface display, port check, disk read, system info collection)
- the final exit code, including runs that end early on invalid input

### Log location

`logger.sh` picks the log folder in this order:

1. `$LOG_DIR`, if set in the environment
2. `<git repository root>/logs`
3. a `logs/` folder next to `logger.sh` (when not inside a git repo)

Because the repo root is detected through git, logs go to the same place no
matter which directory you run a script from.

```bash
LOG_DIR=/var/tmp/mylogs ./disk-check.sh 80    # custom log folder
```

### Useful commands

```bash
tail -f logs/scripts.log                        # follow the log live
grep '\[net-check.sh\]' logs/scripts.log        # one script only
grep -E '\[(WARN|ERROR)\]' logs/scripts.log     # problems only
grep 'exit code 2' logs/scripts.log             # runs that failed on invalid input
```

### If logging cannot write

If the log folder cannot be created or written to, the script prints one
warning to stderr and continues without logging. Logging never stops a script
from doing its job.

### Committing logs

The `logs/` folder is part of the repository. To publish your run history:

```bash
git add logs/
git commit -m "Add script logs"
git push
```

`scripts.log` grows with every run. Trim it with `> logs/scripts.log`, or use
`logrotate`, if it becomes too large. If you do not want logs committed, add
`logs/scripts.log` to `.gitignore`.

## Troubleshooting

| Problem | Cause and fix |
|---------|---------------|
| `Permission denied` when running a script | Run `chmod +x *.sh` |
| `Warning: logger.sh not found; logging disabled.` | Put `logger.sh` in the same folder as the scripts |
| `/proc/uptime: No such file or directory` on a Mac | You are running an older Linux-only version. Use the current `sysinfo.sh`, which handles macOS |
| `disk-check.sh 60 checks` reports invalid input | The second argument is a **path**, not a label. Use `./disk-check.sh 60` or `./disk-check.sh 60 /some/path` |
| `net-check.sh` shows "ping not installed" or "No tool available to display network interfaces" | The tool is missing on that system. The script logs a warning and continues |
| Ping fails but the host is up | The host probably blocks ICMP. Use the port check, for example `./net-check.sh host 443` |

## Quick test of the exit codes

```bash
./disk-check.sh 100; echo "exit=$?"     # 0 (below threshold)
./disk-check.sh 1;   echo "exit=$?"     # 1 (at or above threshold)
./disk-check.sh 101; echo "exit=$?"     # 2 (invalid input)
./net-check.sh "bad host!"; echo "exit=$?"   # 2 (invalid input)
```
