# Helm charts, upgrades and rollback

**Name:** Mayank Gupta
**Roll No:** 24BCS10220
**Repository:** [mayank-0789/Devops-Assignment-1](https://github.com/mayank-0789/Devops-Assignment-1)

## What this lab contains

Lint/template checks for four charts; live notes chart install, replica upgrade and revision rollback.

Top-level resources: `01-helm-commands`, `02-rollback`, `03-mini-project`.

[Detailed adapted walkthrough](REFERENCE.md) · [Source provenance](../SOURCE.md) · [Validation scope](../VALIDATION.md)

The walkthrough retains source example commands and outputs for study. Its historical screenshots were omitted. Workflow names and completion claims in that reference describe the source design; the active workflow in this repository is `.github/workflows/validate-labs.yml`.

## Run the lab

Run these commands from this folder. Use a disposable lab environment. Linux commands need a Linux host; Docker commands need a running Docker engine; Kubernetes/Helm commands need a reachable cluster.

```bash
helm lint 03-mini-project/notes-chart
helm upgrade --install mayank-notes 03-mini-project/notes-chart --wait
helm upgrade mayank-notes 03-mini-project/notes-chart --set replicaCount=2 --wait
helm rollback mayank-notes 1 --wait
helm history mayank-notes
```

## Fresh execution evidence

The **kubernetes** job in [Validate Mayank DevOps labs](https://github.com/mayank-0789/Devops-Assignment-1/actions/workflows/validate-labs.yml) executes the scope above. The screenshot shows actual recorded CI commands/output; it proves only those checks.

![Mayank Gupta — actual lab validation](screenshots/validation.png)

[All screenshot pages](screenshots/) · [Full raw command output](screenshots/validation.log) · [Commit and run metadata](screenshots/validation.json)
