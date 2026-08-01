# Project Checkpoints

This directory contains the engineering checkpoints for the **Kubernetes Observability Lab**.

A checkpoint represents a **known-good engineering milestone** in the project's evolution. Each checkpoint combines a stable Git commit, documented engineering notes and an associated WSL environment export, providing a reproducible snapshot of both the source code and the operational laboratory environment.

Unlike a traditional changelog, checkpoints record not only **what** changed, but also **why** those changes were made, the engineering decisions behind them and the objectives for the next phase of development.

The associated WSL export archives are stored outside of this repository due to their size. Each checkpoint document records the corresponding archive filename, allowing the repository state and recoverable laboratory environment to be correlated.

---

## Purpose

The checkpoint system exists to:

* Preserve known-good engineering milestones.
* Associate Git commits with reproducible WSL environment exports.
* Record the rationale behind significant architectural decisions.
* Provide documented recovery points throughout the project's evolution.
* Maintain an engineering history rather than simply a backup history.

---

## Checkpoint Structure

Each checkpoint document records:

* Checkpoint identifier
* Date
* Git branch
* Git commit
* Engineering summary
* Significant changes since the previous checkpoint
* Engineering rationale
* Known-good operational state
* Associated WSL export filename 
* Objectives for the next development phase

---

## Checkpoint Index

| Checkpoint | Date | Description | Status |
| ---------- | ----------- | ---------------------------------------------- | -------- |
| CP-02 | 26 Jul 2026 | Framework Lifecycle | Archived |
| CP-03 | 29 Jul 2026 | Pre-metrics endpoint scrape change | Current |

> As new checkpoints are created, append them to this table and update the previous checkpoint status from **Current** to **Archived**.

---

## Engineering Philosophy

Checkpoints are intended to capture **engineering milestones**, not merely software backups.

Each checkpoint documents:

* the state of the source code;
* the architecture of the capability validation framework;
* the operational state of the laboratory;
* the engineering decisions leading to that milestone;
* the direction of the project beyond that point.

Together with the associated WSL environment export, these checkpoint documents provide a complete, reproducible record of the project's evolution, allowing previous known-good states to be restored, reviewed and understood.

This approach ensures that every significant milestone can be reproduced, validated and explained—not simply recovered.

Checkpoints establish engineering baselines from which subsequent platform changes, investigations and observability enhancements can be measured and evaluated.
