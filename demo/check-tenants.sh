#!/usr/bin/env bash
set -euo pipefail
kubectl apply -f demo/tenants.yaml
IDENTITY='system:serviceaccount:tenant-alpha:tenant-operator'
kubectl auth can-i list pods -n tenant-alpha --as="$IDENTITY" | grep -qx yes
kubectl auth can-i list pods -n tenant-beta --as="$IDENTITY" | grep -qx no
kubectl auth can-i create deployments -n tenant-alpha --as="$IDENTITY" | grep -qx no
kubectl get resourcequota -n tenant-alpha tenant-quota >/dev/null
kubectl get resourcequota -n tenant-beta tenant-quota >/dev/null
printf 'PASS: tenant-alpha service account cannot read tenant-beta pods or create deployments\n'
printf 'NOTE: API RBAC isolation validated; network isolation is NOT validated by this test\n'
