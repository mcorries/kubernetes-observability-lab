#!/usr/bin/env bash

###############################################################################
# Script : cluster-health-check.sh
# Project: Kubernetes Observability Lab
# Purpose: Validate infrastructure readiness before working with the lab.
#
# Author : Mark Corries
# Version: 0.5.0
###############################################################################

set -o errexit
set -o nounset
set -o pipefail

PASS_COUNT=0
WARN_COUNT=0
FAIL_COUNT=0
CHECK_MESSAGE=""

###############################################################################
# Framework Configuration
###############################################################################

SCRIPT_VERSION="0.5.0"

BUSYBOX_IMAGE="busybox:1.38"

HEALTHCHECK_POD_PREFIX="lab-health-test"

PVC_NAME="${HEALTHCHECK_POD_PREFIX}-pvc"
POD_NAME="${HEALTHCHECK_POD_PREFIX}-pod"

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
    "Storage provisioning operational|check_storage"
)


pass() {
    local message="$1"
    local detail="${2:-}"

    if [[ -n "$detail" ]]; then
        printf "[PASS] %s (%s)\n" "$message" "$detail"
    else
        printf "[PASS] %s\n" "$message"
    fi

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
            if [[ -n "${CHECK_MESSAGE:-}" ]]; then
                pass "$description (${CHECK_MESSAGE})"
                CHECK_MESSAGE=""
	    else
	        pass "$description"
	    fi
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

local pod_name="${HEALTHCHECK_POD_PREFIX}-dns"

kubectl run "$pod_name" \
        --rm \
        -i \
        --restart=Never \
        --image="$BUSYBOX_IMAGE" \
        -- nslookup kubernetes.default.svc.cluster.local >/dev/null 2>&1

}


check_storage() {

DEFAULT_SC=$(
    kubectl get storageclass \
        -o jsonpath='{range .items[?(@.metadata.annotations.storageclass\.kubernetes\.io/is-default-class=="true")]}{.metadata.name}{end}'
)

[[ -z "$DEFAULT_SC" ]] && return 1

STORAGE_PROVISIONER=$(
        kubectl get storageclass "$DEFAULT_SC" \
            -o jsonpath='{.provisioner}'
)


    kubectl delete pod "$POD_NAME" \
        --ignore-not-found \
        --wait=true >/dev/null 2>&1

    kubectl delete pvc "$PVC_NAME" \
        --ignore-not-found \
        --wait=true >/dev/null 2>&1

    kubectl apply -f - >/dev/null <<EOF
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: ${PVC_NAME}
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 64Mi
  storageClassName: ${DEFAULT_SC}
---
apiVersion: v1
kind: Pod
metadata:
  name: ${POD_NAME}
spec:
  restartPolicy: Never
  containers:
  - name: busybox
    image: ${BUSYBOX_IMAGE}
    command: ["sh","-c","sleep 60"]
    volumeMounts:
    - name: storage
      mountPath: /data
  volumes:
  - name: storage
    persistentVolumeClaim:
      claimName: ${PVC_NAME}
EOF

    kubectl wait \
        --for=jsonpath='{.status.phase}'=Bound \
        pvc/${PVC_NAME} \
        --timeout=30s >/dev/null 2>&1 || return 1

    kubectl wait \
        --for=condition=Ready \
        pod/${POD_NAME} \
        --timeout=30s >/dev/null 2>&1 || return 1

    kubectl exec "$POD_NAME" -- \
        sh -c "echo PASS >/data/healthcheck.ok" >/dev/null 2>&1 || return 1

    kubectl delete pod "$POD_NAME" \
         --ignore-not-found \
         --wait=true >/dev/null 2>&1

    kubectl delete pvc "$PVC_NAME" \
         --ignore-not-found \
         --wait=true >/dev/null 2>&1 || return 1

    CHECK_MESSAGE="StorageClass: ${DEFAULT_SC}, Provisioner: ${STORAGE_PROVISIONER}"

    return 0
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
