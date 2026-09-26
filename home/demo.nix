{ ... }:
{
  imports = [ ./module.nix ];
  home.username = "demo";
  home.homeDirectory = "/home/demo";
  home.stateVersion = "26.05";
  programs.bash.enable = true;
  programs.shortctl.enable = true;
}
