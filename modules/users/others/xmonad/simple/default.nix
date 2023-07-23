{ config, pkgs, lib, ... }:

with lib;
let
  cfg = config.thongpv87.others.xmonad.simple;

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
  statusbar = pkgs.haskellPackages.callCabal2nix "xmobar" ./xmobar { };
in {
  options = {
    thongpv87.others.xmonad.simple = {
      enable = mkOption { default = false; };
    };
  };

  config = mkIf cfg.enable (mkMerge [{
    home.packages = with pkgs; [
      wmctrl
      acpi
      playerctl
      jq
      xclip
      maim
      xautolock
      betterlockscreen
      feh
      xdotool
      scrot
      font-awesome
      selected-nerdfonts
      rofi
      xmobar
      libqalculate
      brightnessctl
      xorg.xbacklight
      xorg.setxkbmap
      dunst
      font-awesome
      selected-nerdfonts
      gnome.gnome-terminal
      shellScripts
      trayer
      #statusbar
      networkmanagerapplet
      imagemagick
      #jonaburg-picom
    ];

    thongpv87.others.media.enable = false;

    xsession = {
      enable = true;

      profileExtra = "#wal -R& ";

      windowManager = {
        xmonad = {
          enable = true;
          enableContribAndExtras = true;
          config = ./xmonad/xmonad.hs;
          extraPackages = hsPkgs: [ hsPkgs.xmobar ];
          libFiles = lib.foldr lib.trivial.mergeAttrs { } (lib.lists.forEach
            (lib.lists.filter (x: builtins.baseNameOf x != "xmonad.hs")
              (lib.filesystem.listFilesRecursive ./xmonad))
            (file: { "${builtins.baseNameOf file}" = file; }));
        };
      };
    };

    systemd.user.services.dunst = {
      Unit = {
        Description = "Dunst notification daemon";
        After = [ "graphical-session-pre.target" ];
        PartOf = [ "graphical-session.target" ];
      };

      Service = {
        Type = "dbus";
        BusName = "org.freedesktop.Notifications";
        ExecStart = "${pkgs.dunst}/bin/dunst";
      };
    };

    xdg = {
      configFile = {
        #"picom/picom.conf".source = ./config/picom.conf;
        "dunst" = {
          source = ./dunst;
          recursive = true;
        };

        "xmobar/bin" = {
          source = ./xmobar/bin;
          recursive = true;
        };

        "alacritty/alacritty.yml.in".source = ./alacritty/alacritty.yml;
      };
    };

    home.file = {
      # ".xmonad/xmobar" = {
      #   source = ./xmobar;
      #   recursive = true;
      # };

      # ".xmonad/bin" = {
      #   source = ./bin;
      #   recursive = true;
      # };
    };

    services = {
      random-background = {
        enable = true;
        enableXinerama = true;
        display = "fill";
        imageDirectory = "%h/.wallpapers";
        interval = "24h";
      };

      picom = {
        enable = false;

        #vSync = true;

        #activeOpacity = "1";
        #inactiveOpacity = "0.9";
        opacityRule = [
          "100:class_g   *?= 'Chromium-browser'"
          "100:class_g   *?= 'Google-Chrome'"
          "100:class_g   *?= 'zoom'"
          "100:class_g   *?= 'Firefox'"
          "100:class_g   *?= 'Alacritty'"
          "100:name      *?= 'Dunst'"
          "100:class_g   *?= 'gitkraken'"
          "100:name      *?= 'emacs'"
          "100:class_g   *?= 'emacs'"
          "100:class_g   ~=  'jetbrains'"
          "100:class_g   *?= 'rofi'"
          "70:name       *?= 'GLava'"
          "70:name       *?= 'GLavaRadial'"
        ];

        extraOptions = ''
          corner-radius = 12;
          xinerama-shadow-crop = true;
          #blur-background = true;
          #blur-method = "kernel";
          #blur-strength = 5;
          rounded-corners-exclude = [
            #"window_type = 'normal'",
            "class_g = 'Rofi'",
            #"class_g = 'Tint2'",
            "name = 'Notification area'",
            "name = 'xmobar'",
            "class_g = 'xmobar'",
            #"class_g = 'kitty'",
            #"class_g = 'Alacritty'",
            "class_g = 'Polybar'",
            "class_g = 'code-oss'",
            "class_g = 'trayer'",
            #"class_g = 'firefox'",
            "class_g = 'Thunderbird'"
          ];
        '';
        experimentalBackends = true;

        shadowExclude = [ "bounding_shaped && !rounded_corners" ];

        fade = true;
        fadeDelta = 10;
      };
    };
  }]);
}
