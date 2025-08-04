{
  lib,
  stdenv,
  fetchFromGitHub,
  postgresql,
  libkrb5,
  openssl,
}:

stdenv.mkDerivation rec {
  pname = "pg_failover_slots";
  version = "1.1.0";

  buildInputs = [ postgresql libkrb5 openssl ];

  src = fetchFromGitHub {
    owner = "EnterpriseDB";
    repo = pname;
    rev = "e26870be3b8c6b4cdd94d255a012a46dbd04a29a";
    hash = "sha256-2pFV1uACh2aoqnkxGNERpvJUy6GQwVQqznDy6QQvazk=";
  };

  makeFlags = [ "USE_PGXS=1" ];

  installPhase = ''
    install -D -t $out/lib pg_failover_slots${postgresql.dlSuffix}
    install -D -t $out/share/postgresql/extension *.sql
    install -D -t $out/share/postgresql/extension *.control
  '';

  meta = with lib; {
    description = "PostgreSQL extension for logical replication slot failover";
    homepage = "https://github.com/EnterpriseDB/pg_failover_slots";
    platforms = postgresql.meta.platforms;
    license = licenses.postgresql;
  };
}