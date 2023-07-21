{ pkgs, config, lib, ... }:
with lib;
let cfg = config.thongpv87.applications.neomutt;
in {
  options.thongpv87.applications.neomutt = {
    enable = mkOption {
      description = "Enable neomutt";
      type = types.bool;
      default = false;
    };
  };

  config = mkIf (config.thongpv87.applications.enable && cfg.enable) {
    programs.neomutt = { enable = true; };
  };
}
