#!/usr/bin/env bash
set -euo pipefail
if ! command -v docker >/dev/null || ! command -v kind >/dev/null || ! command -v kubectl >/dev/null; then
  echo 'Install docker, kind and kubectl first' >&2; exit 2
fi
CLUSTER=linkboard-interview
trap 'if [ "${KEEP_CLUSTER:-0}" != 1 ]; then kind delete cluster --name "$CLUSTER"; fi' EXIT
kind create cluster --name "$CLUSTER" --config demo/kind-config.yaml
kubectl config use-context "kind-$CLUSTER"
docker build -t linkboard-backend:demo-good backend
kind load docker-image linkboard-backend:demo-good --name "$CLUSTER"
kubectl apply -f k8s/namespace.yaml -f k8s/configmap.yaml -f k8s/mongo.yaml -f k8s/redis.yaml
kubectl rollout status deployment/mongo -n linkboard --timeout=180s
kubectl rollout status deployment/redis -n linkboard --timeout=120s
kubectl apply -f k8s/backend.yaml
kubectl set image deployment/linkboard-backend backend=linkboard-backend:demo-good -n linkboard
kubectl rollout status deployment/linkboard-backend -n linkboard --timeout=180s
bash demo/check-tenants.sh
kubectl port-forward -n linkboard service/linkboard-backend 4000:80 >/tmp/linkboard-port-forward.log 2>&1 &
PF=$!
trap 'kill "$PF" 2>/dev/null || true; if [ "${KEEP_CLUSTER:-0}" != 1 ]; then kind delete cluster --name "$CLUSTER"; fi' EXIT
for i in {1..30}; do curl -fsS http://127.0.0.1:4000/health >/dev/null && break || sleep 2; done
bash demo/smoke-test.sh
mkdir -p demo-results
kubectl set image deployment/linkboard-backend backend=linkboard-backend:demo-broken -n linkboard
if kubectl rollout status deployment/linkboard-backend -n linkboard --timeout=65s; then echo 'Bad release unexpectedly succeeded'; exit 1; fi
echo 'Expected bad release failed; initiating rollback' | tee demo-results/rollback.log
kubectl rollout undo deployment/linkboard-backend -n linkboard
kubectl rollout status deployment/linkboard-backend -n linkboard --timeout=180s
curl -fsS http://127.0.0.1:4000/health | tee -a demo-results/rollback.log
echo 'PASS: rollback restored good release' | tee -a demo-results/rollback.log
