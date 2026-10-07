#!/usr/bin/env bash
set -euo pipefail
ROOT=$(git rev-parse --show-toplevel)
cd "$ROOT"
# Capture actual commands/output. A nonzero check fails the job and remains in its log.
evidence() {
  local section="$1"; shift
  mkdir -p "evidence/$section"
  (
    set -euo pipefail
    echo "Mayank Gupta | 24BCS10220 | mayank-0789/Devops-Assignment-1"
    echo "Scope: $section"
    echo "Commit: $(git rev-parse HEAD)"
    echo "UTC: $(date -u +%FT%TZ)"
    echo "Run: https://github.com/$GITHUB_REPOSITORY/actions/runs/$GITHUB_RUN_ID"
    set -x
    "$@"
  ) 2>&1 | tee "evidence/$section/validation.log"
}
