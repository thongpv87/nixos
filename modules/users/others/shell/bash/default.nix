{ config, lib, pkgs, ... }:
with lib;
let
  cfg = config.thongpv87.others.shell.bash;
  aliases = {
    ssh = "TERM=xterm-256color ssh";
    irssi = "TERM=xterm-256color irssi";
    em = "emacsclient -t";
  };
in
{
  imports = [ ../common ];

  options = {
    thongpv87.others.shell.bash = {
      enable = mkOption {
        default = false;
        description = ''
          Whether to enable bash bundle
        '';
      };
    };
  };

  config = mkIf cfg.enable {
    home.packages = with pkgs; [ bash-completion ];

    programs.bash = {
      enable = true;
      historyControl = [ "ignoredups" ];
      shellAliases = aliases;
      initExtra = ''
        eval "$(starship init bash)"
      '';
    };
  };
}
