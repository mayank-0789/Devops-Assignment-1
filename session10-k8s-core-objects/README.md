# Kubernetes objects and deployment strategies

**Name:** Mayank Gupta
**Roll No:** 24BCS10220
**Repository:** [mayank-0789/Devops-Assignment-1](https://github.com/mayank-0789/Devops-Assignment-1)

## What this lab contains

nginx Pod execution, deployment rollout, image update and rollback. Further strategies are available as manifests.

Top-level resources: `01-rolling-update`, `02-blue-green`, `03-canary`, `04-recreate`, `daemonset`, `deployment`, `hello.yml`, `k8s-core-objects`, `pod-lifecycle`, `pod.yml`, `replicaset.yml`, `troubleshooting`.

[Detailed adapted walkthrough](REFERENCE.md) · [Source provenance](../SOURCE.md) · [Validation scope](../VALIDATION.md)

The walkthrough retains source example commands and outputs for study. Its historical screenshots were omitted. Workflow names and completion claims in that reference describe the source design; the active workflow in this repository is `.github/workflows/validate-labs.yml`.

## Run the lab

Run these commands from this folder. Use a disposable lab environment. Linux commands need a Linux host; Docker commands need a running Docker engine; Kubernetes/Helm commands need a reachable cluster.

```bash
kubectl apply -f pod.yml
kubectl apply -f deployment/deployment-v1.yaml
kubectl rollout status deployment/web
kubectl apply -f deployment/deployment-v2.yaml
kubectl rollout undo deployment/web
```

## Fresh execution evidence

The **kubernetes** job in [Validate Mayank DevOps labs](https://github.com/mayank-0789/Devops-Assignment-1/actions/workflows/validate-labs.yml) executes the scope above. The screenshot shows actual recorded CI commands/output; it proves only those checks.

![Mayank Gupta — actual lab validation](screenshots/validation.png)

[All screenshot pages](screenshots/) · [Full raw command output](screenshots/validation.log) · [Commit and run metadata](screenshots/validation.json)
