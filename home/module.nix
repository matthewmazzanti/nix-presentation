{ config, lib, pkgs, ... }:
let
  cfg = config.programs.shortctl;
in
{
  options.programs.shortctl = {
    enable = lib.mkEnableOption "the shortener CLI and shared dotfiles";
    package = lib.mkOption {
      type = lib.types.package;
      default = pkgs.callPackage ../shortctl/package.nix { };
      description = "The shortctl package to install.";
    };
    server = lib.mkOption {
      type = lib.types.str;
      default = "http://127.0.0.1:8000";
      description = "Shortener API endpoint reachable from this machine.";
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = [ cfg.package ];
    xdg.configFile."shortctl/config.json".text = builtins.toJSON {
      inherit (cfg) server;
    };
    # Shared by Home Manager's enabled Bash, Zsh, and Fish integrations.
    home.shellAliases = {
      shorten = "shortctl create";
      linkstats = "shortctl stats";
    };
  };
}
