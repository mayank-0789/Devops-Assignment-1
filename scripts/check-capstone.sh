#!/usr/bin/env bash
source scripts/evidence.sh
capstone_lab() {
 cd "$ROOT/final-devops-project/application/backend"
 python -m venv /tmp/mayank-capstone
 timeout 180 /tmp/mayank-capstone/bin/pip install -r requirements-dev.txt
 timeout 120 /tmp/mayank-capstone/bin/python -m pytest -v -o faulthandler_timeout=30
 cd "$ROOT/final-devops-project/application/frontend"
 timeout 180 npm ci --no-audit --no-fund; timeout 120 npm run build
 cd "$ROOT"
 timeout 600 docker compose -f final-devops-project/docker/docker-compose.yml up -d --build --wait --wait-timeout 240
 curl --fail --connect-timeout 5 --max-time 30 http://localhost:8000/health
 curl --fail --connect-timeout 5 --max-time 30 http://localhost:8000/ready
 CURL_OPTS="--fail --connect-timeout 5 --max-time 30" bash final-devops-project/scripts/seed.sh
 curl --fail --connect-timeout 5 --max-time 30 http://localhost:8000/api/tickets/stats
 curl --fail --connect-timeout 5 --max-time 30 http://localhost:3000 | head -15
 curl --fail --connect-timeout 5 --max-time 30 http://localhost:8000/metrics | head -20 || test "${PIPESTATUS[0]}" = 23
 docker compose -f final-devops-project/docker/docker-compose.yml ps
 pip -q install playwright
 google-chrome --version
 python scripts/capture-app.py capstone http://localhost:3000
 docker compose -f final-devops-project/docker/docker-compose.yml down -v
 echo 'PASS: backend tests, frontend production build, Compose PostgreSQL/migrations/API/frontend stack and ticket seed. EKS/Argo CD/HPA deployment remains a separate exercise.'
}
monitoring_lab() {
 cd "$ROOT"
 timeout 360 docker compose -f session-20-monitoring-gitops/01-monitoring/docker-compose.yml up -d --build
 for _ in $(seq 1 60); do curl -fsS --connect-timeout 5 --max-time 15 http://localhost:8000/health && curl -fsS --connect-timeout 5 --max-time 15 http://localhost:9090/-/ready && curl -fsS --connect-timeout 5 --max-time 15 http://localhost:3000/api/health && break || sleep 3; done
 curl --fail --connect-timeout 5 --max-time 30 http://localhost:8000/
 curl --fail --connect-timeout 5 --max-time 30 http://localhost:8000/metrics | head -20 || test "${PIPESTATUS[0]}" = 23
 sleep 20
 curl --fail --connect-timeout 5 --max-time 30 'http://localhost:9090/api/v1/query?query=up'
 curl --fail --connect-timeout 5 --max-time 30 http://localhost:3000/api/health
 docker compose -f session-20-monitoring-gitops/01-monitoring/docker-compose.yml ps
 python scripts/capture-app.py monitoring http://localhost:3000/d/mayank-s20
 docker compose -f session-20-monitoring-gitops/01-monitoring/docker-compose.yml down -v
 echo 'PASS: app, Prometheus and Grafana live stack. GitOps manifest targets this repository; Argo CD synchronization not exercised.'
}
case "${1:-all}" in
  ticket) evidence final-devops-project capstone_lab ;;
  monitoring) evidence session-20-monitoring-gitops monitoring_lab ;;
  all)
    evidence final-devops-project capstone_lab
    evidence session-20-monitoring-gitops monitoring_lab
    ;;
  *) echo "Usage: $0 [ticket|monitoring|all]" >&2; exit 2 ;;
esac
