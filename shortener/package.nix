{ buildGoModule }:

buildGoModule {
  pname = "shortener";
  version = "0.1.0";

  src = ./.;

  # Hash of the fetched Go module dependencies. Nix fetches them in a
  # fixed-output derivation, so the hash must be updated whenever go.mod
  # or go.sum change; set it to lib.fakeHash and the build will tell you
  # the real value.
  vendorHash = "sha256-DTXwSRQk1vtpGMzhSh+L9BRKqcTzcalADwRO/7Dp3XA=";

  env.CGO_ENABLED = 0;

  meta.mainProgram = "shortener";
}
