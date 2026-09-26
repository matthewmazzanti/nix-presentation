# The stack (nixosModules.stack) as a local QEMU VM. Built with
# `nix build .#vm`, run with `just vm`.
{ modulesPath, ... }:

{
  # This machine only ever runs as a QEMU guest, so pull in the VM
  # module directly: it supplies the root filesystem and bootloader.
  imports = [ "${modulesPath}/virtualisation/qemu-vm.nix" ];

  # Demo conveniences: serial console, auto-login root.
  services.getty.autologinUser = "root";

  virtualisation = {
    graphics = false;
    memorySize = 1024;
    forwardPorts = [{ from = "host"; host.port = 8000; guest.port = 8000; }];
  };
}
