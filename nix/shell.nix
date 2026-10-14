{
  mkShell,
  go,
  gopls,
  postgresql,
  redis,
  process-compose,
  docker-compose,
  jq,
  just,
  presenterm,
}:

mkShell {
  packages = [
    go
    gopls
    postgresql
    redis
    process-compose
    docker-compose
    jq
    just
    presenterm
  ];

  # Sockets instead of TCP ports so we never collide with services already running on the host.
  shellHook = ''
    export DATA_DIR=$PWD/.data
    export PGDATA=$DATA_DIR/postgres
    export PGHOST=$DATA_DIR
    export PGDATABASE=postgres
    export REDIS_SOCKET=$DATA_DIR/redis.sock
    export DATABASE_URL="postgresql:///postgres?host=$PGHOST"
    export REDIS_URL="unix://$REDIS_SOCKET"
  '';
}
