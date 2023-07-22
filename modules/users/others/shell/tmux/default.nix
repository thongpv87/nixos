{ config, lib, pkgs, ... }:
with lib;
let
  cfg = config.thongpv87.others.shell.tmux;
  shellCmd =
    if cfg.shell == "zsh" then "${pkgs.zsh}/bin/zsh"
    else if cfg.shell == "bash" then "${pkgs.bashInteractive}/bin/bash"
    else #if cfg.shell == "fish"
      "${pkgs.fish}/bin/fish";
in
{
  options = {
    thongpv87.others.shell.tmux = {
      enable = mkOption {
        default = false;
        description = ''
          Whether to enable tmux module
        '';
      };

      shell = mkOption {
        type = with types; enum [ "bash" "zsh" "fish" ];
        default = "zsh";
      };
    };
  };


  config = mkIf cfg.enable (
    mkMerge [
      {
        home.packages = [ pkgs.xsel ];
        programs.tmux = {
          enable = true;
          plugins = with pkgs.tmuxPlugins; [
            #resurrect
            sensible
            #yank
            prefix-highlight
            pain-control
            # {
            #   plugin = tmux-colors-solarized;
            #   extraConfig = ''
            #     set -g @colors-solarized 'dark'
            #   '';
            # }
          ];
          baseIndex = 1;
          shortcut = "o";
          customPaneNavigationAndResize = true;
          keyMode = "vi";
          newSession = true;
          secureSocket = false;
          terminal = "xterm-256color";

          extraConfig = ''
            set-option  -g default-shell ${shellCmd}
            set -s copy-command 'xsel -ib'
            ${readFile ./bindings.conf}
            ${readFile ./tmux.conf}
            ${readFile ./gruvbox-dark.conf}
          '';
        };
      }
    ]);
}
