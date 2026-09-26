# The stack as an Amazon Machine Image. Built with `nix build .#ami`,
# uploaded and registered with `just ami-register`.
#
# The same stack.nix that backs the QEMU VM; only the substrate differs.
# The amazon-image module supplies the EC2 kernel drivers, grows the
# root partition on first boot, and installs the instance's SSH key
# pair from the metadata service.
{ modulesPath, ... }:

{
  imports = [
    ./stack.nix
    "${modulesPath}/../maintainers/scripts/ec2/amazon-image.nix"
  ];

  image.baseName = "shortener";

  # A raw disk lets coldsnap stream it straight into an EBS snapshot;
  # no S3 bucket or VM Import role needed.
  amazonImage.format = "raw";

  services.openssh.enable = true;
}
