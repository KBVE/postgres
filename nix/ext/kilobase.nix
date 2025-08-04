{
  lib,
  stdenv,
  fetchFromGitHub,
  postgresql,
  buildPgrxExtension_0_15_0,
  rust-bin,
}:
let
  rustVersion = "1.85.0"; # Updated to support edition 2024
  cargo = rust-bin.stable.${rustVersion}.default;
in
buildPgrxExtension_0_15_0 rec {
  pname = "kilobase";
  version = "0.1.0";
  inherit postgresql;

  src = fetchFromGitHub {
    owner = "KBVE";
    repo = "kbve";
    rev = "main"; # Use main branch or specific commit hash
    # If you have a specific commit without edition 2024 requirements, use that instead
    hash = "sha256-3HLpiGuM2zl6h7hIspe9lsHlo/kLy6FaxgTaopR7H4Y=";
  };

  # Cargo.toml path if not at root
  cargoRoot = "apps/kbve/kilobase";
  
  # Build only the kilobase package, isolate from workspace members
  cargoBuildFlags = [ 
    "--package" "kilobase"
  ];

  nativeBuildInputs = [ cargo ];
  buildInputs = [ postgresql ];

  # Update this array when kilobase version is updated
  previousVersions = [
    # Add previous versions here when updating
  ];

  CARGO = "${cargo}/bin/cargo";

  # Environment variables to isolate build and prevent workspace interference
  preBuild = ''
    # Create a minimal Cargo.toml that only includes kilobase to avoid workspace issues
    cd ${cargoRoot}
    
    # Backup original workspace Cargo.toml if it exists
    if [ -f ../../../Cargo.toml ]; then
      mv ../../../Cargo.toml ../../../Cargo.toml.bak
    fi
    
    # Create a standalone Cargo.toml for this build
    cat > ../../../Cargo.toml << 'EOF'
[package]
name = "kilobase-standalone"
version = "0.1.0"
edition = "2021"

[workspace]
members = ["apps/kbve/kilobase"]
resolver = "2"

# Profile overrides for kilobase
[profile.dev.package.kilobase]
panic = "unwind"

[profile.release.package.kilobase] 
panic = "unwind"
opt-level = 3
lto = "fat"
codegen-units = 1
EOF
  '';

  postBuild = ''
    # Restore original Cargo.toml
    if [ -f ../../../Cargo.toml.bak ]; then
      mv ../../../Cargo.toml.bak ../../../Cargo.toml
    fi
  '';

  # Darwin env needs PGPORT to be unique for build to not clash with other pgrx extensions
  env = lib.optionalAttrs stdenv.isDarwin {
    POSTGRES_LIB = "${postgresql}/lib";
    RUSTFLAGS = "-C link-arg=-undefined -C link-arg=dynamic_lookup";
    PGPORT = toString (
      5443 # Unique port for kilobase
      + (if builtins.match ".*_.*" postgresql.version != null then 1 else 0)
      + ((builtins.fromJSON (builtins.substring 0 2 postgresql.version)) - 15) * 2
    );
  };

  cargoLock = {
    lockFile = "${src}/Cargo.lock";
    allowBuiltinFetchGit = true;
    # outputHashes for any git dependencies (if needed)
    # outputHashes = {
    #   "some-git-dep-0.1.0" = "sha256-...";
    # };
  };

  # Disable tests for now
  doCheck = false;

  meta = with lib; {
    description = "Kilobase PostgreSQL extension";
    homepage = "https://github.com/KBVE/kbve";
    platforms = postgresql.meta.platforms;
    license = licenses.mit;
  };
}