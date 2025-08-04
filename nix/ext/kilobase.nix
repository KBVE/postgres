{
  lib,
  stdenv,
  pkgs,
  fetchFromGitHub,
  postgresql,
  buildPgrxExtension_0_15_0,
  rust-bin,
}:
let
  rustVersion = "1.85.0"; # Updated to support edition 2024
  cargo = rust-bin.stable.${rustVersion}.default.override {
    extensions = [ "rust-src" "rustfmt" "clippy" ];
  };
in
buildPgrxExtension_0_15_0 rec {
  pname = "kilobase";
  version = "0.1.0";
  inherit postgresql;

  src = let
    # Fetch the full repo first
    fullSrc = fetchFromGitHub {
      owner = "KBVE";
      repo = "kbve";
      rev = "main"; # Use main branch or specific commit hash
      hash = "sha256-3HLpiGuM2zl6h7hIspe9lsHlo/kLy6FaxgTaopR7H4Y=";
    };
  in pkgs.runCommand "kilobase-filtered-src" {} ''
    # Copy the full source
    cp -r ${fullSrc} $out
    chmod -R +w $out
    
    # Create a minimal workspace Cargo.toml that only includes kilobase
    cat > $out/Cargo.toml << 'EOF'
[workspace]
resolver = "2"
members = ["apps/kbve/kilobase"]

# Profile overrides for kilobase (from original workspace)
[profile.dev.package.kilobase]
panic = "unwind"

[profile.release.package.kilobase] 
panic = "unwind"
opt-level = 3
lto = "fat"
codegen-units = 1
EOF

    # Remove problematic workspace members to prevent cargo from trying to process them
    rm -rf $out/packages/rust/jedi || true
    rm -rf $out/packages/rust/q || true 
    rm -rf $out/packages/rust/soul || true
    rm -rf $out/packages/erust || true
    rm -rf $out/packages/holy || true
    rm -rf $out/apps/kbve/rust_kanban || true
    rm -rf $out/apps/kbve/rust_api_profile || true
    rm -rf $out/apps/rareicon || true
    rm -rf $out/apps/experimental || true
    rm -rf $out/apps/rentearth || true
    rm -rf $out/apps/discord || true
  '';

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