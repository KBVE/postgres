#!/usr/bin/env bash
set -euo pipefail

PGRX_VERSION="${1:?Usage: bootstrap.sh <pgrx-version> <rust-version>}"
RUST_VERSION="${2:?Usage: bootstrap.sh <pgrx-version> <rust-version>}"
OUTPUT_DIR="${3:-/output}"

echo "=== Bootstrapping pgrx ${PGRX_VERSION} with Rust ${RUST_VERSION} ==="
echo ""

# Step 1: Compute the crate source hash from crates.io
echo "--- Step 1: Fetching cargo-pgrx ${PGRX_VERSION} from crates.io ---"
CRATE_URL="https://static.crates.io/crates/cargo-pgrx/cargo-pgrx-${PGRX_VERSION}.crate"
STORE_PATH=$(nix-prefetch-url --unpack "${CRATE_URL}" 2>/dev/null)
CRATE_HASH=$(nix hash to-sri --type sha256 "${STORE_PATH}")
echo "Crate hash: ${CRATE_HASH}"
echo ""

# Step 2: Build cargo-pgrx in a minimal flake to extract the cargoHash
echo "--- Step 2: Computing cargoHash (this builds cargo-pgrx dependencies) ---"
echo "(This will intentionally fail once to reveal the correct hash)"
TMPDIR=$(mktemp -d)

cat > "${TMPDIR}/flake.nix" << EOF
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    rust-overlay = {
      url = "github:oxalica/rust-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };
  outputs = { nixpkgs, rust-overlay, ... }:
  let
    pkgs = import nixpkgs {
      system = "x86_64-linux";
      overlays = [ (import rust-overlay) ];
    };
    rustToolchain = pkgs.rust-bin.stable."${RUST_VERSION}".default;
    rustPlatform = pkgs.makeRustPlatform {
      cargo = rustToolchain;
      rustc = rustToolchain;
    };
  in {
    packages.x86_64-linux.default = rustPlatform.buildRustPackage rec {
      pname = "cargo-pgrx";
      version = "${PGRX_VERSION}";
      src = pkgs.fetchCrate {
        inherit pname version;
        hash = "${CRATE_HASH}";
      };
      cargoHash = "";
      nativeBuildInputs = [ pkgs.pkg-config ];
      buildInputs = [ pkgs.openssl ];
      doCheck = false;
      auditable = false;
    };
  };
}
EOF

# The build will fail because cargoHash is empty, but it will print the correct hash
BUILD_OUTPUT=$(nix build "${TMPDIR}#default" -L 2>&1 || true)

# Extract the hash from the error output - try multiple patterns
CARGO_HASH=$(echo "${BUILD_OUTPUT}" | grep -oP 'got:\s+\K\S+' | head -1 || true)

if [ -z "${CARGO_HASH}" ]; then
  CARGO_HASH=$(echo "${BUILD_OUTPUT}" | grep "got:" | head -1 | sed 's/.*got:[[:space:]]*//' | tr -d ' ' || true)
fi

rm -rf "${TMPDIR}"

if [ -z "${CARGO_HASH}" ]; then
  echo "ERROR: Could not extract cargoHash from build output."
  echo "Build output (last 40 lines):"
  echo "${BUILD_OUTPUT}" | tail -40
  exit 1
fi
echo "Cargo hash: ${CARGO_HASH}"
echo ""

# Step 3: Write result JSON to output directory
echo "--- Step 3: Writing result to ${OUTPUT_DIR}/result.json ---"
mkdir -p "${OUTPUT_DIR}"

cat > "${OUTPUT_DIR}/result.json" << JSON
{
  "pgrxVersion": "${PGRX_VERSION}",
  "rustVersion": "${RUST_VERSION}",
  "hash": "${CRATE_HASH}",
  "cargoHash": "${CARGO_HASH}"
}
JSON

echo ""
echo "=== Results ==="
echo "pgrx version: ${PGRX_VERSION}"
echo "rust version: ${RUST_VERSION}"
echo "crate hash:   ${CRATE_HASH}"
echo "cargo hash:   ${CARGO_HASH}"
echo ""
echo "Result written to ${OUTPUT_DIR}/result.json"
