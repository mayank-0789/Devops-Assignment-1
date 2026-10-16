#!/usr/bin/env bash
set -euo pipefail
BASE="${BASE_URL:-http://localhost:8000}"
SECS="${1:-60}"
PAR="${2:-8}"
[[ "$SECS" =~ ^[0-9]+$ && "$PAR" =~ ^[0-9]+$ ]] || { echo 'Use integer duration and concurrency' >&2; exit 2; }
(( SECS >= 1 && SECS <= 600 && PAR >= 1 && PAR <= 64 )) || { echo 'Limits: 1–600 seconds, 1–64 clients' >&2; exit 2; }
END=$((SECONDS + SECS))
worker() {
  while (( SECONDS < END )); do
    curl --fail --silent --show-error --max-time 10 "$BASE/api/products" -o /dev/null || return 1
    curl --fail --silent --show-error --max-time 10 "$BASE/api/products/stats" -o /dev/null || return 1
  done
}
pids=()
trap 'for pid in "${pids[@]}"; do kill "$pid" 2>/dev/null || true; done' EXIT
for (( i=0; i<PAR; i++ )); do worker & pids+=("$!"); done
failed=0
for pid in "${pids[@]}"; do wait "$pid" || failed=1; done
(( failed == 0 )) || { echo 'Load test saw failed requests' >&2; exit 1; }
echo "Completed ${PAR} clients for ${SECS}s; inspect HPA/CPU to establish whether scaling occurred."
