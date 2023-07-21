{ pkgs, config, lib, ... }:
with lib;
let
  cfg = config.thongpv87.secrets;
  backup = config.thongpv87.impermanence.persistedDatasets.root.backup;
in {
  options.thongpv87.secrets.identityPaths = mkOption {
    type = with types; listOf str;
    description = "The path to age identities (private key)";
  };

  config = mkMerge [
    { age.identityPaths = cfg.identityPaths; }
    (mkIf config.thongpv87.impermanence.enable {
      environment.persistence.${backup}.files = cfg.identityPaths;
    })
  ];
}
