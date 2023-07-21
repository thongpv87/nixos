{ pkgs, config, lib, ... }:
with lib;
let cfg = config.thongpv87.secrets;
in {
  options.thongpv87.secrets.identityPaths = mkOption {
    type = with types; listOf str;
    description = "The path to age identities (private key)";
  };

  config = {
    homeage = {
      identityPaths = cfg.identityPaths;
      pkg = pkgs.rage;
    };
  };
}
