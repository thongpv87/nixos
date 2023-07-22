{ config, lib, pkgs, ... }:
with lib;
let
  cfg = config.thongpv87.others.gsettings;
  my-gsettings-desktop-schemas =
    let
      defaultPackages = with pkgs; [ gsettings-desktop-schemas gtk3 ];
    in
    pkgs.runCommand "nixos-gsettings-desktop-schemas" { preferLocalBuild = true; }
      ''
        mkdir -p $out/share/gsettings-schemas/nixos-gsettings-overrides/glib-2.0/schemas
        ${concatMapStrings
          (pkg: "cp -rf ${pkg}/share/gsettings-schemas/*/glib-2.0/schemas/*.xml $out/share/gsettings-schemas/nixos-gsettings-overrides/glib-2.0/schemas\n")
          (defaultPackages)}
        # cp -f ${pkgs.gnome.gnome-shell}/share/gsettings-schemas/*/glib-2.0/schemas/*.gschema.override $out/share/gsettings-schemas/nixos-gsettings-overrides/glib-2.0/schemas

        chmod -R a+w $out/share/gsettings-schemas/nixos-gsettings-overrides
        ${pkgs.glib.dev}/bin/glib-compile-schemas $out/share/gsettings-schemas/nixos-gsettings-overrides/glib-2.0/schemas/
      '';
in
{
  options = {
    thongpv87.others.gsettings = {
      enable = mkOption {
        default = false;
      };
    };
  };

  config = mkIf cfg.enable {
    home.packages = with pkgs; [ glib gsettings-desktop-schemas gtk3 ];

    home.sessionVariables = {
      NIX_GSETTINGS_OVERRIDES_DIR = "${my-gsettings-desktop-schemas}/share/gsettings-schemas/nixos-gsettings-overrides/glib-2.0/schemas";
    };
  };
}
