#!/usr/bin/env bash

###############################################################################
# Script : cluster-health-check.sh
# Project: Kubernetes Observability Lab
# Purpose: Validate infrastructure readiness before working with the lab.
#
# Author : Kevin Rutenberg 
###############################################################################

set -o errexit
set -o nounset
set -o pipefail

declare -a RESULT_DESCRIPTION=()
declare -a RESULT_STATUS=()
declare -a RESULT_ELAPSED=()
declare -a RESULT_EVIDENCE=()

PASS_COUNT=0
WARN_COUNT=0
FAIL_COUNT=0
CHECK_EVIDENCE=""
SCRIPT_START=0
SCRIPT_END=0
TIMER_START=0
TARGET="${1:-all}"

###############################################################################
# Framework Configuration
###############################################################################

SCRIPT_VERSION="0.7.1"

BUSYBOX_IMAGE="busybox:1.38"

HEALTHCHECK_POD_PREFIX="lab-health-test"

PVC_NAME="${HEALTHCHECK_POD_PREFIX}-pvc"
POD_NAME="${HEALTHCHECK_POD_PREFIX}-pod"

SERVICE_TEST_NAMESPACE="lab-health-network-test"
SERVICE_DEPLOYMENT="http-echo"
SERVICE_NAME="http-echo"
CLIENT_POD="http-client"

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
    "Service networking operational|check_service_networking"
    "Storage provisioning operational|check_storage"
)


render_pass() {
    local message="$1"
    local detail="${2:-}"

    if [[ -n "$detail" ]]; then
        printf "[PASS] %s (%s)\n" "$message" "$detail"
    else
        printf "[PASS] %s\n" "$message"
    fi

    ((++PASS_COUNT))
}

render_warn() {
    printf "[WARN] %s\n" "$1"
    ((++WARN_COUNT))
}

render_fail() {
    printf "[FAIL] %s\n" "$1"
    ((++FAIL_COUNT))
}

section() {

    echo
    echo "============================================================"
    echo "$1"
    echo "============================================================"
}

timer_start() {

    TIMER_START=$(date +%s%3N)

}

timer_stop() {

    local label="$1"

    local timer_end
    local elapsed_ms

    timer_end=$(date +%s%3N)

    elapsed_ms=$((timer_end - TIMER_START))

    printf "        %-24s %3d.%03ds\n" \
        "$label" \
        $((elapsed_ms / 1000)) \
        $((elapsed_ms % 1000))

}

store_result() {


    local description="$1"
    local status="$2"
    local duration="$3"
    local evidence="$4"

    RESULT_DESCRIPTION+=("$description")
    RESULT_STATUS+=("$status")
    RESULT_ELAPSED+=("$duration")
    RESULT_EVIDENCE+=("$evidence")


}

run_check() {

    start_ms=$(date +%s%3N)

    "$function"
    local rc=$?
     
    end_ms=$(date +%s%3N)
    
    elapsed_ms=$((end_ms - start_ms))
    
    elapsed=$(printf "%d.%03ds" \
        $((elapsed_ms / 1000)) \
        $((elapsed_ms % 1000)))

    case "$rc" in
        0)

          store_result \
            "$description" \
            "PASS" \
            "$elapsed" \
            ""

	  if [[ -n "${CHECK_EVIDENCE:-}" ]]; then

            render_pass "$description" "$elapsed"

            [[ -n "${CHECK_EVIDENCE_1:-}" ]] && \
                printf "       %s\n" "${CHECK_EVIDENCE_1}"

            [[ -n "${CHECK_EVIDENCE_2:-}" ]] && \
                 printf "       %s\n" "${CHECK_EVIDENCE_2}"

            CHECK_EVIDENCE=""
            CHECK_EVIDENCE_1=""
            CHECK_EVIDENCE_2=""

          else
     
            render_pass "$description" "$elapsed" 
	    fi
	    ;;
        1)
            store_result \
            "$description" \
            "WARN" \
            "$elapsed" \
            ""
  
            render_warn "$description" "$elapsed"
            ;;
        *)
            store_result \
            "$description" \
            "FAIL" \
            "$elapsed" \
            "$CHECK_EVIDENCE"

            render_fail "$description" "$elapsed"
            ;;

    esac
}


render_results() {

    echo
    echo "Stored Results"

    local i

    for ((i=0; i<${#RESULT_DESCRIPTION[@]}; i++)); do

        printf "%-35s %-5s %-8s %s\n" \
            "${RESULT_DESCRIPTION[$i]}" \
            "${RESULT_STATUS[$i]}" \
            "${RESULT_ELAPSED[$i]}" \
            "${RESULT_EVIDENCE[$i]}"

    done


}

render_summary() {

    SCRIPT_END=$(date +%s%3N)

    elapsed_ms=$((SCRIPT_END - SCRIPT_START))

    section "Summary"

    printf "PASS : %d\n" "$PASS_COUNT"
    printf "WARN : %d\n" "$WARN_COUNT"
    printf "FAIL : %d\n" "$FAIL_COUNT"
    printf "Time : %d.%03ds\n" \
    $((elapsed_ms / 1000)) \
    $((elapsed_ms % 1000))

    echo
    render_results

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

check_service_networking() {

echo
echo "        Service networking validation:"


timer_start

kubectl create namespace "$SERVICE_TEST_NAMESPACE" \
    --dry-run=client -o yaml | kubectl apply -f - >/dev/null 2>&1

kubectl create deployment "$SERVICE_DEPLOYMENT" \
    --image=hashicorp/http-echo:1.0.0 \
    --namespace "$SERVICE_TEST_NAMESPACE" \
    --dry-run=client -o yaml \
| kubectl apply -f - >/dev/null 2>&1

kubectl patch deployment "$SERVICE_DEPLOYMENT" \
    -n "$SERVICE_TEST_NAMESPACE" \
    --type=json \
    -p='[
      {
        "op":"add",
        "path":"/spec/template/spec/containers/0/args",
        "value":["-text=PASS"]
      }
    ]' >/dev/null 2>&1

timer_stop "Create deployment"

timer_start

kubectl rollout status \
    deployment/"$SERVICE_DEPLOYMENT" \
    -n "$SERVICE_TEST_NAMESPACE" \
    --timeout=60s >/dev/null 2>&1 || return 2

timer_stop "Pod Ready"

timer_start

kubectl expose deployment "$SERVICE_DEPLOYMENT" \
    --namespace "$SERVICE_TEST_NAMESPACE" \
    --name "$SERVICE_NAME" \
    --port=5678 \
    --target-port=5678 \
    >/dev/null 2>&1 || return 2

timer_stop "Create service"

timer_start

for i in {1..30}; do

    endpoint_ip=$(
    kubectl get endpointslices.discovery.k8s.io \
        -n "$SERVICE_TEST_NAMESPACE" \
        -l kubernetes.io/service-name="$SERVICE_NAME" \
        -o jsonpath='{.items[0].endpoints[0].addresses[0]}' \
        2>/dev/null
)

    if [[ -n "$endpoint_ip" ]]; then
        break
    fi

    sleep 1

done

[[ -z "$endpoint_ip" ]] && return 2

timer_stop "Endpoint Ready"



timer_start

response=$(
    kubectl run "$CLIENT_POD" \
        -n "$SERVICE_TEST_NAMESPACE" \
        --image=busybox:1.38 \
        --restart=Never \
        --attach \
        --rm \
        --quiet \
        --command -- \
        wget -qO- "http://$SERVICE_NAME:5678" 2>/dev/null
)

if [[ "$response" != "PASS" ]]; then
    CHECK_EVIDENCE="Expected PASS, received '${response:-<empty>}'"
    return 2
fi


timer_stop "HTTP validation"


timer_start

kubectl delete namespace "$SERVICE_TEST_NAMESPACE" \
    --wait=true \
    >/dev/null 2>&1

timer_stop "Final cleanup"



    echo

    return 0
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

    echo 
    echo "        Storage capability validation:"
    timer_start

    kubectl delete pod "$POD_NAME" \
        --ignore-not-found \
        --wait=true >/dev/null 2>&1

    kubectl delete pvc "$PVC_NAME" \
        --ignore-not-found \
        --wait=true >/dev/null 2>&1

    timer_stop "Cleanup previous"

    timer_start

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

    timer_stop "Create resources"
    
    timer_start
    kubectl wait \
        --for=jsonpath='{.status.phase}'=Bound \
        pvc/${PVC_NAME} \
        --timeout=30s >/dev/null 2>&1 || return 1
    timer_stop "PVC Bound"

    timer_start
    kubectl wait \
        --for=condition=Ready \
        pod/${POD_NAME} \
        --timeout=30s >/dev/null 2>&1 || return 1
    timer_stop "Pod Ready"

    timer_start
    kubectl exec "$POD_NAME" -- \
        sh -c "echo PASS >/data/healthcheck.ok" >/dev/null 2>&1 || return 1
    timer_stop "Volume write"

    timer_start
    kubectl delete pod "$POD_NAME" \
         --ignore-not-found \
         --wait=true >/dev/null 2>&1

    kubectl delete pvc "$PVC_NAME" \
         --ignore-not-found \
         --wait=true >/dev/null 2>&1 || return 1
    
    timer_stop "Final cleanup"

    echo

    CHECK_EVIDENCE="${elapsed}"
    CHECK_EVIDENCE_1="StorageClass: ${DEFAULT_SC}"
    CHECK_EVIDENCE_2="Provisioner : ${STORAGE_PROVISIONER}"

    return 0
}


run_check_group() {

    local checks=("$@")

    for entry in "${checks[@]}"; do
        IFS="|" read -r description function <<< "$entry"

        if [[ "$TARGET" != "all" && \
           "$TARGET" != "$function" && \
           "$TARGET" != "$alias" ]]; then
        continue
        fi

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

    SCRIPT_START=$(date +%s%3N)    

    run_checks

    render_summary

}

main "$@"
