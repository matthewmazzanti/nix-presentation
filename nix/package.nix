{ lib, buildGoModule }:

buildGoModule {
  pname = "shortener";
  version = "0.1.0";

  # Only the Go sources go into the build input, so unrelated files in
  # the repo do not trigger a rebuild.
  src = lib.fileset.toSource {
    root = ../shortener;
    fileset = lib.fileset.unions [
      ../shortener/go.mod
      ../shortener/go.sum
      (lib.fileset.fileFilter (f: f.hasExt "go") ../shortener)
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
