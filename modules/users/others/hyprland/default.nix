{ config, lib, pkgs, inputs, ... }:

with lib;
let
  cfg = config.thongpv87.others.hyprland;

  switch-input-method = pkgs.writeShellScriptBin "switch-input-method" ''
    if [ $(ibus engine) == xkb:us::eng ]; then ibus engine Bamboo; else ibus engine xkb:us::eng ; fi
  '';

  raise-volume = pkgs.writeShellScriptBin "raise-volume" ''
    [ $(amixer get Master | grep 'Front Left: Playback' | awk -F '\\[|%' '{print $2}') -lt 100 ] && pactl set-sink-volume @DEFAULT_SINK@ +5%
  '';
  launch-rofi =
    pkgs.writeScriptBin "launch-rofi" (builtins.readFile ./launcher.sh);
in
{
  #imports = [ inputs.hyprland.homeManagerModules.default ];
  options = {
    thongpv87.others.hyprland = {
      enable = mkOption {
        default = false;
        description = ''
          Whether to enable hyprland bundle
        '';
      };
    };
  };

  config = mkIf cfg.enable (mkMerge [{
    home.packages = with pkgs; [
      pop-gtk-theme
      numix-icon-theme
      pop-icon-theme
      papirus-icon-theme
      rhythmbox
      vlc
      shotwell
      dconf
      glib.bin
      goldendict
      gnome.gnome-tweaks
      gnome.nautilus
      gnome.evince
      gnome.gnome-terminal
      pavucontrol
      wofi
      seatd
      hyprpaper
      pipewire
      wireplumber
      slurp
      #wl-clipboard
      switch-input-method
      raise-volume
      rofi-wayland
      launch-rofi
      ranger
      dunst
    ];

    programs = {
      waybar = {
        enable = true;
        package = pkgs.waybar.overrideAttrs (oldAttrs: {
          patchPhase = ''
            sed -i '1s/^/\#define HAVE_WLR\n\#define USE_EXPERIMENTAL\n/' include/factory.hpp
            sed -i 's/zext_workspace_handle_v1_activate(workspace_handle_);/const std::string command = "hyprctl dispatch workspace " + name_;\n\tsystem(command.c_str());/g' src/modules/wlr/workspace_manager.cpp
          '';
          mesonFlags = oldAttrs.mesonFlags ++ [ "-Dexperimental=true" ];
        });

        systemd = {
          enable = true;
          target = "hyprland-session.target";
        };
      };
    };

    gtk = { enable = true; };

    qt = {
      enable = true;
      platformTheme = "gnome";
      style = {
        package = pkgs.pop-gtk-theme;
        name = "pop";
      };
    };

    # wayland.windowManager.hyprland = {
    #   enable = true;
    #   systemdIntegration = true;
    # };

    xdg = {
      configFile = {
        "hypr/hyprland.conf".source = ./hyprland.conf;

        "waybar" = {
          source = ./waybar;
          recursive = true;
        };

        "dunst" = {
          source = ./dunst;
          recursive = true;
        };

        "wofi/style.css".source = ./wofi.css;

        "hypr/hyprpaper.conf".text = ''
          preload=~/.wallpapers/wallpaper.jpg
          wallpaper=eDP-1,~/.wallpapers/wallpaper.jpg
        '';

        "rofi" = {
          source = ./rofi/1080p;
          recursive = true;
        };
      };

      dataFile."fonts" = {
        source = ./rofi/fonts;
        recursive = true;
      };
    };

    home.activation = {
      makeRofiConfigWriteable = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        $DRY_RUN_CMD cp $HOME/.config/rofi/powermenu/styles/colors.rasi.in $HOME/.config/rofi/powermenu/styles/colors.rasi
        chmod 600 $HOME/.config/rofi/powermenu/styles/colors.rasi
      '';
    };
  }]);
}
