{ config, lib, pkgs, ... }:

with lib;
let
  cfg = config.thongpv87.others.media;
in
{
  imports = [
    #./cli-visualizer
    ./mopidy
    ./ncmpcpp
    ./glava
  ];

  options = {
    thongpv87.others.media = {
      enable = mkOption {
        default = false;
        description = ''
          Whether to enable xmonad bundle
        '';
      };
    };
  };

  config = mkIf cfg.enable (mkMerge [
    {
      home.packages = with pkgs; [
        rhythmbox
        vlc
        shotwell
        pavucontrol
      ];

      thongpv87.others.media.mopidy.enable = true;
      thongpv87.others.media.ncmpcpp.enable = true;
      thongpv87.others.media.glava.enable = true;
      #thongpv87.others.media.cli-visualizer.enable = true;
    }
  ]);
}
