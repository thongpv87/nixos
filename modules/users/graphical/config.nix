{ pkgs, config, lib, ... }:
with lib; {
  config.thongpv87.graphical = {
    enable = mkDefault false;

    wayland = {
      enable = mkDefault false;
      type = mkDefault null;

      background = {
        enable = mkDefault true;
        image = mkDefault ./wallpapers/peacefulmtn.jpg;
        mode = mkDefault "fill";
        pkg = mkDefault pkgs.swaybg;
      };

      statusbar = { enable = mkDefault false; };

      screenlock = { enable = mkDefault false; };
    };
  };
}
