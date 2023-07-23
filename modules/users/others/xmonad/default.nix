{ config, lib, pkgs, ... }:

with lib;
let cfg = config.thongpv87.others.xmonad;
in {
  imports = [ ./simple ];

  options = {
    thongpv87.others.xmonad = {
      enable = mkOption {
        default = false;
        description = ''
          Whether to enable xmonad bundle
        '';
      };

      theme = mkOption {
        type = with types; enum [ "simple" ];
        default = "simple";
        description = ''
          xmonad theme"
        '';
      };
    };
  };

  config = mkIf cfg.enable (mkMerge [
    {
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
      ];

      gtk = { enable = true; };

      qt = {
        enable = true;
        platformTheme = "gnome";
        style = {
          package = pkgs.pop-gtk-theme;
          name = "pop";
        };
      };

      programs = {
        autorandr = {
          enable = true;
          hooks.postswitch = {
            "postswitch" = lib.readFile ./autorandr/postswitch;
          };
        };
      };

      systemd.user.services = {
        xsettings = {
          Unit.Description = "xsettings daemon";
          Service = {
            ExecStart =
              "${pkgs.gnome.gnome-settings-daemon}/libexec/gsd-xsettings";
            Restart = "on-failure";
            RestartSec = 3;
          };

          Install.WantedBy = [ "graphical-session.target" ];
        };
      };
    }

    (mkIf (cfg.theme == "simple") {
      thongpv87.others.xmonad.simple.enable = true;
    })

  ]);
}
