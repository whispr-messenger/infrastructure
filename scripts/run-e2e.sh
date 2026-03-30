#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

echo "==> Running E2E tests across services"

pushd "${ROOT_DIR}/auth-service" >/dev/null
echo "--- auth-service: e2e"
npm run test:e2e || { echo "auth-service e2e failed"; exit 1; }
popd >/dev/null

pushd "${ROOT_DIR}/scheduling-service" >/dev/null
echo "--- scheduling-service: e2e"
npm run test:e2e || { echo "scheduling-service e2e failed"; exit 1; }
popd >/dev/null

pushd "${ROOT_DIR}/media-service" >/dev/null
echo "--- media-service: e2e"
npm run test:e2e || echo "media-service e2e (none or optional) — continuing"
popd >/dev/null

pushd "${ROOT_DIR}/user-service" >/dev/null
echo "--- user-service: e2e"
npm run test:e2e || echo "user-service e2e (none or optional) — continuing"
popd >/dev/null

echo "==> All requested E2E suites executed"
