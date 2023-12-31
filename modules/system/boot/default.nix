{ pkgs, config, lib, ... }:
with lib;
let cfg = config.thongpv87.boot;
in {
  options.thongpv87.boot = {
    type = mkOption {
      description = "Type of boot. Default encrypted-efi";
      default = null;
      type = types.enum [ "efi" "bios" ];
    };

    grubDevice = mkOption {
      description = "Grub device";
      default = null;
      type = types.str;
    };
  };

  config = mkMerge [
    (mkIf (cfg.type == "efi") {
      boot = {
        loader = {
          efi = { efiSysMountPoint = "/boot"; };

          grub = {
            enable = true;
            devices = [ "nodev" ];
            efiSupport = true;
            useOSProber = false;
            extraEntries = ''
              menuentry "Reboot" {
                reboot
              }
              menuentry "Power off" {
                halt
              }
            '';
          };
        };
      };
    })
    (mkIf (cfg.type == "bios") {
      boot = {
        loader = {
          grub = {
            enable = true;
            device = cfg.grubDevice;
            efiSupport = false;
          };
        };
      };
    })
  ];
}
