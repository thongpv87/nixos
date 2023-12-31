{
  description = "System Config";
  inputs = {
    # Package repositories
    nixpkgs.url = "nixpkgs/nixos-unstable";
    nixpkgs-stable.url = "nixpkgs/nixos-23.05";

    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    nur.url = "github:nix-community/NUR";

    nixpkgs-wayland.url = "github:nix-community/nixpkgs-wayland";

    jdpkgs.url = "github:jordanisaacs/jdpkgs";
    jdpkgs.inputs.nixpkgs.follows = "nixpkgs";

    # Extra nix/nixos modules
    impermanence.url = "github:nix-community/impermanence";

    disko.url = "github:nix-community/disko";
    disko.inputs.nixpkgs.follows = "nixpkgs";

    simple-nixos-mailserver.url =
      "gitlab:simple-nixos-mailserver/nixos-mailserver";
    simple-nixos-mailserver.inputs.nixpkgs.follows = "nixpkgs";
    simple-nixos-mailserver.inputs.utils.follows = "flake-utils";

    flake-utils.url = "github:numtide/flake-utils";

    deploy-rs.url = "github:serokell/deploy-rs";
    deploy-rs.inputs.nixpkgs.follows = "nixpkgs";
    deploy-rs.inputs.utils.follows = "flake-utils";

    # Secrets
    # secrets.url = "git+ssh://git@github.com/jordanisaacs/secrets.git?ref=main";
    secrets.url = "git+file:///home/thongpv87/Code/secret";
    secrets.inputs.nixpkgs.follows = "nixpkgs";

    agenix.url = "github:ryantm/agenix";
    agenix.inputs.nixpkgs.follows = "nixpkgs";

    homeage.url = "github:jordanisaacs/homeage";
    homeage.inputs.nixpkgs.follows = "nixpkgs";

    microvm-nix = {
      url = "github:astro/microvm.nix";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.flake-utils.follows = "flake-utils";
    };

    hyprland = {
      url = "github:hyprwm/Hyprland/main";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Programs
    neovim-flake.url = "github:jordanisaacs/neovim-flake";

    st-flake.url = "github:jordanisaacs/st-flake";
    st-flake.inputs.nixpkgs.follows = "nixpkgs";
    st-flake.inputs.flake-utils.follows = "flake-utils";

    dwm-flake.url = "github:jordanisaacs/dwm-flake";

    dwl-flake.url = "github:jordanisaacs/dwl-flake";
  };

  outputs = { self, nixpkgs, nixpkgs-stable, jdpkgs, impermanence, deploy-rs
    , agenix, microvm-nix, nixpkgs-wayland, secrets, home-manager, nur
    , neovim-flake, simple-nixos-mailserver, st-flake, dwm-flake, dwl-flake
    , homeage, hyprland, ... }@inputs:
    let
      inherit (nixpkgs) lib;

      util = import ./lib {
        inherit system nixpkgs pkgs home-manager lib overlays patchedPkgs
          inputs;
      };

      scripts = import ./scripts { inherit pkgs lib; };

      inherit (import ./overlays {
        inherit system pkgs lib nur neovim-flake st-flake dwm-flake homeage
          scripts jdpkgs dwl-flake impermanence deploy-rs agenix nixpkgs-wayland
          nixpkgs-stable secrets;
      })
        overlays;

      inherit (util) user;
      inherit (util) host;
      inherit (util) utils;

      system = "x86_64-linux";

      # How to patch nixpkgs, from https://github.com/NixOS/nix/issues/3920#issuecomment-681187597
      remoteNixpkgsPatches = [ ];
      localNixpkgsPatches = [
        # nix-index evaluates all of nixpkgs. Thus, it evaluates a package
        # that purposefully throws an error because mesos was removed.
        # Patch nixpkgs to remove the override.
        ./nixpkgs-patches/mesos.patch
      ];
      originPkgs = nixpkgs.legacyPackages.${system};
      patchedPkgs = nixpkgs;
      # patchedPkgs = originPkgs.applyPatches {
      #   name = "nixpkgs-patched";
      #   src = nixpkgs;
      #   patches = map originPkgs.fetchpatch remoteNixpkgsPatches ++ localNixpkgsPatches;
      #   postPatch = ''
      #     patch=$(printf '%s\n' ${builtins.concatStringsSep " "
      #       (map (p: p.sha256) remoteNixpkgsPatches ++ localNixpkgsPatches)} |
      #       sort | sha256sum | cut -c -7)
      #     echo "+patch-$patch" >.version-suffix
      #   '';
      # };
      pkgs = import patchedPkgs {
        inherit system overlays;
        config = {
          permittedInsecurePackages = [
            "electron-9.4.4"
            "electron-11.5.0"
            #"qtwebkit-5.212.0-alpha4"
          ];
          allowUnfree = true;
        };
      };

      authorizedKeys = ''
        ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPKIspidvrzy1NFoUXMEs1A2Wpx3E8nxzCKGZfBXyezV mail@jdisaacs.com
      '';

      authorizedKeyFiles = pkgs.writeTextFile {
        name = "authorizedKeys";
        text = authorizedKeys;
      };

      wireguardConf = {
        enable = true;
        interface = "thevoid";
        peers = {
          intothevoid = let wgsecret = secrets.wireguard.intothevoid;
          in {
            wgAddrV4 = "10.55.1.1";
            publicKey = wgsecret.publicKey;

            tags = [{ name = "net"; }];
          };

          chairlift = let wgsecret = secrets.wireguard.chairlift;
          in {
            wgAddrV4 = "10.55.0.2";
            interfaceMask = 16;
            listenPort = 51820;

            privateKeyPath = "/etc/wireguard/private_key";
            privateKeyAge = wgsecret.secret.file;
            publicKey = wgsecret.publicKey;
            dns = "server";

            tags = [{
              name = "net";
              ipAddr = "5.161.103.90";
            }];
          };
        };
      };

      defaultUser = {
        name = "thongpv87";
        groups = [ "wheel" ];
        uid = 1000;
        # Fixes assertion issue: https://github.com/NixOS/nixpkgs/pull/211603
        shell = "${pkgs.zsh}/bin/zsh";
      };

      defaultDesktopUser = defaultUser // {
        groups = defaultUser.groups
          ++ [ "networkmanager" "video" "libvirtd" "audio" "docker" ];
      };

      defaultServerConfig = {
        core.enable = true;
        boot.type = "bios";
        fs.type = "zfs";
        users.mutableUsers = false;
        ssh = {
          enable = true;
          type = "server";
          authorizedKeys = [ (builtins.toString authorizedKeys) ];
          initrdKeys = [ authorizedKeys ];
        };
        networking = { firewall.enable = true; };
        impermanence.enable = true;
      };

      chairliftConfig = utils.recursiveMerge [
        defaultServerConfig
        {
          users.rootPassword = secrets.passwords.chairlift;
          isQemuGuest = true;
          boot.grubDevice = "/dev/sda";
          fs = {
            hostId = "2d360981";
            zfs.swap = {
              swapPartuuid = "5ab489de-583d-4e5b-a6b4-3c08e799a217";
              enable = true;
            };
          };
          secrets.identityPaths = [ secrets.age.chairlift.privateKeyPath ];
          wireguard = wireguardConf;
          networking = {
            static = {
              enable = true;
              interface = "enp1s0";
              ipv6.addr = "2a01:4ff:f0:865b::1/64";
              ipv4 = {
                addr = "5.161.103.90/32";
                gateway = "172.31.1.1";
                onlink = true;
              };
            };
          };
          ssh = {
            firewall = "wg";
            hostKeyAge = secrets.ssh.host.chairlift.secret.file;
          };
          acme.email = secrets.acme.email;
          monitoring.enable = false;
          microbin.enable = true;
          calibre.web.enable = true;
          syncthing = {
            relay.enable = false;
            discovery.enable = false;
          };
          languagetool.enable = false;
          mailserver = with secrets.mailserver; {
            enable = true;
            inherit fqdn sendingFqdn domains;
            loginAccounts = builtins.mapAttrs (name: value: {
              hashedPasswordFile = value.hashedPassword.secret.file;
              aliases = value.aliases;
              sendOnly = lib.mkIf (value ? sendOnly) value.sendOnly;
            }) loginAccounts;
          };
          miniflux = {
            enable = true;
            adminCredsFile = secrets.miniflux.adminCredentials.secret.file;
          };
          taskserver = {
            enable = true;
            address = "10.55.0.2";
            fqdn = "chairlift.wg";
            firewall = "wg";
          };
          ankisyncd = {
            # build is broken
            enable = false;
            address = "10.55.0.2";
            firewall = "wg";
          };
          proxy = {
            enable = true;
            firewall = "wg";
            address = "10.55.0.2";
          };
          unbound = {
            enable = true;
            access = "wg";
            enableWGDomain = true;
          };
        }
      ];

      defaultClientConfig = {
        core = {
          enable = true;
          ccache = true;
        };
        users.users = [ defaultDesktopUser ];
        gnome = {
          enable = true;
          keyring = { enable = true; };
        };
        connectivity = {
          bluetooth.enable = true;
          sound.enable = true;
          printing.enable = true;
        };
        networking = {
          firewall = {
            enable = true;
            allowKdeconnect = false;
            allowDefaultSyncthing = false;
          };
          wifi.enable = true;
        };
        graphical = {
          enable = true;
          xorg.enable = true;
          wayland = {
            enable = true;
            waylockPam = true;
            swaylockPam = true;
          };
        };

        # greetd.enable = true;

        ssh = {
          enable = true;
          type = "client";
        };
        extraContainer.enable = false;
      };

      serverConfig = utils.recursiveMerge [
        defaultClientConfig
        {
          core.time = "Asia/Ho_Chi_Minh";
          users.mutableUsers = false;
          boot.type = "efi";
          fs = {
            type = "zfs-v2";
            hostId = "f5db52d8";
          };
          desktop.enable = true;
          impermanence.enable = true;
          greetd.enable = true;
          wireguard = wireguardConf;
          waydroid.enable = true;
          secrets.identityPaths = [ secrets.age.desktop.system.privateKeyPath ];
        }
      ];

      thinkpad-config = utils.recursiveMerge [
        defaultClientConfig
        {
          boot.type = "efi";
          fs = { type = "ext4"; };
          adhoc.enable = true;

          laptop.enable = true;
          secrets.identityPaths = [ "" ];
          networking.interfaces = [ "wlan0" ];
          graphical.desktop-env = {
            kde.enable = false;
            xmonad.enable = true;
          };

          system.hardware.thinkpad-x1e2 = {
            enable = true;
            fancontrol = "manual";
            undervolt = false;
            # cpuScaling = "acpi_cpufreq";
            cpuScaling = "intel_cpufreq";
            xorg = {
              enable = true;
              gpuMode = "integrated";
            };
          };

          dropbox.enable = false;
        }
      ];

      thinkpad-config-zfs = utils.recursiveMerge [
        thinkpad-config
        {
          fs = {
            type = "zfs-v2";
            hostId = "3c86a521";
            zfs = {
              autoSnapshot = {
                enable = true;
                weekly = 4;
                monthly = 12;
                daily = 7;
                hourly = 48;
                frequent = 8;
                flags = "-k -p --utc";
              };

              swap = {
                swapPartuuid = "219fbc7c-2149-414a-8dd3-5477574886cf";
                enable = true;
              };
            };
          };

          graphical.desktop-env = {
            kde.enable = false;
            xmonad.enable = true;
          };
        }
      ];

      thinkpad-config-zfs-wayland = utils.recursiveMerge [
        thinkpad-config-zfs
        {
          system.hardware.thinkpad-x1e2 = { xorg.enable = false; };
          graphical.desktop-env = { kde.enable = false; };
        }
      ];

    in {
      installMedia = {
        kde = host.mkISO {
          name = "nixos";
          kernelPackage = pkgs.linuxPackages_latest;
          initrdMods =
            [ "xhci_pci" "ahci" "usb_storage" "sd_mod" "nvme" "usbhid" ];
          kernelMods = [ "kvm-intel" "kvm-amd" ];
          kernelParams = [ ];
          systemConfig = { };
        };
      };

      homeManagerConfigurations = {
        thongpv87 = user.mkHMUser {
          userConfig = {
            graphical = {
              enable = true;
              theme = "breeze";
              mime.enable = true;
              applications = {
                enable = true;
                firefox.enable = true;
                rofi.enable = true;
                libreoffice.enable = true;
                anki = {
                  enable = false;
                  sync = false;
                };
                kdeconnect.enable = false;
              };
              wayland = {
                enable = false;
                type = "hyprland";
                background = { enable = false; };
                statusbar = { enable = true; };
                screenlock = {
                  enable = false;
                  type = "swaylock";
                };
              };
              xorg = {
                enable = true;
                xmonad = {
                  enable = true;
                  theme = "simple";
                };
                xmobar.enable = true;

                screenlock.enable = false;
              };
            };
            applications = {
              enable = true;
              direnv.enable = true;
              syncthing.enable = false;
              neomutt.enable = false;
              emacs.enable = true;
              # taskwarrior = {
              #   enable = false;
              #   server = {
              #     enable = true;
              #     key = secrets.taskwarrior.client.key.secret.file;
              #     ca = secrets.taskwarrior.client.ca.secret.file;
              #     cert = secrets.taskwarrior.client.cert.secret.file;
              #     credentials = secrets.taskwarrior.credentials;
              #   };
              # };
            };

            terminal = {
              enable = true;
              tmux = {
                enable = true;
                shell = "zsh";
              };
            };

            secrets.identityPaths = [
              "~/.ssh/id_rsa"
              # secrets.age.user.thongpv87.privateKeyPath
            ];
            gpg.enable = true;
            git = {
              enable = true;
              allowedSignerFile = builtins.toString authorizedKeyFiles;
            };
            zsh.enable = true;
            nushell.enable = true;
            ssh.enable = true;
            weechat.enable = false;
            office365 = {
              enable = false;
              onedriver.enable = false; # pkg currently broken
            };
            wine = {
              enable = false; # wine things currently broken
              office365 = false;
            };
            keybase.enable = false;
            pijul.enable = false;
            others.enable = true;
          };
          username = "thongpv87";
        };
      };

      nixosConfigurations = {
        thinkpad = host.mkHost {
          name = "thinkpad";
          kernelPackage = lib.mkForce pkgs.linuxPackages_latest;
          initrdMods = [
            "xhci_pci"
            "nvme"
            "usb_storage"
            "sd_mod"
            "battery"
            "thinkpad_acpi"
            "i915"
          ];
          kernelMods = [ "kvm-intel" "acpi_call" "coretemp" ];
          kernelParams =
            [ "quiet" "msr.allow_writes=on" "cpuidle.governor=teo" ];
          kernelPatches = [ ];
          systemConfig = thinkpad-config;
          cpuCores = 12;
          stateVersion = "23.05";
        };

        thinkpad-zfs = host.mkHost {
          name = "thinkpad";
          kernelPackage = pkgs.zfs.latestCompatibleLinuxPackages;
          initrdMods = [
            "xhci_pci"
            "nvme"
            "usb_storage"
            "sd_mod"
            "battery"
            "thinkpad_acpi"
            "i915"
          ];
          kernelMods = [ "kvm-intel" "acpi_call" "coretemp" ];
          kernelParams =
            [ "quiet" "msr.allow_writes=on" "cpuidle.governor=teo" ];
          kernelPatches = [ ];
          systemConfig = thinkpad-config-zfs;
          cpuCores = 12;
          stateVersion = "23.05";
        };

        thinkpad-zfs-wayland = host.mkHost {
          name = "thinkpad";
          kernelPackage = pkgs.zfs.latestCompatibleLinuxPackages;
          initrdMods = [
            "xhci_pci"
            "nvme"
            "usb_storage"
            "sd_mod"
            "battery"
            "thinkpad_acpi"
            "i915"
          ];
          kernelMods = [ "kvm-intel" "acpi_call" "coretemp" ];
          kernelParams =
            [ "quiet" "msr.allow_writes=on" "cpuidle.governor=teo" ];
          kernelPatches = [ ];
          systemConfig = thinkpad-config-zfs-wayland;
          cpuCores = 12;
          stateVersion = "23.05";
        };

        openvpn-aws = host.mkHost {
          name = "desktop";
          kernelPackage = pkgs.zfs.latestCompatibleLinuxPackages;
          kernelParams = [ "nohibernate" ];
          initrdMods =
            [ "nvme" "xhci_pci" "ahci" "usb_storage" "usbhid" "sd_mod" ];
          kernelMods = [ "kvm-amd" ];
          kernelPatches = [ ];
          systemConfig = serverConfig;
          cpuCores = 12;
          stateVersion = "21.11";
        };

        deploy.nodes.openvpn-aws = {
          hostname = "10.0.0.10";
          sshOpts = [ "-p" "23" ];
          autoRollback = true;
          magicRollback = true;
          profiles = {
            system = {
              sshUser = "root";
              user = "root";
              path = deploy-rs.lib.x86_64-linux.activate.nixos
                self.nixosConfigurations.openvpn-aws;
            };
          };
        };

        checks = builtins.mapAttrs
          (system: deployLib: deployLib.deployChecks self.deploy) deploy-rs.lib;
      };
    };
}
