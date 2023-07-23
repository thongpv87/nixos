{ pkgs, config, lib, ... }:
with lib;
let
  cfg = config.thongpv87.graphical.desktop-env.kde;
  shellScripts = pkgs.stdenv.mkDerivation {
    name = "myShellScripts";
    src = ./bin;
    phases = "installPhase";
    installPhase = ''
      mkdir -p $out/bin
      cp -r ${./bin}/* $out/bin/
      chmod +x $out/bin/*
    '';
  };
in {
  options.thongpv87.graphical.desktop-env.kde = {
    enable = mkOption {
      type = types.bool;
      default = false;
      description = "Enable KDE desktop environment";
    };
  };

  config = mkIf (cfg.enable) {
    environment.systemPackages = with pkgs; [
      alacritty
      wmctrl
      acpi
      playerctl
      jq
      xclip
      font-awesome
      brightnessctl
      imagemagick
      selected-nerdfonts
      plasma5Packages.bismuth
      wayland-utils
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
      imagemagick
      shellScripts
    ];

    programs.xwayland.enable = true;

    services.xserver = {
      displayManager.gdm.enable = true;
      desktopManager.plasma5 = {
        runUsingSystemd = true;
        enable = true;
        useQtScaling = true;
      };

      windowManager.xmonad = {
        enable = true;
        enableContribAndExtras = true;
      };
    };

  };
}
