# Health Check Design

**Author:** Mark Corries
**Version:** 0.7.0
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

Whenever possible, health checks validate **functionality** rather than
resource existence.

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
| 0 | PASS |
| 1 | WARN |
| 2+ | FAIL |

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

# Current Validation Strategy

| Component | Validation Method | Type |
|-----------|-------------------|------|
| Docker | `docker info` | Functional |
| kubectl | `command -v kubectl` | Availability |
| API Server | `kubectl cluster-info` | Functional |
| Nodes | `kubectl get nodes` | Readiness |
| Metrics API | `kubectl top nodes` | Functional |

---

# Future Validation Targets

- CoreDNS
- kube-proxy
- CNI
- StorageClasses
- Persistent Volumes
- Prometheus
- Grafana
- Alertmanager
- Portainer
- Jenkins

---

## Long-term Goal

The readiness framework should become the single command executed before
every lab session.

Its purpose is to provide confidence that the complete lab environment is
ready for development, experimentation and observability testing.
