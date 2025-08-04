{
  lib,
  stdenv,
  fetchFromGitHub,
  postgresql,
}:

stdenv.mkDerivation rec {
  pname = "pg_failover_slots";
  version = "1.1.0";

  buildInputs = [ postgresql ];

  src = fetchFromGitHub {
    owner = "EnterpriseDB";
    repo = pname;
    rev = "e26870be3b8c6b4cdd94d255a012a46dbd04a29a";
    hash = "sha256-2pFV1uACh2aoqnkxGNERpvJUy6GQwVQqznDy6QQvazk=";
  };

  makeFlags = [ "USE_PGXS=1" ];

  installPhase = ''
    mkdir -p $out/{lib,share/postgresql/extension}

    cp *${postgresql.dlSuffix}      $out/lib
    cp *.sql     $out/share/postgresql/extension
    cp *.control $out/share/postgresql/extension
  '';

  meta = with lib; {
    description = "PostgreSQL extension for logical replication slot failover";
    homepage = "https://github.com/EnterpriseDB/pg_failover_slots";
    platforms = postgresql.meta.platforms;
    license = licenses.postgresql;
  };
}