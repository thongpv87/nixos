{ pkgs, config, lib, ... }:
with lib;
let cfg = config.thongpv87.graphical.xorg;
in {
  options.thongpv87.graphical.xorg = {
    enable = mkOption {
      description = "Enable xserver.";
      type = types.bool;
      default = false;
    };
  };

  config = mkIf (config.thongpv87.graphical.enable && cfg.enable) {
    services.xserver = {
      enable = true;
      libinput = { enable = true; };
      displayManager.gdm.enable = true;
    };
  };
}
