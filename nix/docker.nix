{ dockerTools, lib, shortener }:

# A minimal OCI image containing only the static shortener binary.
# No base image, no shell, no package manager: dockerTools assembles
# the layers directly from the nix store closure of `shortener`.
dockerTools.buildLayeredImage {
  name = "shortener";
  tag = "latest";

  contents = [ shortener ];

  config = {
    Cmd = [ (lib.getExe shortener) ];
    Env = [ "HOST=0.0.0.0" ];
    ExposedPorts = { "8000/tcp" = { }; };
  };
}
