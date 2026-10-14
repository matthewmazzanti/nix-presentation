{
  description = "A very basic flake";

  inputs = {
    nixpkgs.url = "https://channels.nixos.org/nixpkgs-unstable/nixexprs.tar.zst";
    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = inputs: {
    packages = builtins.mapAttrs (system: pkgs: {
      shortener = pkgs.callPackage ./nix/package.nix { };
      shortctl = pkgs.callPackage ./shortctl/package.nix { };

      image = pkgs.callPackage ./nix/docker.nix {
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
    homeManagerModules.default = ./home/module.nix;

    homeConfigurations.demo = inputs.home-manager.lib.homeManagerConfiguration {
      pkgs = inputs.nixpkgs.legacyPackages.x86_64-linux;
      modules = [ ./home/demo.nix ];
    };

    nixosConfigurations.vm = inputs.nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        inputs.self.nixosModules.default
        inputs.self.nixosModules.stack
        inputs.home-manager.nixosModules.home-manager
        ./nix/vm.nix
      ];
    };

    nixosConfigurations.ec2 = inputs.nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        inputs.self.nixosModules.default
        inputs.self.nixosModules.stack
        ./nix/ami.nix
      ];
    };

    devShells = builtins.mapAttrs (system: pkgs: {
      default = pkgs.callPackage ./nix/shell.nix { };
    }) inputs.nixpkgs.legacyPackages;
  };
}
