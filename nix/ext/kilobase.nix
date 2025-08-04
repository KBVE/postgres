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
  in pkgs.runCommand "kilobase-isolated-src" {
    nativeBuildInputs = [ cargo ];
    CARGO = "${cargo}/bin/cargo";
  } ''
    # Copy only the kilobase directory and necessary files
    mkdir -p $out/apps/kbve
    cp -r ${fullSrc}/apps/kbve/kilobase $out/apps/kbve/
    
    # Copy any shared files that might be needed (like .gitignore, etc.)
    if [ -f ${fullSrc}/.gitignore ]; then
      cp ${fullSrc}/.gitignore $out/
    fi
    
    chmod -R +w $out
    
    # Create a standalone workspace Cargo.toml that only includes kilobase
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

    # Change to workspace root and generate a new Cargo.lock with only kilobase dependencies
    cd $out
    ${cargo}/bin/cargo generate-lockfile --offline || ${cargo}/bin/cargo generate-lockfile
    
    # Verify the lockfile was created
    if [ ! -f Cargo.lock ]; then
      echo "Failed to generate Cargo.lock"
      exit 1
    fi
    
    echo "Generated isolated Cargo.lock for kilobase"
    ls -la
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

  # Override the default Cargo.toml generation to use our filtered workspace
  postPatch = ''
    # Make sure we're using our filtered workspace configuration
    ls -la Cargo.toml
    cat Cargo.toml
  '';

  # Disable tests for now
  doCheck = false;

  meta = with lib; {
    description = "Kilobase PostgreSQL extension";
    homepage = "https://github.com/KBVE/kbve";
    platforms = postgresql.meta.platforms;
    license = licenses.mit;
  };
}