{
  description = "A very basic flake";

  inputs = {
    nixpkgs.url = "https://channels.nixos.org/nixpkgs-unstable/nixexprs.tar.zst";
  };

  outputs = inputs: {
    packages = builtins.mapAttrs (system: pkgs: {
      shortener = pkgs.callPackage ./nix/package.nix { };

      image = pkgs.callPackage ./nix/image.nix {
        inherit (inputs.self.packages.${system}) shortener;
      };

      vm = inputs.self.nixosConfigurations.vm.config.system.build.vm;

      ami = inputs.self.nixosConfigurations.ec2.config.system.build.amazonImage;

      default = inputs.self.packages.${system}.shortener;
    }) inputs.nixpkgs.legacyPackages;

    nixosModules = {
      # The shortener service itself: services.shortener.*
      default = ./nix/module.nix;
      # The full stack: postgres, redis, and the shortener wired together
      stack = ./nix/stack.nix;
    };

    nixosConfigurations.vm = inputs.nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        inputs.self.nixosModules.default
        inputs.self.nixosModules.stack
        ./nix/vm.nix
      ];
    };

    nixosConfigurations.ec2 = inputs.nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        inputs.self.nixosModules.default
        inputs.self.nixosModules.stack
        ./nix/ec2.nix
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
          pkgs.awscli2
          pkgs.coldsnap
          pkgs.jq
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
