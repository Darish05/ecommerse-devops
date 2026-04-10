#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(git rev-parse --show-toplevel)"

git -C "$REPO_ROOT" config core.hooksPath .githooks
chmod +x "$REPO_ROOT/.githooks/pre-push"
chmod +x "$REPO_ROOT/scripts/trigger-local-jenkins.sh"

echo "Local Git automation enabled."
echo "Pre-push hook is active and will trigger local Jenkins if JENKINS_API_TOKEN is set."
