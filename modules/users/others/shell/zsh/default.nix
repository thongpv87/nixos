{ config, lib, pkgs, ... }:
with lib;
let
  cfg = config.thongpv87.others.shell.zsh;
  aliases = {
    ssh = "TERM=xterm-256color ssh";
    irssi = "TERM=xterm-256color irssi";
    em = "emacsclient -t";
  };
in
{
  imports = [ ../common ];

  options = {
    thongpv87.others.shell.zsh = {
      enable = mkOption {
        default = false;
        description = ''
          Whether to enable zsh bundle
        '';
      };
    };
  };

  config = mkIf cfg.enable {
    home.packages = with pkgs; [ any-nix-shell nix-zsh-completions ];
    programs.zsh = {
      enable = true;
      enableCompletion = true;
      enableAutosuggestions = true;
      autocd = true;
      defaultKeymap = "emacs";
      dotDir = ".config/zsh";

      history = {
        extended = true;
        share = true;
        size = 10000;
      };

      localVariables = { ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE = "fg=3,bold"; };

      shellAliases = aliases;

      initExtra = ''
        if command -v theme.sh > /dev/null; then
          [ -e ~/.theme_history ] && theme.sh "$(theme.sh -l|tail -n1)"
        fi
        any-nix-shell zsh --info-right | source /dev/stdin
        export DIRENV_LOG_FORMAT=
        eval "$(${pkgs.direnv}/bin/direnv hook zsh)"
        source ~/.config/zsh/zshrc_extra
        #(cat ~/.cache/wal/sequences &)
        eval "$(${pkgs.starship}/bin/starship init zsh)"
      '';

      "oh-my-zsh" = {
        enable = true;
        plugins = [
          "git"
          "sudo"
          "gitignore"
          "cp"
          "docker"
          "safe-paste"
          "colored-man-pages"
        ];
      };
    };

    xdg = {
      enable = true;
      configFile."zsh/zshrc_extra".source = ./zshrc_extra;
    };
  };
}
