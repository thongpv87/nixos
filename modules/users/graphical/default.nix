{ pkgs, config, lib, ... }:
with lib;
let cfg = config.thongpv87.graphical;
in {
  imports = [ ./applications ./wayland ./xorg.nix ./config.nix ];

  options.thongpv87.graphical = {
    enable = mkOption {
      description = "Enable xorg";
      default = false;
    };

    theme = mkOption {
      type = with types; enum [ "breeze" ];
      default = "breeze";
    };
  };

  config = mkIf cfg.enable {
    home = {
      sessionVariables = {
        QT_QPA_PLATFORMTHEME = "breeze-qt5";
        SSH_AUTH_SOCK = "\${XDG_RUNTIME_DIR}/keyring/ssh";
        SSH_ASKPASS = "${pkgs.gnome.seahorse}/libexec/seahorse/ssh-askpass";
      };

      packages = with pkgs; [
        # qt
        breeze-qt5

        xdg-utils

        # Fonts
        selected-nerdfonts
        noto-fonts-emoji
        google-fonts

        # bm-font
        noto-fonts-cjk # Chinese
        dejavu_fonts
        liberation_ttf
        corefonts # microsoft
        carlito

        fontpreview
        emote
        #openmoji-color

        jdpkgs.la-capitaine-icon-theme

        gnome.seahorse
      ];
    };

    home.pointerCursor = {
      # installed in profile earlier
      package = pkgs.volantes-cursors;
      name = "volantes_cursors";
      # Pass through config to gtk
      # https://github.com/nix-community/home-manager/blob/693d76eeb84124cc3110793ff127aeab3832f95c/modules/config/home-cursor.nix#L152
      gtk.enable = true;
    };

    fonts.fontconfig.enable = true;

    gtk = {
      enable = true;
      theme = mkMerge [
        (mkIf (cfg.theme == "breeze") {
          package = with pkgs; breeze-gtk;
          name = "Breeze";
        })
      ];

      iconTheme = {
        package = null;
        name = "la-capitaine-icon-theme";
      };

      font = {
        # already installed in profila
        package = null;
        name = "Berkeley Mono Variable";
        size = 10;
      };
    };

    # https://github.com/nix-community/home-manager/issues/2064
    # systemd.user.targets.tray = {
    #   Unit = {
    #     Description = "Home manager system tray";
    #     Requires = [ "graphical-session-pre.target" ];
    #     After = [ "xdg-desktop-portal-gtk.service" ];
    #   };
    # };

    systemd.user.sessionVariables = {
      # So graphical services are themed (eg trays)
      QT_QPA_PLATFORMTHEME = "breeze-qt5";
      PATH = builtins.concatStringsSep ":" [
        # Following two needed for themes from trays
        # "${pkgs.libsForQt5.qtstyleplugin-kvantum}/bin"
        # "${pkgs.qt5ct}/bin"
        # needed for opening things from trays
        # "${pkgs.xdg-utils}/bin"
        # "${pkgs.dolphin}/bin"
      ];
    };

    xdg = {
      systemDirs.data = [
        "${pkgs.gtk3}/share/gsettings-schemas/${pkgs.gtk3.name}"
        "${pkgs.gsettings-desktop-schemas}/share/gsettings-schemas/${pkgs.gsettings-desktop-schemas.name}"
      ];

      configFile = {
        "wallpapers" = { source = ./wallpapers; };

        "kdeglobals" = {
          text = ''
            [General]
            TerminalApplication=${pkgs.alacritty}/bin/alacritty
          '';
        };
      };

      #   # https://wiki.archlinux.org/title/XDG_MIME_Applications#New_MIME_types
      #   # https://specifications.freedesktop.org/shared-mime-info-spec/shared-mime-info-spec-latest.html#idm46292897757504
      #   # "mime/text/x-r-markdown.xml" = {
      #   #   text = ''
      #   #     <?xml version="1.0" encoding="UTF-8"?>
      #   #     <mime-info xmlns="http://www.freedesktop.org/standards/shared-mime-info">
      #   #       <mime-type type="text/x-r-markdown">
      #   #         <comment>RMarkdown file</comment>
      #   #         <icon name="text-x-r-markdown"/>
      #   #         <glob pattern="*.Rmd"/>
      #   #         <glob pattern="*.Rmarkdown"/>
      #   #       </mime-type>
      #   #     </mime-info>
      #   #   '';
      #   # };
      # };
    };

    # dconf settings set by gtk settings: https://github.com/nix-community/home-manager/blob/693d76eeb84124cc3110793ff127aeab3832f95c/modules/misc/gtk.nix#L227
    dconf.settings = {
      "org/gnome/desktop/interface" = {
        # https://askubuntu.com/questions/1404764/how-to-use-hdystylemanagercolor-scheme
        color-scheme = "prefer-dark";
        text-scaling-factor = 1.0;
      };
    };

    systemd.user.services.gnome-keyring =
      mkIf config.machineData.systemConfig.gnome.keyring.enable {
        Unit = {
          Description = "GNOME Keyring";
          PartOf = [ "graphical-session-pre.target" ];
        };

        Service = {
          ExecStart =
            "/run/wrappers/bin/gnome-keyring-daemon --start --foreground";
          Restart = "on-abort";
        };

        Install = { WantedBy = [ "graphical-session-pre.target" ]; };
      };

    xdg = {
      enable = true;
      mime.enable = true;
      mimeApps = {
        enable = true;
        # TODO: Create a function for generating these better
        associations.added = {
          "x-scheme-handler/terminal" = "foot.desktop";
          "x-scheme-handler/file" = "org.kde.dolphin.desktop";
          "x-directory/normal" = "org.kde.dolphin.desktop";
        };
        defaultApplications = {
          "application/pdf" = "okularApplication_pdf.desktop";
          "application/x-shellscript" = "nvim.desktop";
          "application/x-perl" = "nvim.desktop";
          "application/json" = "nvim.desktop";
          "text/x-readme" = "nvim.desktop";
          "text/plain" = "nvim.desktop";
          "text/markdown" = "nvim.desktop";
          "text/x-csrc" = "nvim.desktop";
          "text/x-chdr" = "nvim.desktop";
          "text/x-python" = "nvim.desktop";
          "text/x-tex" = "texstudio.desktop";
          "text/x-makefile" = "nvim.desktop";
          "inode/directory" = "org.kde.dolphin.desktop";
          "x-directory/normal" = "org.kde.dolphin.desktop";
          "x-scheme-handler/file" = "org.kde.dolphin.desktop";
          "x-scheme-handler/terminal" = "foot.desktop";
          "image/bmp" = "vimiv.desktop";
          "image/gif" = "vimiv.desktop";
          "image/jpeg" = "vimiv.desktop";
          "image/jp2" = "vimiv.desktop";
          "image/jpeg2000" = "vimiv.desktop";
          "image/jpx" = "vimiv.desktop";
          "image/png" = "vimiv.desktop";
          "image/svg" = "vimiv.desktop";
          "image/tiff" = "vimiv.desktop";
        };
      };
    };
  };

}
