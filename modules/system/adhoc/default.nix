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
      pkgs.taskwarrior
      pkgs.timewarrior
      pkgs.taskwarrior-tui
    ];

    services.tailscale.enable = true;
  };
}
