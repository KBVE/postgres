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
    fullSrc = fetchFromGitHub {
      owner = "KBVE";
      repo = "kbve";
      rev = "main"; # Use main branch or specific commit hash
      hash = "sha256-3HLpiGuM2zl6h7hIspe9lsHlo/kLy6FaxgTaopR7H4Y=";
    };
  in pkgs.runCommand "kilobase-standalone-src" {} ''
    # Copy only the kilobase source
    mkdir -p $out
    cp -r ${fullSrc}/apps/kbve/kilobase/* $out/
    chmod -R +w $out
    
    # Ensure we have a proper standalone Cargo.toml
    ls -la $out/
    cat $out/Cargo.toml || echo "No Cargo.toml found"
  '';

  # Since we're using the kilobase directory as root, no cargoRoot needed
  # cargoRoot = "";
  
  # No cargoBuildFlags needed since we're building the root package
  cargoBuildFlags = [ ];

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

  # Use the original Cargo.lock but only build kilobase
  cargoLock = let
    fullSrc = fetchFromGitHub {
      owner = "KBVE";
      repo = "kbve";
      rev = "main";
      hash = "sha256-3HLpiGuM2zl6h7hIspe9lsHlo/kLy6FaxgTaopR7H4Y=";
    };
  in {
    lockFile = "${fullSrc}/Cargo.lock";
    allowBuiltinFetchGit = true;
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