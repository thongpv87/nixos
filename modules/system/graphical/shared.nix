{ pkgs, config, lib, ... }:
with lib;
let cfg = config.thongpv87.graphical;
in {
  options.thongpv87.graphical = {
    enable = mkOption {
      type = types.bool;
      default = false;
      description = "Enable wayland";
    };
  };
  config = mkIf cfg.enable (mkMerge [
    {
      environment.systemPackages = with pkgs; [
        # Graphics
        libva-utils
        vdpauinfo
        glxinfo
      ];

      hardware.opengl = {
        enable = true;
        # TODO: remove after https://github.com/NixOS/nixpkgs/pull/223530 reaches nixos-unstable
        mesaPackage = pkgs.mesa;
        extraPackages = with pkgs; [ mesa.drivers ];
      };

      environment.etc = {
        "profile.local".text = builtins.concatStringsSep "\n" ([''
          # /etc/profile.local: DO NOT EDIT -- this file has been generated automatically.
          if [ -f "$HOME/.profile" ]; then
            . "$HOME/.profile"
          fi
        ''] ++ lib.optional
          (cfg.xorg.enable && !config.thongpv87.greetd.enable) ''
            if [ -z "$DISPLAY" ] && [ "''${XDG_VTNR}" -eq 1 ]; then
              exec startx
            fi
          '' ++ lib.optional
          (cfg.wayland.enable && !config.thongpv87.greetd.enable) ''
            if [ -z "$DISPLAY" ] && [ "''${XDG_VTNR}" -eq 2 ]; then
              exec $HOME/.winitrc
            fi
          '');
      };
    }
    (mkIf config.thongpv87.networking.wifi.enable {
      programs.captive-browser = {
        enable = true;
        bindInterface = true;
        interface = config.thongpv87.networking.wifi.interface;
      };
    })
  ]);
}
