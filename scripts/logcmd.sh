#!/bin/bash

LOG="$HOME/lab-notes/monitoring/baseline/00-initial-install/baseline.log"

echo "==================================================" >> "$LOG"
echo "$(date '+%F %T') : $*" >> "$LOG"
echo "==================================================" >> "$LOG"

"$@" >> "$LOG" 2>&1

echo >> "$LOG"
