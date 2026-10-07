#!/usr/bin/env bash
source scripts/evidence.sh
calculator() {
  cd "$ROOT/session-16-cicd"
  python -m venv /tmp/mayank-calc
  /tmp/mayank-calc/bin/pip -q install -r requirements.txt
  /tmp/mayank-calc/bin/python -m pytest -v
  bash build.sh
  cat build/build-info.txt
  printf '10 + 5\nq\n' | /tmp/mayank-calc/bin/python app/calculator.py
  docker build -q -t mayank-calculator .
  printf '7 * 8\nq\n' | docker run --rm -i mayank-calculator
}
devsecops() {
  cd "$ROOT/session-17-devsecops"
  python -m venv /tmp/mayank-security
  /tmp/mayank-security/bin/pip -q install -r requirements-dev.txt
  /tmp/mayank-security/bin/python -m pytest -v
  /tmp/mayank-security/bin/bandit -r app -ll
  /tmp/mayank-security/bin/pip-audit -r requirements.txt
  docker build -q -t mayank-devsecops .
  docker run -d --name mayank-devsecops -p 8182:5001 mayank-devsecops
  sleep 3; curl --fail http://localhost:8182/api/status
  docker rm -f mayank-devsecops
  echo 'Scope: tests, Bandit SAST, dependency audit, image build and API smoke test. Registry publish and production deploy are separate.'
}
evidence session-16-cicd calculator
evidence session-17-devsecops devsecops
