# AltitudeIQ interview practice — LinkBoard pipeline

This portfolio project is **not a deployment to AltitudeIQ, AWS, or production**. It demonstrates CI/CD and Kubernetes failure recovery using an ephemeral CI runner.

## GitHub workflows

- **01 - Continuous Integration** (`.github/workflows/ci.yml`): runs on pushes to `main`/`ci-demo`, PRs targeting `main`, and manual dispatch. Runs Jest + coverage, TypeScript checks, Next.js build, secret scan, critical vulnerability scans, Terraform validation, and Docker build/image scan.
- **02 - Production Simulation** (`.github/workflows/production-simulation.yml`): runs on pushes to `production-demo` or manual dispatch. Builds a backend Docker image, starts Kind, deploys MongoDB, Redis and the backend, tests `/health` and `/metrics`, checks tenant RBAC and quotas, and tests a deliberately broken deployment with rollback.

The repo's previous AWS-related workflows are backed up as `.yml.disabled` to prevent unintended AWS deployment. **No AWS credentials needed.** Restore them only after reviewing costs and security.

## Local prerequisites

Node.js 22, npm, Docker Engine/Desktop, `kubectl`, and `kind`. The Docker CLI must be able to reach Docker Engine. Terraform CLI is optional for local static checks.

```bash
cd backend && npm ci && npm run typecheck && npm run test:ci && npm run build && cd ..
cd frontend && npm ci && npx tsc --noEmit && npm run build && cd ..
# Complete deployment/recovery walkthrough (Docker + kind + kubectl):
bash demo/local-demo.sh
```

To see everything on GitHub: push the same commit to `ci-demo` and `production-demo`, or manually dispatch either workflow from GitHub Actions. A single shared `main` branch can also run each with workflow_dispatch. To keep demonstration branches synchronized:

```bash
git push origin HEAD:ci-demo
git push origin HEAD:production-demo
```

Use `git push --force` **only if you understand the impact**; normally create/update branches from the same base commit.

## What evidence means

- Check backend coverage under the CI job summary and download `backend-coverage` artifacts.
- Check each security or validation job directly: their failures are real findings or execution errors, not intentional successes.
- `simulation-evidence` includes smoke XML, rollback logs, pod listings, events, deployment description, and backend logs.
- A deliberately broken image that fails rollout **and** is rolled back successfully counts as a passing recovery drill.
- Tenant checks establish **Kubernetes API RBAC isolation**, not network isolation. The repository has NetworkPolicy resources, but Kind's default CNI does not enforce them.
- Metrics are checked from `/metrics`; the demo does not stand up a Prometheus server or Grafana.
- Kubernetes pods, image layers and PVCs in Kind are disposable. Real deployments require persistent storage, backups, secrets, scaling and monitoring.

## Troubleshooting

- If backend tests fail: run `cd backend && npm run test:ci` and inspect the stack trace.
- If frontend install fails: check lockfile with `npm ci` (do not hide it with `npm install`).
- If Docker build fails: check Docker daemon availability, available disk space and app build output.
- If Kind is slow or OOM: give Docker at least 4 GB RAM, inspect `kubectl get pods -A` and `kubectl describe pod -n linkboard <name>`.
- If Terraform fails: check each directory individually; `terraform init -backend=false` avoids contacting the configured S3 backend but may download providers.
- No jobs were actually executed against GitHub Actions while preparing this artifact. Treat workflow compatibility as pending until you run them.
