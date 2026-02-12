#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"

PGRX_VERSION="${1:?Usage: run.sh <pgrx-version> <rust-version>}"
RUST_VERSION="${2:?Usage: run.sh <pgrx-version> <rust-version>}"

echo "=== pgrx Hash Bootstrap Tool ==="
echo "pgrx: ${PGRX_VERSION}, Rust: ${RUST_VERSION}"
echo "Target: linux/amd64 (via Docker)"
echo ""

echo "Building hash bootstrap container (linux/amd64)..."
docker build --platform linux/amd64 -t pgrx-hash-bootstrap "${SCRIPT_DIR}"

echo ""
echo "Running hash bootstrap..."
docker run --rm --platform linux/amd64 \
  -v "${REPO_ROOT}/nix/cargo-pgrx/versions.json:/repo/nix/cargo-pgrx/versions.json" \
  pgrx-hash-bootstrap \
  "${PGRX_VERSION}" "${RUST_VERSION}" "/repo/nix/cargo-pgrx/versions.json"

echo ""
echo "Done! Check nix/cargo-pgrx/versions.json for the new entry."
