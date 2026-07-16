#!/usr/bin/env bash

###############################################################################
# Script : cluster-health-check.sh
# Project: Kubernetes Observability Lab
# Purpose: Validate infrastructure readiness before working with the lab.
#
# Author : Mark Corries
# Version: 0.3.0
###############################################################################

set -o errexit
set -o nounset
set -o pipefail

PASS_COUNT=0
WARN_COUNT=0
FAIL_COUNT=0

pass() {
    printf "[PASS] %s\n" "$1"
    ((++PASS_COUNT))
}

warn() {
    printf "[WARN] %s\n" "$1"
    ((++WARN_COUNT))
}

fail() {
    printf "[FAIL] %s\n" "$1"
    ((++FAIL_COUNT))
}

section() {
    echo
    echo "============================================================"
    echo "$1"
    echo "============================================================"
}

run_check() {

    local description="$1"
    local function="$2"

    "$function"
    local rc=$?

    case "$rc" in
        0)
            pass "$description"
            ;;
        1)
            warn "$description"
            ;;
        *)
            fail "$description"
            ;;
    esac
}


summary() {

    section "Summary"

    printf "PASS : %d\n" "$PASS_COUNT"
    printf "WARN : %d\n" "$WARN_COUNT"
    printf "FAIL : %d\n" "$FAIL_COUNT"

    echo

    if (( FAIL_COUNT > 0 )); then
        exit 2
    elif (( WARN_COUNT > 0 )); then
        exit 1
    else
        exit 0
    fi
}

check_docker() {

    docker info >/dev/null 2>&1

}

check_kubectl() {

    command -v kubectl >/dev/null 2>&1

}

check_apiserver() {

    kubectl cluster-info >/dev/null 2>&1

}

check_framework() {

    return 0

}

check_nodes() {

    local total ready

    total=$(kubectl get nodes --no-headers 2>/dev/null | wc -l)

    ready=$(kubectl get nodes --no-headers 2>/dev/null | grep -c ' Ready ')

    [[ "$total" -eq "$ready" ]]

}

main() {

section "Framework"

run_check "Framework operational" check_framework
	
section "Host"

run_check "Docker daemon reachable" check_docker
run_check "kubectl available" check_kubectl

section "Cluster"

run_check "Kubernetes API reachable" check_apiserver
run_check "All nodes Ready" check_nodes

summary

}

main "$@"
