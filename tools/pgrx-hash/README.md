# pgrx Hash Bootstrap Tool

Computes Nix SRI hashes for new `cargo-pgrx` versions. Uses Docker (`linux/amd64`) so ARM machines (Apple Silicon) produce correct x86_64 hashes.

## Usage

```bash
# From repo root:
./tools/pgrx-hash/run.sh <pgrx-version> <rust-version>

# Example: bootstrap pgrx 0.17.0 with Rust 1.90.0
./tools/pgrx-hash/run.sh 0.17.0 1.90.0
```

## What It Does

1. Builds a Docker container targeting `linux/amd64` (uses QEMU on ARM hosts)
2. Fetches `cargo-pgrx` crate from crates.io and computes the source SRI hash
3. Builds `cargo-pgrx` to compute the Cargo dependency hash (`cargoHash`)
4. Writes result to `tools/pgrx-hash/output/result.json` (cached locally)
5. Auto-merges into `nix/cargo-pgrx/versions.json` (requires `jq` on host)

## Output

Results are written to `tools/pgrx-hash/output/result.json`:

```json
{
  "pgrxVersion": "0.17.0",
  "rustVersion": "1.90.0",
  "hash": "sha256-...",
  "cargoHash": "sha256-..."
}
```

This file is gitignored and persists locally for reference.

## When to Use

Run this tool whenever a new pgrx version is needed for an extension:

- Adding a new extension that requires a newer pgrx (e.g., VectorChord needs 0.17.0)
- Upgrading an existing extension to a newer pgrx version
- Adding support for a new Rust version with an existing pgrx version

## Requirements

- Docker with buildx support (for `--platform linux/amd64`)
- On ARM hosts: QEMU user-static registered (usually automatic with Docker Desktop)
- `jq` on the host for auto-merging into versions.json (optional — results are also in output/)
