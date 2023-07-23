{ config, lib, pkgs, ... }:
with lib;
let cfg = config.thongpv87.others.fonts;
in {
  options = { thongpv87.others.fonts.enable = mkOption { default = false; }; };

  config = mkIf cfg.enable {
    fonts.fontconfig.enable = true;

    home.packages = with pkgs; [
      corefonts
      google-fonts
      roboto-slab

      fira-code
      source-code-pro
      fira-mono
      fira-code-symbols
      inconsolata
      emacs-all-the-icons-fonts
      font-awesome
      selected-nerdfonts
      #powerline-fonts
    ];

    xdg.dataFile = {
      "fonts/CascadiaMono" = {
        source = ./myfonts/CascadiaMono;
        recursive = true;
      };
      "fonts/Cousine" = {
        source = ./myfonts/Cousine;
        recursive = true;
      };
      "fonts/DankMono" = {
        source = ./myfonts/DankMono;
        recursive = true;
      };
      "fonts/Menlo" = {
        source = ./myfonts/Menlo;
        recursive = true;
      };
      "fonts/MonoLisa" = {
        source = ./myfonts/MonoLisa;
        recursive = true;
      };
      "fonts/OperatorMono" = {
        source = ./myfonts/OperatorMono;
        recursive = true;
      };
    };
  };
}
