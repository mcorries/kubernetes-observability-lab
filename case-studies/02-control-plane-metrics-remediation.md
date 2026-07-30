# Control Plane Metrics Remediation

## Objective

Following completion of the control plane metrics investigation, the engineering decision was made to enhance instrumentation within this KinD-based laboratory by exposing selected control plane metrics endpoints beyond the default loopback interface.

Unlike a production Kubernetes deployment, the primary objective of this laboratory is to maximise platform observability in support of experimentation, operational understanding and repeatable engineering validation.

---

# Implementation

## kube-controller-manager

### Configuration Change

```text
--bind-address=127.0.0.1
```

↓

```text
--bind-address=0.0.0.0
```

### Validation

- Metrics listener confirmed on `*:10257`
- Prometheus target changed from **DOWN** to **UP**
- Cluster Health Framework completed successfully

---

## kube-scheduler

### Configuration Change

```text
--bind-address=127.0.0.1
```

↓

```text
--bind-address=0.0.0.0
```

### Validation

- Metrics listener confirmed on `*:10259`
- Prometheus target changed from **DOWN** to **UP**
- Cluster Health Framework completed successfully

---

## kube-proxy

### Configuration Change

```yaml
metricsBindAddress: ""
```

↓

```yaml
metricsBindAddress: "0.0.0.0:10249"
```

### Validation

- DaemonSet rollout completed successfully
- Metrics listeners confirmed on all cluster nodes
- All Prometheus kube-proxy targets reported **UP**
- Cluster Health Framework completed successfully

---

## etcd

### Configuration Change

```text
--listen-metrics-urls=http://127.0.0.1:2381
```

↓

```text
--listen-metrics-urls=http://0.0.0.0:2381
```

### Operational Observation

Updating the static pod manifest caused the kubelet to restart the etcd pod.

During the restart, the Kubernetes API server temporarily became unavailable while reconnecting to its backing datastore. This resulted in a short-lived `kubectl` timeout before the control plane recovered automatically.

This behaviour was anticipated and required no manual intervention.

### Validation

- Metrics listener confirmed on `*:2381`
- Prometheus etcd target changed from **DOWN** to **UP**
- Kubernetes API recovered automatically
- Cluster Health Framework completed successfully

---

# Overall Validation

Following completion of all configuration changes:

| Component | Metrics Reachable | Prometheus | Platform Validation |
|----------|------------------|------------|---------------------|
| kube-controller-manager | ✅ | UP | PASS |
| kube-scheduler | ✅ | UP | PASS |
| kube-proxy | ✅ | UP | PASS |
| etcd | ✅ | UP | PASS |

The laboratory Health Framework completed successfully with:

```text
PASS : 9
WARN : 0
FAIL : 0
```

No degradation was observed in any validated platform capability.

---

# Persistence Validation

Following implementation, multiple WSL and KinD restarts were performed. During subsequent testing, a full host hardware restart resulted in the KinD control plane node address changing from 172.18.0.3 to 172.18.0.2.

Testing confirmed that KinD automatically updated the dynamic networking parameters within the generated etcd static pod manifest while preserving the custom metrics listener configuration:

```text
--listen-metrics-urls=http://0.0.0.0:2381
```

No manual reconfiguration was required following the control plane IP address change.

Additional validation confirmed:

- Kubernetes Dashboard Metrics Scraper continued operating normally.
- Prometheus continued successfully scraping the etcd metrics endpoint.
- The enhanced instrumentation remained functional after restart.

---

# Engineering Outcome

The remediation successfully transformed the previously unreachable control plane metrics endpoints into fully functional Prometheus scrape targets without introducing observable degradation to validated platform capabilities.

The implementation was performed incrementally, beginning with the lowest operational risk components and concluding with etcd, with full validation completed after every change.

Subsequent lifecycle testing demonstrated that the enhanced metrics configuration remained compatible with KinD's management of the generated static pod manifests under the conditions tested, providing confidence that the instrumentation persists across normal laboratory restart events.

---

# Conclusion

The investigation established that the original **DOWN** Prometheus targets were an expected consequence of the default KinD control plane instrumentation configuration rather than a fault within Kubernetes or Prometheus.

The subsequent implementation demonstrated that exposing the metrics endpoints beyond the loopback interface significantly improves observability within this laboratory while maintaining platform stability and operational correctness.

This implementation therefore aligns with the primary objective of the Kubernetes Observability Lab: maximising platform visibility to support observation, experimentation and repeatable engineering validation.

#### Operational Note

During post-remediation validation an unrelated, transient networking anomaly was observed within the KinD/WSL2 environment. Kubernetes Dashboard (Kong) intermittently returned HTTP 502 responses despite healthy Dashboard API/Auth pods, valid Services and Endpoints, and successful in-cluster connectivity tests from other workloads.

The issue was investigated as a networking datapath anomaly rather than a metrics configuration fault. Following a complete host reboot and normal cluster startup, all monitoring components, Dashboard functionality, Prometheus scrape targets and capability validations returned to normal operation without further configuration changes.

As no reproducible configuration defect was identified, this incident is considered unrelated to the control plane metrics remediation documented above.

Successful remediation should be validated independently of unrelated operational anomalies. Correlation in time should not be assumed to imply causation.
