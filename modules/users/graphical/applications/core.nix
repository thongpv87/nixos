{ pkgs, config, lib, ... }:
with lib;
let
  cfg = config.thongpv87.graphical;
  systemCfg = config.machineData.systemConfig;
in {
  options.thongpv87.graphical.applications = {
    enable = mkOption {
      type = types.bool;
      default = false;
      description = "Enable graphical applications";
    };
  };

  config = mkIf (cfg.applications.enable) {
    home.packages = with pkgs;
      [
        dolphin # fixes dbus/firefox
        okular
        xorg.xinput

        microsoft-edge

        # updated version with wayland/grim backend
        jdpkgs.flameshot
        libsixel

        # Password manager
        bitwarden
        jdpkgs.authy

        # Reading
        calibre

        # Video conference
        zoom-us

        # Note taking
        xournalpp
        rnote

        # Sound
        pavucontrol
        pasystray

        # music
        rhythmbox

        # kdeconnect
      ] ++ lib.optional systemCfg.networking.wifi.enable pkgs.iwgtk;
  };
}
