# Capability Validation Framework User Guide

**Author:** Kevin Rutenberg  
**Version:** 0.9.0  
**Last Updated:** 01 Aug 2026

---

# Purpose

The Kubernetes Observability Lab health check framework is designed to verify the operational capability of a Kubernetes cluster rather than simply confirming the existence of Kubernetes resources.

The framework provides a consistent, extensible and repeatable mechanism that validates the operational capabilities of both the host environment and the Kubernetes platform through functional testing. 

This repository is not intended to demonstrate Kubernetes commands. It is intended to demonstrate an engineering approach to designing, validating and understanding Kubernetes platforms through observation, experimentation and repeatable operational verification.

---

# Design Goals

The framework was designed around several objectives.

- Simple to execute
- Human readable output
- Repeatable validation
- Minimal external dependencies
- Extensible architecture
- Capability-based testing
- Evidence-driven diagnostics
- Suitable for both learning and operational verification

---

# Framework Architecture

The framework is intentionally data-driven.

Health checks are organised into logical groups:

```
Framework
Host
Cluster
```

Each group is defined as an array containing:

- Description
- Function name

The generic execution engine (`run_check_group()`) executes every check identically, allowing new capability checks to be added without modifying the framework itself.

This keeps the framework simple to extend while maintaining consistent behaviour across all validation routines.

The framework follows a data-driven architecture in which validation definitions are separated from the execution engine. This allows new capability validations to be introduced with minimal changes to the framework itself while maintaining consistent execution, reporting and cleanup behaviour.

---

## Framework Cleanup

The framework is designed to leave the laboratory in a predictable state regardless of whether execution completes successfully, encounters an error or is interrupted by the user.

Temporary resources created during capability validation are automatically removed as part of the framework's cleanup process. Signal handling ensures that cleanup routines execute before the framework exits, helping to prevent orphaned resources from affecting subsequent validation runs.

This behaviour supports repeatable execution while maintaining a consistent laboratory environment.

Cleanup is considered part of the framework's operational lifecycle rather than an optional post-processing step.

---

# Capability-Based Validation

Traditional health checks often verify only that Kubernetes objects exist.

This framework instead validates the capability that consumers rely upon.

For example:

| Traditional Check | Capability Validation |
|-------------------|-----------------------|
| CoreDNS Pod Running | DNS resolution functions |
| StorageClass Exists | Dynamic volume provisioning works |
| Metrics Server Running | Metrics API returns data |
| Nodes Ready | Cluster scheduling available |

Functional validation provides significantly higher confidence than resource existence alone.

---

# Current Capability Coverage

## Framework

- Framework operational

## Host

- Docker daemon reachable
- kubectl available

## Cluster

- Kubernetes API reachable
- All nodes Ready
- Metrics API operational
- CoreDNS operational
- Service networking
- Storage provisioning operational

---

# Execution Timing

Version 0.6.0 introduced execution timing for every capability check.

Each health check reports its execution duration.

Example:

```text
[PASS] Metrics API operational (0.281s)
```

Execution timing serves two purposes:

- Provides visibility into platform responsiveness.
- Creates a performance baseline for future comparison.

Timing information is intended as operational evidence rather than a performance benchmark.

---

# Capability Diagnostics

Certain capability tests perform multiple operational phases internally.

Where useful, these phases are instrumented individually.

Example:

```text
Storage capability validation:

    Cleanup previous
    Create resources
    PVC Bound
    Pod Ready
    Volume write
    Final cleanup
```

This allows the framework to identify where time is actually spent instead of reporting only a single aggregate duration.

---

# Engineering Principles

## Health is layered

Health verification should distinguish between:

- Resource existence
- Component health
- Functional capability

A running Pod does not necessarily indicate that the service it provides is operational.

---

## Validate capability

Health checks should validate the behaviour relied upon by users and workloads rather than assuming a particular Kubernetes implementation.

---

## Measure before optimising

When unexpected behaviour is observed:

1. Instrument the capability.
2. Collect evidence.
3. Identify the cause.
4. Optimise only where justified.

Evidence should always precede optimisation.

---

## Environment-aware design

The framework should discover characteristics of the current Kubernetes environment wherever practical rather than relying upon hard-coded assumptions.

---

# Future Capability Areas

Potential future capability areas include:

- Ingress
- Helm
- Dashboard
- Prometheus
- Grafana
- Persistent application deployment
- Resource pressure simulation
- API performance
- Certificate validation

---

### Service Networking Capability

Purpose:
Validate Kubernetes Service networking by exercising an end-to-end application path.

Validation sequence:
- Create isolated test namespace.
- Deploy a test HTTP application.
- Wait for Pod readiness.
- Create a ClusterIP Service.
- Verify EndpointSlice population.
- Perform an HTTP request from an in-cluster client.
- Validate the expected application response.
- Remove all temporary resources.

This validates:
- Pod scheduling
- Service creation
- EndpointSlice population
- Cluster DNS
- Service routing
- Application connectivity

## Framework Extensibility

New capability validations can be added by implementing the validation function and registering it with the framework's validation definitions.

The existing execution engine, structured result collection, reporting and cleanup behaviour are inherited automatically, allowing the framework to evolve without altering its core operational workflow.

# Design Philosophy

The objective of this framework is not to produce a green "PASS" report.

Its purpose is to improve understanding of Kubernetes behaviour through repeatable operational validation.

The framework should answer not only:

> Is the cluster healthy?

but also:

> Why is it healthy?

and, when appropriate,

> Every validation should increase operational understanding, not merely produce another successful test result. 

## Related Documentation

- `00-project-objectives.md`  
  Defines the project's objectives, scope and engineering philosophy.

- `01-lab-overview.md`  
  Introduces the laboratory and provides a structured guide to the repository.

- `03-architecture.md`  
  Describes the laboratory architecture and how the capability validation framework fits within the overall platform.

- `05-lab-environment.md`  
  Captures the current laboratory environment and software versions generated from the live platform.

- `06-health-check-design.md`  
  Describes the design philosophy, architectural principles and capability validation strategy that underpin the framework.

- `CHANGELOG.md`  
  Summarises significant project milestones, architectural changes and feature evolution.
