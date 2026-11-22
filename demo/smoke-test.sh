#!/usr/bin/env bash
set -euo pipefail
: "${API_BASE:=http://127.0.0.1:4000}"
RESULTS="${RESULTS_DIR:-demo-results}"
mkdir -p "$RESULTS"
pass=0; fail=0
check() {
  local name="$1" url="$2" pattern="$3" response
  if response="$(curl --fail --silent --show-error --max-time 10 "$url")" && grep -q "$pattern" <<<"$response"; then
    printf 'PASS %s\n' "$name"; pass=$((pass+1))
  else
    printf 'FAIL %s\n' "$name"; fail=$((fail+1))
  fi
}
check 'backend health and dependencies' "$API_BASE/health" '"status":"ok"'
check 'Prometheus exposition' "$API_BASE/metrics" 'http_'
cat > "$RESULTS/smoke.xml" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<testsuite name="kubernetes-smoke" tests="1" failures="$([ "$fail" -eq 0 ] && echo 0 || echo 1)"><testcase name="health and metrics">$([ "$fail" -eq 0 ] || echo '<failure message="Smoke checks did not pass"/>')</testcase></testsuite>
EOF
printf 'Smoke checks: %s passed, %s failed\n' "$pass" "$fail"
[ "$fail" -eq 0 ]
