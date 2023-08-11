{ pkgs, config, lib, ... }:
with lib;
let cfg = config.thongpv87.connectivity;
in {
  options.thongpv87.connectivity = {
    bluetooth.enable = mkOption {
      description = "Enable bluetooth with default options";
      type = types.bool;
      default = false;
    };

    printing.enable = mkOption {
      description = "Enable printer";
      type = types.bool;
      default = false;
    };

    sound.enable = mkOption {
      description = "Enable sound";
      type = types.bool;
      default = false;
    };
  };

  config = mkMerge [
    {
      environment.systemPackages = with pkgs;
        optional cfg.bluetooth.enable scripts.bluetoothTools
        ++ optionals cfg.sound.enable [ pulseaudio scripts.soundTools ];

      security.rtkit.enable = cfg.sound.enable;
      services.pipewire = mkIf (cfg.sound.enable) {
        enable = true;
        alsa.enable = true;
        alsa.support32Bit = true;
        pulse.enable = true;
        jack.enable = true;
      };
    }

    mkIf
    cfg.printing.enable
    {
      services.printing.enable = true;
      services.avahi.enable = true;
      services.avahi.nssmdns = true;
      # for a WiFi printer
      services.avahi.openFirewall = true;
    }

    mkIf
    cfg.bluetooth.enable
    {
      hardware.bluetooth.enable = true;
      services.blueman.enable = true;
    }
  ];
}
