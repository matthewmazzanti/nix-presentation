# The application stack: postgres, redis, and the shortener, wired up
# over local unix sockets. Exposed as nixosModules.stack; every machine
# that runs the app imports it and adds only its substrate-specific
# parts (see vm.nix and ami.nix).
{ ... }:

{
  networking.hostName = "shortener";

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

  services.shortener = {
    enable = true;
    # Traffic arrives on the machine's NIC, not loopback.
    host = "0.0.0.0";
  };

  systemd.services.shortener = {
    after = [ "postgresql.service" "redis-shortener.service" ];
    requires = [ "postgresql.service" "redis-shortener.service" ];
  };

  networking.firewall.allowedTCPPorts = [ 8000 ];

  system.stateVersion = "26.11";
}
