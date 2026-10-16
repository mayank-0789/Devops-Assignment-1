# Capstone acceptance and evidence

This combines the 100-point rubric with the broader homework document. “Implemented” means source exists; “verified” requires recorded execution. No AWS or cluster completion is claimed here.

| Area | Marks | Current implementation | Evidence still required for submission |
|---|---:|---|---|
| Application | 10 | Original inventory UI; products/movements API; PostgreSQL configuration; Alembic schema | Fresh running UI/API/database screenshot |
| Tests | 10 | More than five tests across more than three endpoints; isolated database; PostgreSQL concurrency smoke in CI | Passing `pytest -v` output and green current-commit CI |
| Git | 5 | Existing personal repository; feature branch; ignores for secrets, environments and build data | Meaningful history showing at least ten genuine commits |
| Docker | 10 | Non-root backend; multi-stage non-root Nginx frontend; PostgreSQL and migration service | Both builds and working full Compose stack |
| CI/CD | 15 | Main/PR workflow; tests → build → scans → GHCR SHA tags → GitOps promotion | Green main run URL, image package pages, actual deployment update |
| Trivy | 5 | Both images scanned; HIGH/CRITICAL findings block publication | Scan output and 2–3 sentence interpretation |
| Terraform | 15 | VPC, two public/private subnets, EKS nodes, EBS CSI IAM, example variables | AWS-backed plan, apply, console views and clean destroy |
| Kubernetes/Helm | 15 | Namespace; two app replicas each; ClusterIP; Ingress; HPA; probes; ConfigMap; Secret; PVC | Running pods/services, Helm release and working Ingress |
| Monitoring | 10 | Instrumented API; ServiceMonitor; Prometheus/Grafana values; dashboard and alerts | Targets UP, populated Grafana panel, metrics output |
| Presentation/docs | 5 | Current README, architecture and runbooks | Live/recorded commit → pipeline → deployment demo |

Additional homework requirements: SAST (Bandit), SCA (pip-audit/npm audit), history secret scanning (Gitleaks), GitOps (Argo CD), logs/metrics, and multiple documented failure/fix scenarios. Configuration is present; capture actual runs.

## Suggested evidence names

Store new evidence under `screenshots/stockroom/` and include the commit SHA/date/run URL in `metadata.json`.

- `application.png`, `postgres-tables.png`, `tests.png`, `commit-history.png`
- `compose.png`, `pipeline.png`, `ghcr-backend.png`, `ghcr-frontend.png`
- `security.txt` plus your scan interpretation
- `terraform-plan.txt`, `aws-vpc.png`, `aws-eks.png`, `terraform-destroy.txt`
- `pods.png`, `services.png`, `helm.png`, `ingress.png`, `hpa-before-after.png`
- `metrics.txt`, `prometheus-targets.png`, `grafana.png`, `argocd-synced.png`
- Troubleshooting logs with before/after results and root-cause explanation

Screenshots of configuration alone do not prove resources are running. Historical TicketHub images are kept for provenance and must not be relabeled.

## Demo order

1. Create a product, receive stock, dispatch stock and show its ledger.
2. Reject a dispatch that would make quantity negative; show PostgreSQL rows.
3. Make a visible UI change, commit it and push to main through review.
4. Show tests/security gates, both SHA-tagged GHCR images and promotion commit.
5. Show Argo CD Synced/Healthy and the changed app through Ingress.
6. Show HPA CPU readings and scaling under load; explain if the workload did not trigger scaling.
7. Show live Prometheus/Grafana metrics and API logs.
8. Diagnose two deliberately broken resources and verify their fixes.
9. After evaluation, clean up cloud resources and capture destruction output.

The due date is not specified in the reviewed sources. The rubric states a five-point deduction for each 24-hour late period. Confirm the actual deadline with the instructor.
