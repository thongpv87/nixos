{ pkgs, config, lib, ... }:
with lib;
let cfg = config.thongpv87.waydroid;
in {
  options.thongpv87.waydroid.enable = mkOption {
    description = "Enable waydroid, requires wayland for running gui";
    default = false;
    type = types.bool;
  };

  config = mkIf (cfg.enable) {
    # https://nixos.wiki/wiki/WayDroid
    virtualisation.waydroid.enable = true;
    system.requiredKernelConfig = with config.lib.kernelConfig;
      [ (isEnabled "MEMFD") ];
  };
}
