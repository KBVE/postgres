#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
OUTPUT_DIR="${SCRIPT_DIR}/output"

PGRX_VERSION="${1:?Usage: run.sh <pgrx-version> <rust-version>}"
RUST_VERSION="${2:?Usage: run.sh <pgrx-version> <rust-version>}"
VERSIONS_JSON="${REPO_ROOT}/nix/cargo-pgrx/versions.json"

echo "=== pgrx Hash Bootstrap Tool ==="
echo "pgrx: ${PGRX_VERSION}, Rust: ${RUST_VERSION}"
echo "Target: linux/amd64 (via Docker)"
echo ""

# Ensure output directory exists
mkdir -p "${OUTPUT_DIR}"

echo "Building hash bootstrap container (linux/amd64)..."
docker build --platform linux/amd64 -t pgrx-hash-bootstrap "${SCRIPT_DIR}"

echo ""
echo "Running hash bootstrap..."
# Mount local output dir for the container to write results into
docker run --rm --platform linux/amd64 \
  --privileged \
  --security-opt seccomp=unconfined \
  -v "${OUTPUT_DIR}:/output" \
  pgrx-hash-bootstrap \
  "${PGRX_VERSION}" "${RUST_VERSION}" "/output"

echo ""

# Read the result and merge into versions.json
RESULT_FILE="${OUTPUT_DIR}/result.json"
if [ ! -f "${RESULT_FILE}" ]; then
  echo "ERROR: No result.json found in ${OUTPUT_DIR}"
  echo "The container may have failed. Check output above."
  exit 1
fi

echo "=== Result from container ==="
cat "${RESULT_FILE}"
echo ""

# Merge into versions.json if jq is available
if command -v jq &>/dev/null; then
  CRATE_HASH=$(jq -r '.hash' "${RESULT_FILE}")
  CARGO_HASH=$(jq -r '.cargoHash' "${RESULT_FILE}")

  echo "--- Updating ${VERSIONS_JSON} ---"
  jq --arg pv "${PGRX_VERSION}" \
     --arg ch "${CRATE_HASH}" \
     --arg rv "${RUST_VERSION}" \
     --arg crh "${CARGO_HASH}" \
     '.[$pv] = { hash: $ch, rust: { ($rv): { cargoHash: $crh } } }' \
     "${VERSIONS_JSON}" > "${VERSIONS_JSON}.tmp" \
  && mv "${VERSIONS_JSON}.tmp" "${VERSIONS_JSON}"

  echo "versions.json updated successfully!"
else
  echo "WARNING: jq not found on host. Install jq to auto-merge, or copy"
  echo "values from ${RESULT_FILE} into ${VERSIONS_JSON} manually."
fi

echo ""
echo "Done! Result cached in ${RESULT_FILE}"
