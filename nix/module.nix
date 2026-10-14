# NixOS module: runs the shortener as a hardened systemd service, backed
# by a local postgres and a dedicated redis instance, all wired up over
# unix sockets.
{ config, lib, pkgs, ... }:

let
  cfg = config.services.shortener;
in
{
  options.services.shortener = {
    enable = lib.mkEnableOption "the URL shortener";

    package = lib.mkOption {
      type = lib.types.package;
      default = pkgs.callPackage ./package.nix { };
      description = "The shortener package to run.";
    };

    host = lib.mkOption {
      type = lib.types.str;
      default = "127.0.0.1";
      description = "Address to listen on.";
    };

    port = lib.mkOption {
      type = lib.types.port;
      default = 8000;
      description = "Port to listen on.";
    };

    openFirewall = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Open the firewall for the shortener port.";
    };
  };

  config = lib.mkIf cfg.enable {
    networking.firewall.allowedTCPPorts = lib.mkIf cfg.openFirewall [ cfg.port ];

    services.postgresql = {
      enable = true;
      ensureDatabases = [ "shortener" ];
      ensureUsers = [{
        name = "shortener";
        ensureDBOwnership = true;
      }];
    };

    # A dedicated redis instance, reachable only via its unix socket.
    services.redis.servers.shortener.enable = true;

    systemd.services.shortener = {
      description = "URL shortener";
      wantedBy = [ "multi-user.target" ];
      after = [ "network.target" "postgresql.service" "redis-shortener.service" ];
      requires = [ "postgresql.service" "redis-shortener.service" ];

      environment = {
        HOST = cfg.host;
        PORT = toString cfg.port;
        # Peer auth over the local postgres socket; the OS user "shortener"
        # maps to the postgres role of the same name.
        DATABASE_URL = "postgresql://shortener@/shortener?host=/run/postgresql";
        REDIS_URL = "unix:///run/redis-shortener/redis.sock";
      };

      serviceConfig = {
        ExecStart = lib.getExe cfg.package;
        Restart = "on-failure";
        RestartSec = "2s";

        # The unit runs as a transient user named after the service, so
        # no users.users entry is needed. That name is what postgres peer
        # auth sees.
        DynamicUser = true;
        # Grants access to the redis unix socket.
        SupplementaryGroups = [ "redis-shortener" ];

        NoNewPrivileges = true;
        PrivateTmp = true;
        ProtectSystem = "strict";
        ProtectHome = true;
      };
    };
  };
}
