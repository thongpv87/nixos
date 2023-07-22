{ config, lib, pkgs, ... }:
let
  selected-nerdfonts = pkgs.nerdfonts.override {
    fonts = [
      "FiraCode"
      "FiraMono"
      "SourceCodePro"
      "DejaVuSansMono"
      "DroidSansMono"
      "Inconsolata"
      "Iosevka"
      "RobotoMono"
      "Terminus"
    ];
    enableWindowsFonts = false;
  };
  mkWriteable = pkgs.writeShellScriptBin "mkWriteable" ''
    fn=$1;
    mv "$fn" "$fn".bk;
    cp "$fn".bk "$fn";
    chmod +w "$fn"
  '';
  theme-sh = pkgs.writeShellScriptBin "theme.sh" ''${builtins.readFile ./theme.sh}'';
in
{
  home.packages = with pkgs; [ starship selected-nerdfonts mkWriteable theme-sh ];

  programs = {
    fzf = {
      enable = true;
      enableBashIntegration = true;
      enableZshIntegration = true;
      enableFishIntegration = true;
      fileWidgetOptions = [ "--preview 'head {}'" ];
    };

    direnv = {
      enable = true;
      nix-direnv = {
        enable = true;
      };
      enableZshIntegration = true;
    };
  };

  #home.sessionVariables = {};

  xdg = {
    enable = true;
    configFile."starship.toml".source = ./starship.toml;
  };
}
