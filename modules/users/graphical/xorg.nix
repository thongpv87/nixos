{ pkgs, config, lib, ... }:
with lib;
let
  cfg = config.thongpv87.graphical.xorg;
  systemCfg = config.machineData.systemConfig;
in {
  options.thongpv87.graphical.xorg = {
    enable = mkOption {
      description = "Enable xorg";
      type = types.bool;
      default = false;
    };

    type = mkOption {
      description = ''What desktop/wm to use. Options: "xmonad"'';
      type = types.enum [ "xmonad" ];
      default = null;
    };

    screenlock = {
      enable = mkOption {
        description = "Enable screen locking (xss-lock). Only used with dwm";
        type = types.bool;
        default = false;
      };

      timeout = {
        script = mkOption {
          description = "Script to run on timeout. Default null";
          type = with types; nullOr package;
          default = null;
        };

        time = mkOption {
          description =
            "Time in seconds until run timeout script. Default 180.";
          type = types.int;
          default = 180;
        };
      };

      lock = {
        command = mkOption {
          description = "Lock command. Default xsecurelock";
          type = types.str;
          default = "${pkgs.xsecurelock}/bin/xsecurelock";
        };

        time = mkOption {
          description =
            "Time in seconds after timeout until lock. Default 180.";
          type = types.int;
          default = 180;
        };
      };
    };
  };

  config = mkIf cfg.enable (mkMerge [
    mkIf
    (cfg.type == "xmonad")
    {
      assertions = [
        {
          assertion = systemCfg.graphical.xorg.enable;
          message = "To enable xorg for user, it must be enabled for system";
        }
        {
          assertion = systemCfg.graphical.desktop-env.kde.enable;
          message =
            "To enable xmonad window manager for KDE, KDE must be enabled for system";
        }
      ];

      systemd.user.services.xmonad = {
        Install = { WantedBy = [ "plasma-workspace.target" ]; };

        Unit = {
          Description = "Plasma Custom Window Manager";
          Before = [ "plasma-workspace.target" ];
        };

        Service = {
          ExecStart = "/run/current-system/sw/bin/xmonad";
          Restart = "on-failure";
          Slice = "session.slice";
        };
      };
    }

    {
      systemd.user.services = mkIf (cfg.screenlock.enable) {
        xss-lock = {
          Install = { WantedBy = [ "dwm-session.target" ]; };

          Unit = {
            Description = "XSS Lock Daemon";
            # PartOf = [ "" ];
            After = [ "graphical-session.target" ];
          };

          Service = {
            ExecStart = "${pkgs.xss-lock}/bin/xss-lock -s \${XDG_SESSION_ID} ${
                if cfg.screenlock.timeout.script == null then
                  ""
                else
                  "-n ${cfg.screenlock.timeout.script}"
              } -l -- ${cfg.screenlock.lock.command}";
          };
        };
      };
    }

  ]);
}
