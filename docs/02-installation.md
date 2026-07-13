# Installation Guide

## Purpose

> **Engineering Principle**
>
> This guide intentionally separates installation from optimisation.
> No configuration changes are made during installation. The objective
> is to establish a known-good baseline from which future experiments
> can be measured.

This guide documents the complete installation of the Kubernetes observability lab used throughout this repository.

The objective is to provide a reproducible environment that can be used to perform controlled engineering experiments on Prometheus, Grafana and Kubernetes observability.

The installation has been validated on a resource-constrained WSL2 environment and forms the baseline for all subsequent experiments.

---

## Lab Topology

The laboratory consists of:

- Windows 11 host
- WSL2 running Ubuntu 24.04 LTS
- Docker Engine
- KinD Kubernetes cluster (1 control-plane, 2 worker nodes)
- Helm package manager
- kube-prometheus-stack
  - Prometheus
  - Grafana
  - Alertmanager
  - kube-state-metrics
  - node-exporter

---

## Prerequisites

The following software should already be installed before continuing.

### Hardware

- x86-64 system
- Minimum 8 GB RAM (12 GB recommended)
- SSD storage recommended
- Internet connectivity

### Software

- Windows 11
- WSL2
- Ubuntu 24.04 LTS
- Docker Engine
- kubectl
- KinD
- Helm


### Developer Tools

The following utilities are not mandatory but are recommended throughout this project.

- git
- tree
- curl
- jq
- watch
- htop

## Installing Docker

Docker Engine is assumed to be installed and operational before beginning this guide.

Verify the installation:

```bash
docker version
docker info

## Installing KinD

Again, don't duplicate another guide.

```markdown
KinD must already be installed.

Verify:

```bash
kind version


## Creating the Cluster

kind create cluster --config kind-cluster.yaml

A three-node KinD cluster (one control plane and two workers) is used throughout this repository. The cluster configuration is documented in ...

## Installing Helm

helm version

## Installing kube-prometheus-stack

The Kubernetes observability platform is deployed using the
`kube-prometheus-stack` Helm chart.

This chart provides a well-integrated monitoring solution including:

- Prometheus
- Grafana
- Alertmanager
- kube-state-metrics
- node-exporter

Using the Helm chart ensures consistent deployments and simplifies future
upgrades.

### Add the Helm Repository

```bash
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
```

### Update Helm Repositories

```bash
helm repo update
```

### Verify

```bash
helm repo list
```

Expected output should include:

```text
prometheus-community
```

### Install the Monitoring Stack

```bash
helm install monitoring prometheus-community/kube-prometheus-stack \
    --namespace monitoring \
    --create-namespace
```

The deployment may take several minutes while Kubernetes schedules the
pods and pulls the required container images.

## Verification

### Verify Deployment

Check that the Helm release has been created.

```bash
helm list -A
```

Expected:

```text
monitoring
```

Check the pods.

```bash
kubectl get pods -n monitoring
```

Wait until all pods report:

```
STATUS: Running
```

Check the services.

```bash
kubectl get svc -n monitoring
```

## Accessing Grafana

Grafana is deployed as a ClusterIP service and is accessed using Kubernetes port forwarding.

### Port Forward

```bash
kubectl port-forward svc/monitoring-grafana 3000:80 -n monitoring
```

Open your browser:

```
http://localhost:3000
```

### Default Credentials

Retrieve the administrator password:

```bash
kubectl get secret monitoring-grafana \
    -n monitoring \
    -o jsonpath="{.data.admin-password}" | base64 -d
```

Username:

```text
admin
```

---

## Verification

Log in successfully and verify that the Grafana home page is displayed.

## Accessing Prometheus

Prometheus is also exposed using port forwarding.

```bash
kubectl port-forward svc/monitoring-kube-prometheus-prometheus \
    9090:9090 \
    -n monitoring
```

Open:

```
http://localhost:9090
```

---

## Verification

Verify that:

- The Prometheus web interface loads.
- **Status → Targets** reports targets as **UP**.
- Prometheus is collecting metrics.

## Installation Verification Checklist

Before proceeding to the experiments, verify the following:

- Docker is running.
- KinD cluster is healthy.
- All monitoring pods are in the `Running` state.
- Helm reports the monitoring release as deployed.
- Grafana is accessible.
- Prometheus is accessible.
- Kubernetes metrics are being collected.
- Grafana dashboards are loading correctly.

Only once every item above has been verified should the baseline measurements be captured.

## Troubleshooting

This section will grow as additional installation and configuration issues are encountered and resolved during the evolution of the project.

## Common Problems

Examples already include:

Pods stuck in ContainerCreating
Port already in use
Swap file warning in Vim (developer tooling, not Kubernetes)
WSL networking hiccups
Image pull delays
Helm release already exists

Real engineering notes.

## Where to Go Next

Now that the monitoring stack has been successfully installed and verified,
the next phase is to establish a measurable baseline before making any
configuration changes.

Proceed to:

04-baseline.md


## Revision History

| Version | Date | Description |
|----------|------|-------------|
| 0.1 | 2026-07-13 | Initial installation guide |
