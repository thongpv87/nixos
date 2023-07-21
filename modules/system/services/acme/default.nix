{ config, lib, pkgs, ... }:
with lib;
let cfg = config.thongpv87.acme;
in {
  options.thongpv87.acme = {
    email = mkOption {
      description = "Email to register with acme";
      type = types.str;
    };
  };
}
