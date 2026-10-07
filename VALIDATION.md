# Validation and evidence

**Student:** Mayank Gupta · **Roll number:** 24BCS10220

The `Validate Mayank DevOps labs` workflow runs reproducible checks on disposable Ubuntu GitHub Actions runners. It captures actual command output and screenshots of that output with student, repository, commit and run metadata. TicketHub and Grafana also receive screenshots of the running browser applications. Imported screenshots are excluded.

| Suite | Checks |
| --- | --- |
| Basics | Linux links, shell script execution, network commands, Git commit/cherry-pick behavior, six Docker applications, multistage build, Docker networking and bind mount |
| Apps | Calculator tests/build/container; DevSecOps tests, Bandit, pip-audit, container and API smoke test |
| Kubernetes | Live kind cluster, nginx pod, deployment update/rollback, ClusterIP connectivity, ConfigMap/Secret-backed application, storage persistence, HPA creation, broken Service selector repair, Helm install/upgrade/rollback |
| Terraform | `fmt -check`, provider/module initialization and `validate` for all three infrastructure projects |
| Capstone | TicketHub API tests, frontend build, PostgreSQL/migrations/backend/frontend via Compose, API smoke tests and browser screenshot; live app/Prometheus/Grafana stack |

A successful run proves only these checks. Kubernetes Ingress controller routing and TLS, measured HPA scaling, registry publishing, Argo CD synchronization and AWS resource creation are not claimed by this validation workflow. The adapted walkthroughs describe those further exercises and contain source example outputs. No cloud credentials have been provided, so this workflow never runs Terraform apply or destroy.

## Reproduce

1. Open [Actions](https://github.com/mayank-0789/Devops-Assignment-1/actions/workflows/validate-labs.yml).
2. Choose **Run workflow** on `main`; select `all` or a single suite for a focused retry.
3. Download the five `mayank-evidence-*` artifacts after completion. Every section includes `validation.log`, `validation.json`, `validation.png` and additional image pages for long logs.
4. Copy each artifact section into the matching lab folder's `screenshots/` directory to refresh the committed evidence. Keep the raw log and metadata beside each image.

The original Section A folders and code are preserved. OCR found another terminal account in their previous screenshots, so those 31 images were removed and the sections now link to fresh CI evidence. Historical output blocks are retained as clearly labeled reference examples.

## Recorded results

Completed on 8 October 2026 (India time). Execution evidence spans two GitHub Actions runs:

| Suite | Result | Evidence run |
| --- | --- | --- |
| Basics | Passed | [Original run](https://github.com/mayank-0789/Devops-Assignment-1/actions/runs/37664487255/job/112940087879) |
| Apps | Passed: 7 calculator tests, 8 DevSecOps API tests, Bandit and dependency audit | [Original run](https://github.com/mayank-0789/Devops-Assignment-1/actions/runs/37664487255/job/112940087910) |
| Kubernetes | Passed: live cluster checks and Helm rollback | [Original run](https://github.com/mayank-0789/Devops-Assignment-1/actions/runs/37664487255/job/112940087952) |
| Terraform | Passed: all 3 configuration projects initialized and validated | [Original run](https://github.com/mayank-0789/Devops-Assignment-1/actions/runs/37664487255/job/112940087590) |
| Capstone | Passed: 10 TicketHub API tests, frontend build, Compose/API smoke tests and both browser captures | [Focused run](https://github.com/mayank-0789/Devops-Assignment-1/actions/runs/37668016962) |

The original run was canceled after its browser dependency installation stalled. Its four completed jobs above passed. The focused capstone retry uses the runner's installed Chrome and bounded commands. Screenshots and raw logs identify their exact tested commit and run; documentation/evidence-only commits do not rerun unchanged application checks.

TicketHub's student card shows Mayank Gupta and 24BCS10220. Static green publish/deploy badges from the reference UI were removed because those actions were not executed. Actual deployment and infrastructure execution limits remain as listed above.
