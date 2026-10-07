#!/usr/bin/env bash
source scripts/evidence.sh
capstone_lab() {
 cd "$ROOT/final-devops-project/application/backend"
 python -m venv /tmp/mayank-capstone
 /tmp/mayank-capstone/bin/pip -q install -r requirements-dev.txt
 /tmp/mayank-capstone/bin/python -m pytest -v
 cd "$ROOT/final-devops-project/application/frontend"
 npm install --no-audit --no-fund; npm run build
 cd "$ROOT"
 docker compose -f final-devops-project/docker/docker-compose.yml up -d --build --wait --wait-timeout 240
 curl --fail http://localhost:8000/health
 curl --fail http://localhost:8000/ready
 bash final-devops-project/scripts/seed.sh
 curl --fail http://localhost:8000/api/tickets/stats
 curl --fail http://localhost:3000 | head -15
 curl --fail http://localhost:8000/metrics | head -20 || test "${PIPESTATUS[0]}" = 23
 docker compose -f final-devops-project/docker/docker-compose.yml ps
 pip -q install playwright
 python -m playwright install --with-deps chromium >/tmp/mayank-playwright-install.log
 python scripts/capture-app.py capstone http://localhost:3000
 docker compose -f final-devops-project/docker/docker-compose.yml down -v
 echo 'PASS: backend tests, frontend production build, Compose PostgreSQL/migrations/API/frontend stack and ticket seed. EKS/Argo CD/HPA deployment remains a separate exercise.'
}
monitoring_lab() {
 cd "$ROOT"
 docker compose -f session-20-monitoring-gitops/01-monitoring/docker-compose.yml up -d --build
 for _ in $(seq 1 60); do curl -fsS http://localhost:8000/health && curl -fsS http://localhost:9090/-/ready && curl -fsS http://localhost:3000/api/health && break || sleep 3; done
 curl --fail http://localhost:8000/
 curl --fail http://localhost:8000/metrics | head -20 || test "${PIPESTATUS[0]}" = 23
 sleep 20
 curl --fail 'http://localhost:9090/api/v1/query?query=up'
 curl --fail http://localhost:3000/api/health
 docker compose -f session-20-monitoring-gitops/01-monitoring/docker-compose.yml ps
 python scripts/capture-app.py monitoring http://localhost:3000/d/mayank-s20
 docker compose -f session-20-monitoring-gitops/01-monitoring/docker-compose.yml down -v
 echo 'PASS: app, Prometheus and Grafana live stack. GitOps manifest targets this repository; Argo CD synchronization not exercised.'
}
evidence final-devops-project capstone_lab
evidence session-20-monitoring-gitops monitoring_lab
