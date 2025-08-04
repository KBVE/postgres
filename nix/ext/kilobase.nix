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
    hash = "sha256-AKsvBd1UR28/o269Ys3lZzYkCRXXZrIgurE9C9lsW+Y=";
  };

  # Cargo.toml path if not at root
  cargoRoot = "apps/kbve/kilobase";
  
  # Build only the kilobase package
  cargoBuildFlags = [ "--package" "kilobase" ];

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

  cargoHash = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA="; # TODO: Replace with actual cargoHash

  # Disable tests for now
  doCheck = false;

  meta = with lib; {
    description = "Kilobase PostgreSQL extension";
    homepage = "https://github.com/KBVE/kbve";
    platforms = postgresql.meta.platforms;
    license = licenses.mit;
  };
}