{
  lib,
  stdenv,
  pkgs,
  fetchgit,
  postgresql,
  buildPgrxExtension_0_15_0,
}:

buildPgrxExtension_0_15_0 rec {
  pname = "kilobase";
  version = "0.1.0";
  inherit postgresql;

  src = fetchgit {
    url = "https://github.com/KBVE/kbve.git";
    rev = "c969aa6b78de56266e0496c9f61ea0895c1730d4";
    sha256 = "sha256-D8Zxhgr4fV/s6m7MWs9P0tpHNkgkaWdJ2m4C/BKbGHk=";
  };

  # Build from workspace root (with Rust 1.85 we support edition 2024)
  cargoRoot = ".";
  
  # Build only kilobase package - but don't use --package flag as buildAndTestSubdir handles it
  cargoBuildFlags = [ ];

  nativeBuildInputs = [ ];
  buildInputs = [ postgresql ];

  # Update this array when kilobase version is updated
  previousVersions = [
    # Add previous versions here when updating
  ];

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
  };

  # Add pg17 feature
  buildFeatures = [ "pg17" ];

  # Disable tests for now
  doCheck = false;
  
  # Disable cargo-auditable to avoid issues
  auditable = false;
  
  # Tell cargo pgrx package which package to build
  buildAndTestSubdir = "apps/kbve/kilobase";

  meta = with lib; {
    description = "Kilobase PostgreSQL extension";
    homepage = "https://github.com/KBVE/kbve";
    platforms = postgresql.meta.platforms;
    license = licenses.mit;
  };
}