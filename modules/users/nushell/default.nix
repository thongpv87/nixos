{ pkgs, config, lib, ... }:
with lib;
let cfg = config.thongpv87.zsh;
in {
  options.thongpv87.nushell = {
    enable = mkOption {
      description = "Enable zsh with settings";
      type = types.bool;
      default = false;
    };
  };

  config = mkIf (cfg.enable) (let
  in {
    programs = {
      starship.enableNushellIntegration = true;
      direnv.enableNushellIntegration = true;

      nushell = {
        enable = true;
        configFile.source = ./_config.nu;
        envFile.source = ./_env.nu;
      };
    };
  });
}
