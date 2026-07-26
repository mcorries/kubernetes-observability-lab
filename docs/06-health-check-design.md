# Capability Validation Framework Architecture

**Author:** Kevin Rutenberg 
**Version:** 0.8.0
**Last Updated:** 21 July 2026


# Lab Readiness Framework Design 

**Project:** Kubernetes Observability Lab

---

## Purpose

This document describes the design philosophy behind the
`cluster-health-check.sh` framework.

The goal of the framework is **not** simply to verify that Kubernetes
objects exist. Instead, it aims to validate that the lab environment is
fully operational and ready for observability work.

Whenever practical, health checks validate operational capability through functional testing supported by observable evidence, rather than relying on resource existence alone.

---

# Design Principles

## 1. Validate capability, not existence

Avoid checks that merely confirm an object exists.

Example:

❌

```bash
kubectl get deployment metrics-server
```

This only proves the Deployment exists.

Preferred:

```bash
kubectl top nodes
```

This validates the complete Metrics API pipeline.

---

## 2. One responsibility per check

Each check should answer one operational question.

Examples:

| Check | Operational Question |
|--------|----------------------|
| Docker | Is Docker operational? |
| API Server | Can kubectl communicate with the cluster? |
| Nodes | Are all nodes Ready? |
| Metrics | Can Kubernetes serve resource metrics? |
| CoreDNS | Can workloads resolve cluster DNS? |

---

## 3. Functional testing is preferred

Whenever practical, checks should verify the service is functioning.

Example:

Instead of checking whether CoreDNS Pods are running, perform a DNS lookup
from within the cluster.

---

## 4. Minimise assumptions

The framework should assume as little as possible about the user's
environment.

Checks should not depend on:

- pre-deployed utility Pods
- custom namespaces
- third-party tooling

Temporary resources may be created if required and automatically removed
after testing.

---

## 5. Deterministic behaviour

Health checks should produce reliable and repeatable results.

Avoid commands whose behaviour depends on implementation quirks.

Example:

Preferred:

```bash
nslookup kubernetes.default.svc.cluster.local
```

Avoid:

```bash
nslookup kubernetes.default
```

which may behave differently depending on the resolver implementation.

---

## 6. The framework owns the output

Individual health-check functions should not print status messages.

Each function should simply return an exit status.

| Return Code | Meaning |
|-------------|---------|
| 0           | PASS |
| 1           | WARN |
| 2+          | FAIL |

The framework is responsible for displaying results.

---

## 7. Diagnostics follow validation

A failed health check should guide the operator towards the next logical
diagnostic step.

Example:

Metrics API failure

Suggested diagnostics:

```bash
kubectl top nodes

kubectl get pods -n kube-system

kubectl logs deployment/metrics-server -n kube-system
```

---

## 8. Validate capability before remediation

When validation fails:

- Collect evidence
- Understand the capability failure
- Then consider remediation

Not the reverse.

---

## 9. Health != Capability

This deserves its own principle.

Running Pods and Ready Deployments are indicators of resource state, not proof that the capability they provide is operational.

Capability must be exercised to demonstrate that it is functioning as intended.

---

## 10. Implementation Independence

Different Kubernetes implementations may legitimately behave differently.

Frameworks should validate behaviour, not implementation details.

---

## 11. Evidence Collection

Each validation should collect sufficient evidence to explain its conclusion.

Evidence should explain the operational conclusion, not merely report PASS or FAIL.

---

## 12. Framework Extensibility

The framework architecture separates execution logic from validation implementations, allowing new capability checks to be added without modifying the execution engine. 
This encourages incremental growth while maintaining a consistent operational workflow.

---

# Current Capability Coverage

| Capability           | Validation               |
| -------------------- | ------------------------ |
| Docker daemon        | `docker info`            |
| kubectl              | executable availability  |
| Kubernetes API       | `kubectl cluster-info`   |
| Node readiness       | Ready state              |
| Metrics API          | `kubectl top nodes`      |
| CoreDNS              | in-cluster DNS lookup    |
| Service networking   | workload connectivity    |
| Storage provisioning | dynamic PVC/PV lifecycle |

---

# Future Validation Targets

- Cluster capabilities
- Networking
- Storage
- Observability
- Monitoring infrastructure
- CI/CD tooling
- Operational integrations

( Potential validation targets include: 
* CoreDNS
* kube-proxy
* CNI
* StorageClasses
* Persistent Volumes
* Prometheus
* Grafana
* Alertmanager
* Portainer
* Jenkins
)


---

## Architecture

```text
Framework Architecture
        |
        v
Execution Engine
        |
        v
Validation Definitions
        |
        v
Validation Functions
        |
        v
Structured Result Collection
        |
        v
Summary Rendering
```

---

## Lifecycle


```text
Initialisation
        |
        v      
Execute validations
        |
        v      
Collect structured results
        |
        v
Cleanup temporary resources
        |
        v
Render report
        |
        v
Return overall status
```

---

## Long-term Goal

The readiness framework should become the single command executed before
every lab session.

Its purpose is to provide confidence that the complete lab environment is
ready for development, experimentation and operational validation.

---

## Observability Connection

The capability validation framework establishes operational confidence before observability data is interpreted. Observability explains platform behaviour over time; capability validation confirms that the platform is capable of providing the services being observed.


