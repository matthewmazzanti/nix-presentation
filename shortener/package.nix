{ lib, buildGoModule }:

buildGoModule {
  pname = "shortener";
  version = "0.1.0";

  # Only the Go sources go into the build input, so editing the nix
  # files that live alongside them does not trigger a rebuild.
  src = lib.fileset.toSource {
    root = ./.;
    fileset = lib.fileset.unions [
      ./go.mod
      ./go.sum
      (lib.fileset.fileFilter (f: f.hasExt "go") ./.)
    ];
  };

  # Hash of the fetched Go module dependencies. Nix fetches them in a
  # fixed-output derivation, so the hash must be updated whenever go.mod
  # or go.sum change; set it to lib.fakeHash and the build will tell you
  # the real value.
  vendorHash = "sha256-DTXwSRQk1vtpGMzhSh+L9BRKqcTzcalADwRO/7Dp3XA=";

  env.CGO_ENABLED = 0;

  meta.mainProgram = "shortener";
}
