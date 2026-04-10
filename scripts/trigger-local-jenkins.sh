#!/usr/bin/env bash
set -euo pipefail

JENKINS_URL="${JENKINS_URL:-http://localhost:8081}"
JENKINS_JOB_NAME="${JENKINS_JOB_NAME:-e-commerce}"
JENKINS_USER="${JENKINS_USER:-admin}"
JENKINS_API_TOKEN="${JENKINS_API_TOKEN:-}"

if [[ -z "$JENKINS_API_TOKEN" ]]; then
  echo "JENKINS_API_TOKEN is not set. Skipping Jenkins trigger."
  exit 0
fi

CRUMB_HEADER="$(curl -fsS -u "${JENKINS_USER}:${JENKINS_API_TOKEN}" "${JENKINS_URL}/crumbIssuer/api/xml?xpath=concat(//crumbRequestField,\":\",//crumb)" || true)"

CURL_ARGS=(
  -fsS
  -X POST
  -u "${JENKINS_USER}:${JENKINS_API_TOKEN}"
)

if [[ -n "$CRUMB_HEADER" ]]; then
  CURL_ARGS+=( -H "$CRUMB_HEADER" )
fi

curl "${CURL_ARGS[@]}" "${JENKINS_URL}/job/${JENKINS_JOB_NAME}/build?delay=0sec"
echo "Triggered Jenkins job: ${JENKINS_JOB_NAME}"
