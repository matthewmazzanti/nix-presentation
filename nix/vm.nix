# The shortener service as a local QEMU VM. Built with `nix build .#vm`,
# run with `just vm`.
{ modulesPath, ... }:

{
  # This machine only ever runs as a QEMU guest, so pull in the VM
  # module directly: it supplies the root filesystem and bootloader.
  imports = [ "${modulesPath}/virtualisation/qemu-vm.nix" ];

  networking.hostName = "shortener";
  system.stateVersion = "26.11";

  users.users.demo.isNormalUser = true;
  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    users.demo = import ../home/demo.nix;
  };

  # Demo conveniences: serial console, auto-login the configured user.
  services.getty.autologinUser = "demo";

  # The host port forward lands on the guest NIC, so listen there and
  # open the guest firewall. The forward itself is bound to loopback on
  # the host, so only this machine can reach it.
  services.shortener = {
    enable = true;
    host = "0.0.0.0";
    openFirewall = true;
  };

  virtualisation = {
    graphics = false;
    memorySize = 1024;
    forwardPorts = [{
      from = "host";
      host = { address = "127.0.0.1"; port = 8000; };
      guest.port = 8000;
    }];
  };
}
