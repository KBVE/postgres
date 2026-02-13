{
  lib,
  stdenv,
  callPackages,
  postgresql,
  rust-bin,
}:
let
  pname = "vchord";
  version = "1.1.0";
  rustVersion = "1.88.0";
  pgrxVersion = "0.16.1";

  cargo = rust-bin.stable.${rustVersion}.default;
  mkPgrxExtension = callPackages ../cargo-pgrx/mkPgrxExtension.nix {
    inherit rustVersion pgrxVersion;
  };

  src = builtins.fetchGit {
    url = "https://github.com/tensorchord/VectorChord.git";
    rev = "c68a6aec9446899d0ab22662968053bd2820ddd4";
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
    description = "Scalable, fast, and disk-friendly vector search for Postgres";
    homepage = "https://github.com/tensorchord/VectorChord";
    platforms = postgresql.meta.platforms;
    license = licenses.agpl3Plus;
  };
}
