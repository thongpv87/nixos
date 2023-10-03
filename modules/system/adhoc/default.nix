{ pkgs, config, lib, ... }:
with lib;
let
  cfg = config.thongpv87.adhoc;
  apploye = pkgs.writeScriptBin "apploye" ''
    ${pkgs.appimage-run}/bin/appimage-run ${./Apploye-3.1.12.AppImage}
  '';
in {
  options.thongpv87.adhoc = { enable = mkOption { default = false; }; };
  config = {
    environment.systemPackages = [
      pkgs.clockify
      apploye
      pkgs.python3
      pkgs.taskwarrior
      pkgs.timewarrior
      pkgs.taskwarrior-tui

      pkgs.shellcheck
      pkgs.nodePackages.bash-language-server
    ];

    services.postgresql = {
      enable = true;
      extraPlugins = with pkgs.postgresql.pkgs; [ timescaledb ];
      authentication = pkgs.lib.mkOverride 10 ''
        #type database  DBuser  auth-method
        local all       all     trust
        host  all       all     127.0.0.1       255.255.255.255     trust
      '';
    };

    services.tailscale.enable = true;
  };
}
