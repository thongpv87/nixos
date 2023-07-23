{ pkgs, config, lib, ... }:
with lib;
let cfg = config.thongpv87.others;
in {
  imports = [
    # ./develop
    ./emacs
    ./fonts
    ./gsettings
    ./media
    ./others
    ./xmonad
  ];

  options.thongpv87.others.enable = mkOption {
    type = types.bool;
    default = false;
  };

  config = mkIf cfg.enable {
    thongpv87.others = {
      #hyprland.enable = mkDefault false;
      xmonad = {
        enable = mkDefault false;
        rofi.enable = true;
        theme = "simple";
      };

      # develop.haskell.enable = mkDefault true;
      # develop.agda.enable = mkDefault true;
      fonts.enable = mkDefault true;
      others.enable = mkDefault true;
      emacs.enable = mkDefault true;
      gsettings.enable = mkDefault true;
      #mime.enable = mkDefault false;
      media.glava.enable = mkDefault true;
    };
  };
}
