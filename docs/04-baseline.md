**Author:** Kevin Rutenberg  
**Version:** 0.9.0  
**Last Updated:** 01 Aug 2026

**Project:** Kubernetes Observability Lab

---

## Purpose

This document defines the baseline state of the Kubernetes Observability Lab.

The baseline provides a known reference point against which future architectural changes, platform enhancements, performance measurements and engineering experiments can be compared.

Rather than representing a permanent configuration, the baseline captures the laboratory at a specific stage of its evolution, allowing future changes to be evaluated with confidence and supported by documented evidence.


## Baseline Scope

The baseline captures the core characteristics of the laboratory, including:

- Host platform
- Operating environment
- Kubernetes platform
- Core platform services
- Observability platform
- Capability validation status
- Reference operational measurements
- Repository state
- Checkpoint association

Detailed configuration information is maintained separately within the supporting documentation referenced at the end of this document.


## Initial Platform Baseline

The initial baseline represents the laboratory following successful installation, configuration and validation of the core Kubernetes platform.

At this stage, the laboratory provides a stable multi-node Kubernetes environment together with the foundational engineering tooling required to support repeatable experimentation, capability validation and ongoing observability engineering.

The baseline establishes the reference point from which subsequent architectural enhancements and operational capabilities will evolve.


## Baseline Measurements

The baseline should capture objective measurements that can be compared throughout the laboratory's evolution.

Typical baseline measurements include:

- Kubernetes version
- Cluster topology
- Core platform services
- Observability platform components
- Capability validation results
- Environment capture information
- Repository version
- Checkpoint reference
- Performance observations where appropriate

Detailed environment information is maintained in `05-lab-environment.md` and updated independently of this baseline document.


## Maintaining the Baseline

The baseline should remain stable throughout the lifetime of a given architectural milestone.

Rather than modifying historical baselines, significant platform changes should establish a new baseline that documents the laboratory's evolved state while preserving earlier reference points for comparison.
Each documented baseline should correspond to a repository checkpoint where practical, allowing configuration, documentation and platform state to be correlated with a recoverable laboratory snapshot.

This approach provides an auditable record of the laboratory's engineering progression.

## Future Comparisons

Future engineering work should compare new capabilities and architectural changes against the established baseline.

Comparisons may include functional capability, platform behaviour, performance characteristics, resource utilisation and operational workflows.

Documented comparisons help distinguish intentional improvements from unexpected regressions while supporting evidence-based engineering decisions.

- Observability coverage

## Related Documentation

- `00-project-objectives.md`  
  Defines the project's objectives, scope and engineering philosophy.

- `01-lab-overview.md`  
  Introduces the laboratory and provides a structured guide to the repository.

- `02-installation.md`  
  Documents installation, configuration and initial platform verification.

- `03-architecture.md`  
  Describes the laboratory architecture and design principles.

- `05-lab-environment.md`  
  Captures the current laboratory environment and software versions generated from the live platform.

- `06-health-check-design.md`  
  Describes the design philosophy and architecture of the capability validation framework.

- `07-health-check-framework.md`  
  Explains the operation and extensibility of the health check framework.

- `CHANGELOG.md`  
  Summarises significant project milestones, architectural changes and feature evolution.
