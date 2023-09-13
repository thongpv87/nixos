{ pkgs, config, lib, ... }: {
  nixpkgs.config.allowUnfree = true;
  virtualisation.virtualbox = { host.enable = true; };
  users.extraGroups.vboxusers.members = [ "thongpv87" ];
}
