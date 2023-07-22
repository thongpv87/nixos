{ config, lib, pkgs, ... }:
with lib;
let
  cfg = config.thongpv87.others.shell;
in
{
  imports = [
    ./tmux
    ./bash
    ./zsh
  ];

  options = {
    thongpv87.others.shell = {
      enable = mkOption {
        default = false;
      };
    };
  };

  config = mkIf cfg.enable (mkMerge [
    {
      home.packages = with pkgs; [
        htop
        gtop
        wtf
        nano
        vim
        xclip
        xsel
        curl
        wget
        ix
        inxi
        powertop
        neofetch
        lolcat
        ncurses
        glxinfo
        lshw
        s-tui
        python3
        silver-searcher
        gawk
        ack
        jq
        yq
        gnused
        nix-prefetch-git
        git-crypt
        gnumake
      ];

      programs.git.enable = true;

      thongpv87.others.shell = {
        zsh.enable = true;
        bash.enable = true;
        tmux = {
          enable = true;
          shell = "zsh";
        };
      };
    }
  ]);
}
