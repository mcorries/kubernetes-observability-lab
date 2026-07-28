# Case Study 01

## Control Plane Metrics Investigation

**Objective**

Investigate why several Prometheus scrape targets reported `DOWN` despite the Kubernetes platform passing all functional health and capability checks.

**Outcome**

The investigation established that the reported failures resulted from the default metrics binding configuration of several control plane components rather than faults within either Kubernetes or the observability stack.

**Status**

Complete

--------------------------

Version: 1.0.0
Status: Complete
Last Updated: 28 July 2026

--------------------------

## Background

This repository is intended to demonstrate an engineering approach to designing, validating and understanding Kubernetes platforms through observation, experimentation and repeatable operational verification.

During validation of the observability stack, Prometheus reported several control plane targets as **DOWN** despite the platform health framework confirming that all validated capabilities remained fully operational.

Rather than treating the monitoring status as a fault requiring immediate remediation, the objective of this investigation was to determine whether the reported failures represented:

- a platform fault,
- an observability stack fault,
- an instrumentation limitation,
- or an intentional implementation decision.

Only after establishing the root cause would any configuration changes be considered.

## Observation

During routine validation of the observability stack, the Prometheus **Status → Target Health** page showed several scrape targets reporting a **DOWN** state.

Inspection of the affected targets showed they corresponded to Kubernetes control plane components, including the kube-controller-manager, kube-scheduler, etcd and kube-proxy.

Each affected target reported a connection failure similar to:

```text
Error scraping target:
Get "https://172.18.0.2:10257/metrics":
dial tcp 172.18.0.2:10257:
connect: connection refused
```
At the same time, the platform health framework continued to report all validated capabilities as operational, creating an apparent discrepancy between platform health and observability.

## Investigation Strategy

Rather than applying configuration changes immediately, the investigation followed the complete telemetry path from Prometheus to the monitored components in order to determine where communication was failing.

Each stage built upon the evidence collected in the previous stage until a single, evidence-supported explanation remained.

The investigation proceeded in the following order:

1. Confirm the reported failures in Prometheus.
2. Verify Prometheus target discovery.
3. Validate Kubernetes Services and EndpointSlices.
4. Confirm endpoint reachability.
5. Inspect the control plane component configuration.
6. Validate the findings against upstream implementation documentation.

### Stage 1 – Confirming the Reported Failures

**Question**

Which targets are failing?

**Command**

```promql
up == 0
```

**Observation**

Only the following scrape targets reported `UP = 0`:

- kube-proxy
- kube-controller-manager
- kube-scheduler
- etcd

All other Prometheus targets were reporting healthy.

**Conclusion**

The failures were limited to a small number of control plane components rather than indicating a wider Prometheus or platform failure.

### Stage 2 – Verifying Target Discovery

**Question**

Is Prometheus discovering the expected Kubernetes objects?

**Commands**

```bash
kubectl get servicemonitor -n monitoring
kubectl get prometheus -n monitoring
```

Additional inspection:

```bash
kubectl get servicemonitor -n monitoring \
  monitoring-kube-prometheus-kubelet -o yaml

kubectl get prometheus -n monitoring \
  monitoring-kube-prometheus-prometheus -o yaml
```

**Observation**

The Prometheus custom resource was correctly configured to discover ServiceMonitors with the expected labels.

The ServiceMonitors for the affected control plane components were present and configured to scrape the expected metrics endpoints.

**Conclusion**

Target discovery was operating correctly. Prometheus was attempting to scrape the intended components.

### Stage 3 – Validating Kubernetes Service Discovery

**Question**

Are the monitored components correctly exposed through Kubernetes Services and EndpointSlices?

**Commands**

```bash
kubectl get svc -n kube-system | \
egrep 'controller|scheduler|etcd|kube-proxy'

kubectl get endpointslice -n kube-system | \
grep kube-proxy

kubectl describe endpointslice \
monitoring-kube-prometheus-kube-proxy-<id> \
-n kube-system
```

**Observation**

The required Services existed for each affected component and exposed the expected metrics ports.

The corresponding EndpointSlices contained the expected node IP addresses and ports, confirming that Kubernetes service discovery was functioning correctly.

All endpoints were reported as **Ready**.

**Conclusion**

The failure was not caused by missing Services, incorrect EndpointSlices or Kubernetes service discovery.

### Stage 4 – Validating Endpoint Reachability

**Question**

Are the advertised metrics endpoints accepting connections on the node addresses published by Kubernetes?

**Commands**

```bash
docker exec kind-control-plane ss -lnt
docker exec kind-worker ss -lnt
docker exec kind-worker2 ss -lnt
```

Relevant output:

```text
LISTEN 127.0.0.1:10249
LISTEN 127.0.0.1:10257
LISTEN 127.0.0.1:10259
LISTEN 127.0.0.1:2381
```

**Observation**

The metrics ports for kube-proxy, kube-controller-manager, kube-scheduler and etcd were listening only on the local loopback interface (`127.0.0.1`).

However, the corresponding Kubernetes Services and EndpointSlices advertised the node IP addresses (`172.18.x.x`) as the scrape targets.

Prometheus therefore attempted to connect to the advertised node IP addresses, where no process was listening on the required metrics ports.

**Conclusion**

The reported connection failures were caused by the metrics endpoints being inaccessible via the advertised node addresses rather than by a failure of Prometheus or Kubernetes service discovery.

### Stage 5 – Inspecting Component Configuration

**Question**

Are the affected components intentionally configured to expose their metrics only on the local loopback interface?

**Commands**

```bash
kubectl -n kube-system get configmap kube-proxy -o yaml | grep metrics

docker exec kind-control-plane \
grep -n "bind-address\|secure-port\|listen" \
/etc/kubernetes/manifests/kube-controller-manager.yaml

docker exec kind-control-plane \
grep -n "bind-address\|secure-port\|listen" \
/etc/kubernetes/manifests/kube-scheduler.yaml

docker exec kind-control-plane \
grep -n "listen\|metrics\|advertise" \
/etc/kubernetes/manifests/etcd.yaml
```

**Relevant Output**

```text
kube-proxy ConfigMap
--------------------
metricsBindAddress: ""

kube-controller-manager
-----------------------
--bind-address=127.0.0.1

kube-scheduler
--------------
--bind-address=127.0.0.1

etcd
----
--listen-metrics-urls=http://127.0.0.1:2381
```

**Observation**

Inspection of the component configuration confirmed that the affected metrics endpoints were intentionally configured to bind only to the local loopback interface.

For kube-proxy, an empty `metricsBindAddress` causes the metrics endpoint to default to `127.0.0.1:10249`.

Similarly, the kube-controller-manager, kube-scheduler and etcd static pod manifests explicitly configured their metrics interfaces to listen only on the localhost interface.

These configuration settings were consistent with the listening sockets observed during the previous stage of the investigation.

**Conclusion**

The reported **DOWN** targets were not caused by a runtime fault. They resulted from the default configuration of the control plane components, which intentionally prevented their metrics endpoints from being reached via the node IP addresses advertised by Kubernetes.

### Stage 6 – Validating Against Upstream Documentation

**Question**

Does the observed behaviour align with the documented implementation of Kubernetes and KinD?

**Sources Consulted**

- Kubernetes component configuration documentation
- KinD known issues and design documentation
- kube-prometheus-stack community discussions relating to control plane metrics

**Observation**

The upstream documentation confirmed that the observed behaviour is intentional.

By default, several Kubernetes control plane components expose their metrics endpoints only on the local loopback interface (`127.0.0.1`) as part of their default security posture. This prevents external access to the metrics endpoints unless the components are explicitly configured to bind to a non-loopback interface.

This behaviour is commonly encountered when deploying observability stacks into local KinD-based environments.

**Conclusion**

The investigation findings were fully consistent with the documented behaviour of Kubernetes and KinD.

The reported **DOWN** targets therefore represented an instrumentation limitation resulting from the default component configuration rather than a fault within either the Kubernetes platform or the observability stack.

## Root Cause

The investigation established that the reported **DOWN** targets were not caused by faults within Prometheus, Kubernetes service discovery or the monitored control plane components.

Instead, the metrics endpoints for the affected components were intentionally configured to bind only to the local loopback interface (`127.0.0.1`). As a result, Prometheus was unable to reach the endpoints via the node addresses advertised by Kubernetes Services and EndpointSlices.

The reported **DOWN** targets were therefore an expected consequence of the default instrumentation configuration.

## Engineering Decision

For this KinD-based observability laboratory, the decision was made to expose the affected metrics endpoints beyond the local loopback interface.

This decision was based on the objectives of the repository rather than production deployment guidance.

The primary objective of the laboratory is to maximise visibility into Kubernetes platform behaviour in order to support observation, experimentation and repeatable operational verification. Enabling these metrics provides more complete telemetry of the control plane without introducing meaningful additional risk within this isolated environment.

The implementation will therefore favour increased platform instrumentation over preservation of the upstream default configuration, with all deviations documented and justified.

## Engineering Principles

This investigation reinforced several engineering principles that underpin this repository.

* Capability

Capability must be demonstrated, not assumed.

* Observability

> **Anything that cannot be observed cannot be confidently understood, verified or troubleshot.**

The conclusions reached during this investigation were only possible because sufficient evidence could be gathered from the running platform. Where instrumentation is absent, engineering conclusions become less certain because critical evidence cannot be collected.

**Therefore, instrumentation must be sufficient to demonstrate capability.**


* Evidence

Engineering decisions should be based on evidence gathered from the running platform rather than assumptions or appearances.

* Documentation

Documentation should be used to validate an engineering conclusion, not to substitute for the investigation that produced it.
