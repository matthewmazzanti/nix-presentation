{
  description = "A very basic flake";

  inputs = {
    nixpkgs.url = "https://channels.nixos.org/nixpkgs-unstable/nixexprs.tar.zst";
  };

  outputs = inputs: {
    packages = builtins.mapAttrs (system: pkgs: {
      shortener = pkgs.callPackage ./shortener/package.nix { };

      image = pkgs.callPackage ./shortener/image.nix {
        inherit (inputs.self.packages.${system}) shortener;
      };

      vm = inputs.self.nixosConfigurations.vm.config.system.build.vm;

      default = inputs.self.packages.${system}.shortener;
    }) inputs.nixpkgs.legacyPackages;

    nixosModules.default = ./shortener/module.nix;

    nixosConfigurations.vm = inputs.nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        inputs.self.nixosModules.default
        ./vm.nix
      ];
    };

    devShells = builtins.mapAttrs (system: pkgs: {
      default = pkgs.mkShell {
        packages = [
          pkgs.go
          pkgs.gopls
          pkgs.postgresql
          pkgs.redis
          pkgs.process-compose
          pkgs.docker-compose
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
