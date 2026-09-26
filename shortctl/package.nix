{ writeShellApplication, curl, jq }:
writeShellApplication {
  name = "shortctl";
  runtimeInputs = [ curl jq ];
  text = builtins.readFile ./shortctl.sh;
}
