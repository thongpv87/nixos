{ pkgs, config, lib, ... }: {
  imports = [
    #./compositor.nix
    ./hyprland.nix
    ./shared.nix
  ];
}
