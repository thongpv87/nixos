{ pkgs, config, lib, ... }:
with lib;
let
  cfg = config.thongpv87.applications.syncthing;
  isGraphical = let graphical = config.thongpv87.graphical;
  in graphical.xorg.enable == true || graphical.wayland.enable == true;
in {
  options.thongpv87.applications.syncthing = {
    enable = mkOption {
      description = "Enable syncthing";
      type = types.bool;
      default = false;
    };
  };

  config = mkIf (config.thongpv87.applications.enable && cfg.enable) {
    services.syncthing = {
      enable = true;
      # TODO: fails on service starting during login. Restarting it sets it up correctly
      tray.enable = false;
    };

    systemd.user.services = {
      "syncthingtray" = {
        Unit = {
          Description = "syncthingtray";
          Requires = [ "tray.target" ];
          After = [ "graphical-session-pre.target" "tray.target" ];
          PartOf = [ "graphical-session.target" ];
        };

        Service = {
          # Shitty hack to make syncthingtray wait until tray is initialized
          # --wait does not work on wayland due to:
          # QObject::connect: No such signal QPlatformNativeInterface::systemTrayWindowChanged(QScreen*)
          ExecStartPre = "${pkgs.coreutils}/bin/sleep 0.5";
          ExecStart = "${pkgs.syncthingtray-minimal}/bin/syncthingtray";
        };

        Install = { WantedBy = [ "tray.target" ]; };
      };
    };
  };
}
