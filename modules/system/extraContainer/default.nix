{ pkgs, config, lib, ... }:
with lib; {
  options.thongpv87.extraContainer = {
    enable = mkOption {
      description = "Enable extra-container";
      type = types.bool;
      default = false;
    };
  };
}
