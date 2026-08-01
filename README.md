> **Canonical Repository:** https://github.com/mcorries/kubernetes-observability-lab
>
> This repository is the original source for this project, its documentation, engineering notes and operational framework.

# Kubernetes Observability Lab

A reproducible Kubernetes observability lab built on WSL2 and KinD, documenting the design, implementation, operational validation, instrumentation and engineering investigation of an extensible capability-based validation framework and evolving Kubernetes observability platform. 

---

## Project Overview

This repository documents the development of a lightweight, reproducible Kubernetes laboratory designed to explore platform health, observability and operational engineering.

Rather than focusing on Kubernetes commands in isolation, the project demonstrates how engineering decisions can be validated through repeatable testing, observable evidence and structured operational verification.

The lab is intentionally built from readily available technologies—including Windows 11, WSL2, Docker Engine and KinD—to provide a realistic environment for experimentation without requiring cloud infrastructure.

---

## Engineering Philosophy

> This repository is not intended to demonstrate Kubernetes commands. It is intended to demonstrate an engineering approach to designing, validating and understanding Kubernetes platforms through observation, experimentation and repeatable operational verification.

A running Pod does not necessarily mean the service it provides is operational.

Throughout this project, health is treated as a measurable capability rather than a simple resource state. Each validation is designed to exercise the capability being tested and collect observable evidence supporting the resulting operational conclusion.
Health and capability are intentionally treated as separate concepts. A healthy resource is not, by itself, evidence that the service it provides is operational. Validation should exercise the capability relied upon by users and dependent components.

The emphasis is on understanding:

* **why** a platform is healthy
* **how** that health can be validated
* **what** evidence supports that conclusion
* **how** operational assumptions can be replaced by repeatable verification

---

## Framework Characteristics

The health-check framework developed within this repository is designed around several engineering principles:

* Data-driven framework architecture
* Capability-based validation
* Structured result collection
* Repeatable operational evidence
* Deterministic execution lifecycle
* Automatic resource cleanup
* Interrupt-safe execution
* Extensible validation model

Rather than checking only that Kubernetes resources exist, the framework validates that the services they provide are functioning correctly.

---

## Technology Stack

* Windows 11
* WSL2
* Ubuntu 24.04 LTS
* Docker Engine 29.x
* Kubernetes 1.35
* kubectl 1.36
* KinD 0.31
* Helm 3.x
* Prometheus (current tested release)
* Grafana (current tested release)
* Bash 5.x

The complete software inventory, package versions and environment details used to build this lab are captured in `docs/05-lab-environment.md`, which is regenerated whenever the environment changes.

---

## Current Validation Capabilities

Current framework validation includes:

* Framework operational validation
* Docker daemon availability
* kubectl availability
* Kubernetes API connectivity
* Kubernetes node readiness
* Metrics API validation
* CoreDNS capability validation
* Service networking capability validation
* Dynamic Persistent Volume provisioning validation

Each capability is validated through functional testing rather than simple resource inspection wherever practical.

---

## Repository Structure

```text

kubernetes-observability-lab/
├── docs/                  # Core documentation (Project documentation including Design notes and Engineering decisions)
│   ├── architecture/      # Architecture diagrams
│   ├── experiments/       # Experimental work and prototypes
│   └── reference/         # Supporting reference material
├── monitoring/            # Helm values and monitoring configuration (Prometheus, Grafana, monitoring resources)
├── scripts/               # Health checks and automation (Operational tooling and framework scripts)
├── checkpoints/           # Checkpoint documentation
├── case-studies/          # Engineering investigations and analyses
├── images/
├── README.md
├── CHANGELOG.md
└── LICENSE

```

---

## Engineering Case Studies

The repository includes documented engineering investigations that demonstrate a structured approach to analysing platform behaviour, gathering evidence, validating hypotheses and making evidence-based engineering decisions.

Current case studies include:

- **Case Study 01 – Control Plane Metrics Investigation**
- **Case Study 02 – Control Plane Metrics Remediation**

---

## Project Objectives

The long-term goal is to evolve this repository into a practical reference for Kubernetes operational engineering, covering topics including:

Develop a practical operational engineering reference demonstrating how platform capabilities can be validated, observed, measured and diagnosed using repeatable evidence collected from Kubernetes and its supporting infrastructure.

The emphasis throughout remains understanding platform behaviour rather than simply deploying tooling.

---
## Current Status

### Completed

* Reproducible local Kubernetes laboratory
* Observability platform foundation
* Capability-based health-check framework
* Structured result collection
* Operational lifecycle management
* Interrupt-safe execution
* Evidence-based validation methodology

### In Progress

* Observability integration
* Metrics correlation
* Capability trend analysis
* Operational diagnostics
* Evidence-driven troubleshooting

---

## Documentation

The `docs/` directory contains detailed documentation covering:

* Lab installation
* Environment configuration
* Framework design
* Engineering principles
* Operational validation
* Project evolution

For readers new to the project, `docs/01-lab-overview.md` provides the recommended reading order and a structured introduction to the laboratory, its engineering philosophy and supporting documentation.

---

## License

This project is licensed under the terms of the MIT License. See the `LICENSE` file for details.

