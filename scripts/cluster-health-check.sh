#!/usr/bin/env bash

###############################################################################
# Script : cluster-health-check.sh
# Project: Kubernetes Observability Lab
# Purpose: Validate infrastructure readiness before working with the lab.
#
# Author : Mark Corries
# Version: 0.4.0
###############################################################################

set -o errexit
set -o nounset
set -o pipefail

PASS_COUNT=0
WARN_COUNT=0
FAIL_COUNT=0

###############################################################################
# Configuration
###############################################################################

BUSYBOX_IMAGE="busybox:1.38"

SECTIONS=(
    "Framework|FRAMEWORK_CHECKS"
    "Host|HOST_CHECKS"
    "Cluster|CLUSTER_CHECKS"
)

FRAMEWORK_CHECKS=(
    "Framework operational|check_framework"
)

HOST_CHECKS=(
    "Docker daemon reachable|check_docker"
    "kubectl available|check_kubectl"
)

CLUSTER_CHECKS=(
    "Kubernetes API reachable|check_apiserver"
    "All nodes Ready|check_nodes"
    "Metrics API operational|check_metrics_server"
    "CoreDNS operational|check_coredns"
)



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

check_metrics_server() {

    kubectl top nodes >/dev/null 2>&1

}


check_coredns() {

    kubectl run dns-test \
        --rm \
        -i \
        --restart=Never \
        --image="$BUSYBOX_IMAGE" \
        -- nslookup kubernetes.default.svc.cluster.local >/dev/null 2>&1

}


run_check_group() {

    local checks=("$@")

    for entry in "${checks[@]}"; do
        IFS="|" read -r description function <<< "$entry"
        run_check "$description" "$function"
    done
}

run_checks() {

    local section_name
    local registry_name
    local entry

    for entry in "${SECTIONS[@]}"; do
        IFS="|" read -r section_name registry_name <<< "$entry"

        section "$section_name"

        declare -n registry="$registry_name"
        run_check_group "${registry[@]}"
    done
}

main() {

    run_checks

    summary

}

main "$@"
