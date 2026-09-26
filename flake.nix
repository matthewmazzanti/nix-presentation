{
  description = "A very basic flake";

  inputs = {
    nixpkgs.url = "https://channels.nixos.org/nixpkgs-unstable/nixexprs.tar.zst";
  };

  outputs = inputs: {
    packages = builtins.mapAttrs (system: pkgs: {
      hello = pkgs.hello;

      default = inputs.self.packages.${system}.hello;
    }) inputs.nixpkgs.legacyPackages;

    devShells = builtins.mapAttrs (system: pkgs: {
      default = pkgs.mkShell {
        packages = [
          (pkgs.python3.withPackages (ps: [
            ps.fastapi
            ps.uvicorn
            ps.psycopg
            ps.psycopg-pool
            ps.redis
          ]))
          pkgs.postgresql
          pkgs.redis
          pkgs.process-compose
          pkgs.just
        ];

        # Sockets instead of TCP ports so we never collide with services already running on the host.
        shellHook = ''
          export DATA_DIR=$PWD/.data
          export PGDATA=$DATA_DIR/postgres
          export PGHOST=$DATA_DIR
          export REDIS_SOCKET=$DATA_DIR/redis.sock
          export DATABASE_URL="postgresql:///postgres?host=$PGHOST"
          export REDIS_URL="unix://$REDIS_SOCKET"
        '';
      };
    }) inputs.nixpkgs.legacyPackages;
  };
}
