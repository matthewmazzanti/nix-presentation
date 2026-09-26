# A complete NixOS machine running postgres, redis, and the shortener.
# Built as a QEMU VM with `nix build .#vm`, run with `just vm`.
{ modulesPath, ... }:

{
  # This machine only ever runs as a QEMU guest, so pull in the VM
  # module directly: it supplies the root filesystem and bootloader.
  imports = [ "${modulesPath}/virtualisation/qemu-vm.nix" ];

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
    # QEMU's port forward arrives on the guest's NIC, not loopback.
    host = "0.0.0.0";
  };

  systemd.services.shortener = {
    after = [ "postgresql.service" "redis-shortener.service" ];
    requires = [ "postgresql.service" "redis-shortener.service" ];
  };

  networking.firewall.allowedTCPPorts = [ 8000 ];

  users.users.demo.isNormalUser = true;
  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    users.demo = import ./home/demo.nix;
  };

  # Demo conveniences: serial console, auto-login the configured user.
  services.getty.autologinUser = "demo";

  virtualisation = {
    graphics = false;
    memorySize = 1024;
    forwardPorts = [{ from = "host"; host.port = 8000; guest.port = 8000; }];
  };

  system.stateVersion = "26.11";
}
