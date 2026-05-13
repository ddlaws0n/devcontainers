#!/usr/bin/env bash
#
# Verify a devcontainer image was built by this repo's signed CI workflow.
#
# Usage:
#   scripts/verify-image.sh ghcr.io/ddlaws0n/devcontainer-base:latest
#   scripts/verify-image.sh ghcr.io/ddlaws0n/devcontainer-python@sha256:<digest>
#
# Checks:
#   1. Cosign keyless signature against the build workflow OIDC identity
#   2. GitHub-issued build provenance attestation
#
# Requires: cosign, gh (GitHub CLI) on PATH.

set -euo pipefail

if [[ $# -ne 1 ]]; then
  echo "usage: $0 <image-ref>" >&2
  exit 2
fi

IMAGE="$1"
REPO_OWNER="${REPO_OWNER:-ddlaws0n}"
REPO_NAME="${REPO_NAME:-devcontainers}"
WORKFLOW="${WORKFLOW:-build.yml}"

IDENTITY_RE="https://github.com/${REPO_OWNER}/${REPO_NAME}/\\.github/workflows/${WORKFLOW}@refs/(heads|tags)/.*"
ISSUER="https://token.actions.githubusercontent.com"

for cmd in cosign gh; do
  if ! command -v "$cmd" >/dev/null 2>&1; then
    echo "error: '$cmd' not on PATH" >&2
    exit 1
  fi
done

echo "==> Verifying cosign signature for ${IMAGE}"
cosign verify \
  --certificate-identity-regexp "${IDENTITY_RE}" \
  --certificate-oidc-issuer "${ISSUER}" \
  "${IMAGE}" >/dev/null

echo "==> Verifying GitHub build provenance attestation"
gh attestation verify \
  --owner "${REPO_OWNER}" \
  "oci://${IMAGE}"

echo "==> OK: ${IMAGE} is signed and attested by ${REPO_OWNER}/${REPO_NAME}/${WORKFLOW}"
