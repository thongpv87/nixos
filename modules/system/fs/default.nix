{ pkgs, config, lib, ... }:
with lib;
let cfg = config.thongpv87.fs;
in {
  options.thongpv87.fs = {
    type = mkOption {
      description = "Type of boot. Default encrypted-efi";
      default = null;
      type = types.enum [ "ext4" "encrypted-efi" "zfs" "zfs-v2" ];
    };

    hostId = mkOption {
      # Generate with:
      # head -c4 /dev/urandom | od -A none -t x4
      description = "HostID, needed for server-zfs";
      default = null;
      type = types.str;
    };

    zfs = {
      userPool = mkEnableOption "a user pool";

      swap = {
        enable = mkEnableOption "zfs swap";

        swapPartuuid = mkOption {
          description = "Swap part uuid, needed for server-zfs";
          default = null;
          type = types.str;
        };
      };
    };
  };

  config = let
    fsConfig = mkMerge [
      (mkIf (cfg.type == "ext4") {
        fileSystems."/" = {
          device = "/dev/disk/by-label/EXT4_ROOT";
          fsType = "ext4";
        };

        fileSystems."/boot" = {
          device = "/dev/disk/by-label/EXT4_BOOT";
          fsType = "vfat";
        };

        swapDevices = [{ device = "/dev/disk/by-label/EXT4_SWAP"; }];
      })

      (mkIf (cfg.type == "encrypted-efi") {
        environment.systemPackages = with pkgs; [ e2fsprogs ];
        fileSystems."/" = {
          device = "/dev/disk/by-label/DECRYPTNIXROOT";
          fsType = "ext4";
        };

        fileSystems."/boot" = {
          device = "/dev/disk/by-label/BOOT";
          fsType = "vfat";
        };

        swapDevices = [{ device = "/dev/disk/by-label/DECRYPTNIXSWAP"; }];

        boot = {
          # plymouth.enable = true;
          initrd = {
            # systemd.enable = true;
            luks.devices = {
              cryptkey = { device = "/dev/disk/by-label/NIXKEY"; };

              cryptroot = {
                device = "/dev/disk/by-label/NIXROOT";
                keyFile = "/dev/mapper/cryptkey";
              };

              cryptswap = {
                device = "/dev/disk/by-label/NIXSWAP";
                keyFile = "/dev/mapper/cryptkey";
              };
            };
          };
        };
      })

      # ZFS sources
      # https://nixos.wiki/wiki/ZFS
      # https://elis.nu/blog/2019/08/encrypted-zfs-mirror-with-mirrored-boot-on-nixos/
      # https://florianfranke.dev/posts/2020/03/installing-nixos-with-encrypted-zfs-on-a-netcup.de-root-server/
      (mkIf (cfg.type == "zfs" || cfg.type == "zfs-v2") {
        boot = {
          supportedFilesystems = [ "zfs" ];
          zfs.requestEncryptionCredentials = true;
        };

        services.zfs.trim.enable = true;
        services.zfs.autoScrub.enable = true;
        services.zfs.autoScrub.pools = [ "rpool" ];

        networking.hostId = cfg.hostId;

        fileSystems."/boot" = {
          device = "/dev/disk/by-label/BOOT";
          fsType = "vfat";
        };

        swapDevices = lib.optional (cfg.zfs.swap.enable) {
          device = "/dev/disk/by-partuuid/${cfg.zfs.swap.swapPartuuid}";
          randomEncryption = true;
        };
      })

      (mkIf
        ((cfg.type == "zfs" || cfg.type == "zfs-v2") && !cfg.zfs.swap.enable) {
          boot.kernelParams = [ "nohibernate" ];
        })

      (mkIf (cfg.type == "zfs-v2") (mkMerge [
        {
          thongpv87.impermanence.rollbackDatasets =
            [ "rpool/local" "rpool/local/root" "rpool/local/home" ];

          thongpv87.impermanence.persistedDatasets = {
            "root" = { };
            "data" = { };
          };

          fileSystems."/" = {
            device = "rpool/local";
            fsType = "zfs";
            neededForBoot = true;
          };

          fileSystems."/root" = {
            device = "rpool/local/root";
            fsType = "zfs";
            neededForBoot = true;
          };

          fileSystems."/home" = {
            device = "rpool/local/home";
            fsType = "zfs";
            neededForBoot = true;
          };

          fileSystems."/nix" = {
            device = "rpool/persist/nix";
            fsType = "zfs";
            neededForBoot = true;
          };

          fileSystems."/persist/root" = {
            device = "rpool/persist/root";
            fsType = "zfs";
            neededForBoot = true;
          };

          fileSystems."/persist/data" = {
            device = "rpool/persist/data";
            fsType = "zfs";
            neededForBoot = true;
          };

          fileSystems."/backup/root" = {
            device = "rpool/backup/root";
            fsType = "zfs";
            neededForBoot = true;
          };

          fileSystems."/backup/data" = {
            device = "rpool/backup/data";
            fsType = "zfs";
            neededForBoot = true;
          };
        }
        (mkIf cfg.zfs.userPool {
          fileSystems."/home/thongpv87" = {
            device = "rpool/local/home/thongpv87";
            fsType = "zfs";
          };

          fileSystems."/persist/home/thongpv87" = {
            device = "rpool/persist/home/thongpv87";
            fsType = "zfs";
          };

          fileSystems."/backup/home/thongpv87" = {
            device = "rpool/backup/home/thongpv87";
            fsType = "zfs";
          };
        })
      ]))
      (mkIf (cfg.type == "zfs") {
        thongpv87.impermanence.rollbackDatasets =
          [ "rpool/local/root" "rpool/local/home" ];

        thongpv87.impermanence.persistedDatasets = {
          "root" = {
            persist = "/persist";
            backup = "/persist";
          };
          "data" = { backup = "/persist/data"; };
        };

        fileSystems."/" = {
          device = "rpool/local/root";
          fsType = "zfs";
        };

        fileSystems."/home" = {
          device = "rpool/local/home";
          fsType = "zfs";
        };

        fileSystems."/nix" = {
          device = "rpool/local/nix";
          fsType = "zfs";
          neededForBoot = true;
        };

        fileSystems."/persist" = {
          device = "rpool/persist/root";
          fsType = "zfs";
          neededForBoot = true;
        };

        fileSystems."/persist/home" = {
          device = "rpool/persist/home";
          fsType = "zfs";
          neededForBoot = true;
        };

        fileSystems."/persist/data" = {
          device = "rpool/persist/data";
          fsType = "zfs";
          neededForBoot = true;
        };
      })
    ];
  in fsConfig;
}
