#!/usr/bin/env bash
# Tears the Mayank App stack down in reverse order.
set -uo pipefail
cd "$(dirname "$0")"
echo "==> Deleting Ingress (mayankapp-ingress)..."
kubectl delete -f ingress.yaml --ignore-not-found
echo "==> Deleting frontend (mayankapp-frontend)..."
kubectl delete -f frontend.yaml --ignore-not-found
echo "==> Deleting backend (mayankapp-backend)..."
kubectl delete -f backend.yaml --ignore-not-found
echo "==> Deleting Secret (mayankapp-db-secret)..."
kubectl delete -f secret.yaml --ignore-not-found
echo "==> Deleting ConfigMap (mayankapp-config)..."
kubectl delete -f configmap.yaml --ignore-not-found
echo "==> Cleanup complete."
