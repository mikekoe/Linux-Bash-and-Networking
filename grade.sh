#!/bin/bash

PASS=0
FAIL=0
 
pass() { echo "PASS: $1"; PASS=$((PASS+1)); }
fail() { echo "FAIL: $1"; FAIL=$((FAIL+1)); }
 
echo "================================="
echo "Grader"
echo "================================="
 
# Required files
for f in README.md system-info.sh disk-check.sh network-check.sh; do
    [[ -f "$f" ]] && pass "Required file exists: $f" || fail "Missing required file: $f"
done
 
echo "================================="
echo "Passed: $PASS  Failed: $FAIL"
echo "================================="
 
[ "$FAIL" -eq 0 ]
