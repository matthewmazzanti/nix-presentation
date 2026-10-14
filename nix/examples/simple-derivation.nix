{
  pkgs ? import <nixpkgs> { },
}:
let
  audience = "Python Frederick";
in
pkgs.writeShellApplication {
  name = "example-package";

  runtimeInputs = [ pkgs.cowsay ];

  text = ''
    cowsay "Hello, ${audience}"
  '';
}
