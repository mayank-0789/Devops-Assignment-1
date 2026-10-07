#!/usr/bin/env bash
# Deploys the whole Mayank App stack in dependency order.
set -euo pipefail
cd "$(dirname "$0")"
echo "==> [1/5] Applying ConfigMap (mayankapp-config)..."
kubectl apply -f configmap.yaml
echo "==> [2/5] Applying Secret (mayankapp-db-secret)..."
kubectl apply -f secret.yaml
echo "==> [3/5] Applying backend Deployment + Service (mayankapp-backend)..."
kubectl apply -f backend.yaml
echo "==> [4/5] Applying frontend ConfigMap + Deployment + Service (mayankapp-frontend)..."
kubectl apply -f frontend.yaml
echo "==> [5/5] Applying Ingress (mayankapp-ingress)..."
kubectl apply -f ingress.yaml
echo "==> Waiting for deployments to become ready..."
kubectl rollout status deployment/mayankapp-backend --timeout=120s
kubectl rollout status deployment/mayankapp-frontend --timeout=120s
echo "==> Done. Stack is up."
