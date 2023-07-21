{ pkgs, config, lib, ... }:
with lib;
let cfg = config.jd.hardware.thinkpad-x1e2;
in {
  options.jd.hardware.thinkpad-x1e2 = {
    enable = mkOption {
      description =
        "Whether to enable desktop settings. Also tags as desktop for user settings";
      type = types.bool;
      default = false;
    };
    fancontrol = mkOption {
      type = with types; enum [ "auto" "manual" ];
      default = "auto";
    };

    undervolt = mkOption { default = false; };

    cpuScaling = mkOption {
      type = with types; enum [ "intel_pstate" "intel_cpufreq" "acpi_cpufreq" ];
      description = "CPU performance scaling driver";
      default = "acpi_cpufreq";
    };

  };

  config = mkIf (cfg.enable) (mkMerge [
    {
      boot = {
        # loader = {
        #   systemd-boot.enable = true;
        #   systemd-boot.configurationLimit = 10;
        #   efi.canTouchEfiVariables = true;
        # };
        kernel.sysctl = { "vm.swappiness" = 0; };
        kernelPackages = mkDefault pkgs.linuxPackages;
        initrd.availableKernelModules = [
          "xhci_pci"
          "nvme"
          "usb_storage"
          "sd_mod"
          "battery"
          "thinkpad_acpi"
        ];
        initrd.kernelModules = [ "i915" ];
        kernelModules = [ "kvm-intel" "acpi_call" "coretemp" ];
        blacklistedKernelModules = [ ];
        kernelParams = [ "quiet" "msr.allow_writes=on" "cpuidle.governor=teo" ];

        extraModulePackages = with config.boot.kernelPackages; [ acpi_call ];

      };

      time.timeZone = mkForce "Asia/Ho_Chi_Minh";
      i18n.inputMethod = {
        enabled = "ibus"; # "fcitx";
        ibus.engines = with pkgs.ibus-engines; [ bamboo ];

        # fcitx.engines = [ pkgs.fcitx-engines.unikey ];
        # fcitx5.addons = [ pkgs.fcitx5-unikey ];
      };

      networking = {
        wireless.iwd.enable = true;
        networkmanager = {
          enable = true;
          wifi = {
            powersave = true;
            backend = mkForce "iwd";
          };
        };
      };

      hardware = {
        trackpoint.device = "TPPS/2 Elan TrackPoint";
        opengl = {
          enable = true;
          driSupport32Bit = true;
          extraPackages = with pkgs; [
            hybridVaApiIntel
            vaapiVdpau
            libvdpau-va-gl
            intel-media-driver
            nvidia-vaapi-driver
            libva
          ];
        };
      };

      services = {
        fstrim.enable = true;
        fwupd.enable = true;
        udev.packages = with pkgs; [ gnome.gnome-settings-daemon ];
      };
      console.useXkbConfig = true;

      environment.variables = {
        VDPAU_DRIVER =
          lib.mkIf config.hardware.opengl.enable (lib.mkDefault "va_gl");
        LIBVA_DRIVER_NAME = "nvidia";
        MOZ_DISABLE_RDD_SANDBOX = "1";
      };
      hardware.cpu.intel.updateMicrocode =
        lib.mkDefault config.hardware.enableRedistributableFirmware;

    }

    {
      services.upower.enable = true;

      boot.initrd.availableKernelModules = [ "battery" "thinkpad_acpi" ];
      boot.kernelModules = [ "acpi_call" "coretemp" ];
      boot.extraModulePackages = with config.boot.kernelPackages; [ acpi_call ];

      boot.kernelParams = if (cfg.cpuScaling == "intel_pstate") then
        [ ]
      else if (cfg.cpuScaling == "intel_cpufreq") then
        [ "intel_pstate=passive" ]
      else if (cfg.cpuScaling == "acpi_cpufreq") then
        [ "intel_pstate=disable" ]
      else
        [ ];
      boot.extraModprobeConfig = lib.mkMerge [
        # enable wifi power saving (keep uapsd off to maintain low latencies)
        "options iwlwifi power_save=1 uapsd_disable=1"
      ];

      # Gnome 40 introduced a new way of managing power, without tlp.
      # However, these 2 services clash when enabled simultaneously.
      # https://github.com/NixOS/nixos-hardware/issues/260
      services.power-profiles-daemon.enable = false;
      services.tlp = {
        enable = true;
        # settings = # { "CPU_SCALING_GOVERNOR_ON_AC" = "schedutil"; };
        settings = let
          governor = (if (cfg.cpuScaling != "schedutil") then
            "powersave"
          else
            "schedutil");
          cpuScaling = (if (cfg.cpuScaling == "acpi_cpufreq") then {
            CPU_SCALING_GOVERNOR_ON_AC = mkForce "schedutil";
            CPU_SCALING_GOVERNOR_ON_BAT = mkForce "schedutil";

            # Don't not use this setting with intel_pstate scaling driver, use CPU_MIN/MAX_PERF_ON_AC/BAT instead
            CPU_SCALING_MIN_FREQ_ON_AC = 800000;
            CPU_SCALING_MAX_FREQ_ON_AC = mkForce 3500000;
            CPU_SCALING_MIN_FREQ_ON_BAT = mkForce 800000;
            CPU_SCALING_MAX_FREQ_ON_BAT = mkForce 2300000;
          } else if (cfg.cpuScaling == "intel_cpufreq") then {
            CPU_SCALING_GOVERNOR_ON_AC = mkForce "schedutil";
            CPU_SCALING_GOVERNOR_ON_BAT = mkForce "schedutil";

            # Set Intel CPU HWP.EPP /EPB policy
            CPU_ENERGY_PERF_POLICY_ON_AC = mkForce "default";
            CPU_ENERGY_PERF_POLICY_ON_BAT = mkForce "power";

            # Set min/max P-state for intel CPUs, min/max from min_perf_pct
            CPU_MIN_PERF_ON_AC = mkForce 17;
            CPU_MAX_PERF_ON_AC = mkForce 89;
            CPU_MIN_PERF_ON_BAT = mkForce 17;
            CPU_MAX_PERF_ON_BAT = mkForce 55;
            CPU_HWP_DYN_BOOST_ON_AC = mkForce 1;
            CPU_HWP_DYN_BOOST_ON_BAT = mkForce 0;

          } else if (cfg.cpuScaling == "intel_pstate") then {
            CPU_SCALING_GOVERNOR_ON_AC = mkForce "powersave";
            CPU_SCALING_GOVERNOR_ON_BAT = mkForce "powersave";
          } else
            { });
        in lib.mkMerge [
          cpuScaling

          {
            START_CHARGE_THRESH_BAT0 = mkForce 75;
            STOP_CHARGE_THRESH_BAT0 = mkForce 80;

            CPU_BOOST_ON_AC = mkForce 1;
            CPU_BOOST_ON_BAT = mkForce 0;
            # Minimize number of CPU cores under light load conditions
            SCHED_POWER_SAVE_ON_AC = mkForce 0;
            SCHED_POWER_SAVE_ON_BAT = mkForce 1;

            NMI_WATCHDOG = mkForce 0;

            # Enable audio power saving for Intel HDA, AC97 devices (timeout in secs).
            # A value of 0 disables, >=1 enables power saving (recommended: 1).
            # Default: 0 (AC), 1 (BAT)
            SOUND_POWER_SAVE_ON_AC = mkForce 0;
            SOUND_POWER_SAVE_ON_BAT = mkForce 0;

            # Radio device switching
            DEVICES_TO_DISABLE_ON_BAT_NOT_IN_USE = mkForce "bluetooth wwan";

            PLATFORM_PROFILE_ON_BAT = mkForce "low-power";
            # Runtime Power Management for PCI(e) bus devices: on=disable, auto=enable.
            # Default: on (AC), auto (BAT)
            RUNTIME_PM_ON_AC = mkForce "auto";
            RUNTIME_PM_ON_BAT = mkForce "auto";
            RUNTIME_PM_ENABLE = mkForce "01:00.0";

            # Battery feature drivers: 0=disable, 1=enable
            # Default: 1 (all)
            NATACPI_ENABLE = mkForce 1;
            TPACPI_ENABLE = mkForce 1;
            TPSMAPI_ENABLE = mkForce 1;

            # Bluetooth devices are excluded from USB autosuspend:
            #   0=do not exclude, 1=exclude
            USB_BLACKLIST_BTUSB = mkForce 1;
          }
        ];
      };
    }

    (mkIf (cfg.fancontrol == "manual") {
      boot.initrd.availableKernelModules = [ "battery" "thinkpad_acpi" ];
      boot.kernelModules = [ "acpi_call" "coretemp" ];

      services.thinkfan = {
        enable = true;
        fans = [{
          type = "tpacpi";
          query = "/proc/acpi/ibm/fan";
        }];

        sensors = [{
          query = "/proc/acpi/ibm/thermal";
          type = "tpacpi";
        }];

        levels = [
          [ 0 0 44 ]
          [ 1 44 50 ]
          [ 2 47 55 ]
          [ 3 51 60 ]
          [ 4 54 65 ]
          [ 5 58 70 ]
          [ 6 60 75 ]
          [ 7 59 85 ]
          [ "level auto" 80 32767 ]
        ];
      };
    })

    (mkIf cfg.undervolt {
      services.undervolt = {
        enable = true;
        coreOffset = -120;
        gpuOffset = -90;
        uncoreOffset = -70;
      };
    })

  ]);
}
