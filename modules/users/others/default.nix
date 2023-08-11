{ pkgs, config, lib, ... }:
with lib;
let cfg = config.thongpv87.others;
in {
  imports = [
    # ./develop
    ./media
    ./others
  ];

  options.thongpv87.others.enable = mkOption {
    type = types.bool;
    default = false;
  };

  config = mkIf cfg.enable {
    thongpv87.others = {
      # develop.haskell.enable = mkDefault true;
      # develop.agda.enable = mkDefault true;
      others.enable = mkDefault true;
      #mime.enable = mkDefault false;
      media.glava.enable = mkDefault true;
    };
  };
}
