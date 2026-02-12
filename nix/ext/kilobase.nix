{
  lib,
  stdenv,
  callPackages,
  postgresql,
  rust-bin,
}:
let
  pname = "kilobase";
  version = "17.4.1";
  rustVersion = "1.88.0";
  pgrxVersion = "0.16.1";

  cargo = rust-bin.stable.${rustVersion}.default;
  mkPgrxExtension = callPackages ../cargo-pgrx/mkPgrxExtension.nix {
    inherit rustVersion pgrxVersion;
  };

  src = builtins.fetchGit {
    url = "https://github.com/KBVE/kbve.git";
    rev = "c686ba886f9fd8b87ed9b049264f8602a70706e4";
    shallow = true;
  };
in
mkPgrxExtension {
  inherit
    pname
    version
    postgresql
    src
    ;

  buildAndTestSubdir = "apps/kbve/kilobase";

  nativeBuildInputs = [ cargo ];
  buildInputs = [ postgresql ];

  cargoLock = {
    lockFile = "${src}/Cargo.lock";
    allowBuiltinFetchGit = true;
  };

  buildFeatures = [ "pg17" ];

  CARGO = "${cargo}/bin/cargo";

  env = lib.optionalAttrs stdenv.isDarwin {
    POSTGRES_LIB = "${postgresql}/lib";
    RUSTFLAGS = "-C link-arg=-undefined -C link-arg=dynamic_lookup";
  };

  doCheck = false;
  auditable = false;

  meta = with lib; {
    description = "Kilobase PostgreSQL extension";
    homepage = "https://github.com/KBVE/kbve";
    platforms = postgresql.meta.platforms;
    license = licenses.mit;
  };
}
