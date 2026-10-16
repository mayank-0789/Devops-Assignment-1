# Security gates

`.github/workflows/capstone.yml` runs:

1. **Bandit** on backend application and migration code (SAST).
2. **pip-audit** on Python runtime requirements and **npm audit** on the frontend lockfile (SCA).
3. **Gitleaks** with full checkout history (secret scanning). PR comments are disabled.
4. **Trivy** on both final runtime images. HIGH and CRITICAL vulnerabilities cause exit code 1, including unfixed findings. Neither image is pushed until the entire image job's scans succeed.

Never weaken the severity threshold simply to make a run green. Update affected dependencies/base images, rerun tests, and retain the scan output. A CVE that cannot be resolved is an explicit blocker for this rubric's security gate.

PR builds never log in or push to GHCR and cannot promote deployments. Only `main` runs can publish. Runtime database credentials are supplied by an existing Kubernetes Secret for GitOps, not tracked values. Local Compose defaults are sample-only credentials.

Release images use full Git commit SHAs. Python requirements currently use bounded version ranges; each new image can resolve newer dependencies. The frontend uses a committed npm lockfile. Review/pin Python transitive dependencies before treating releases as reproducible beyond their built image.

A clean scan means no matching known findings were reported by that tool/database at that time. It does not establish that the application is secure. The app intentionally has no authentication and should only contain classroom sample inventory.

## Evidence

Keep the `stockroom-image-scans` artifact and the job output. Explain what was scanned, the affected package/CVE and remediation (or the scope of the clean scan), in 2–3 sentences. Do not pre-fill a “clean” claim before the current images are scanned.
