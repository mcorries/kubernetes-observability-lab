#!/bin/bash

set -euo pipefail

if [ $# -lt 2 ]; then
    echo "Usage: $0 <experiment> <command> [args...]"
    exit 1
fi

EXPERIMENT="$1"
shift

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
LOGDIR="$ROOT/monitoring/baselines/$EXPERIMENT"

mkdir -p "$LOGDIR"

LOGFILE="$LOGDIR/baseline.log"

{
    echo "================================================================="
    echo "$(date '+%F %T')"
    echo "COMMAND: $*"
    echo "================================================================="
} | tee -a "$LOGFILE"

"$@" 2>&1 | tee -a "$LOGFILE"

RC=${PIPESTATUS[0]}

echo | tee -a "$LOGFILE"

exit $RC
