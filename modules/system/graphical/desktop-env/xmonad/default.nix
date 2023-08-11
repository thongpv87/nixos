{ pkgs, config, lib, ... }:
with lib;
let cfg = config.thongpv87.graphical.desktop-env.xmonad;
in {
  options.thongpv87.graphical.desktop-env.xmonad = {
    enable = mkOption {
      type = types.bool;
      default = false;
      description = "Enable XMonad desktop environment";
    };
  };

  config = mkIf (cfg.enable) {
    environment.systemPackages = with pkgs; [
      alacritty
      acpi
      playerctl
      jq
      xclip
      brightnessctl
      imagemagick
      elisa
      gwenview
      okular
      konversation

      # xmonad pkgs
      jq
      xclip
      feh
      rofi
      brightnessctl
      xorg.xbacklight
      xorg.setxkbmap
      font-awesome
    ];

    services.xserver = {
      displayManager.gdm.enable = true;
      windowManager.xmonad = {
        enable = true;
        enableContribAndExtras = true;
      };
    };

  };
}
