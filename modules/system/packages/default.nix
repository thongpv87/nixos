{ config, pkgs, lib, ... }: {
  programs = {
    dconf.enable = true;
    iftop.enable = true;
    iotop.enable = true;
    nano.syntaxHighlight = true;
    zsh.enable = true;
  };

  services = {
    teamviewer.enable = true;
    usbmuxd.enable = true;
  };

  environment = {
    systemPackages = with pkgs; [
      #utilities packages
      killall
      pciutils
      htop
      iotop
      neofetch
      ntfs3g
      gnused
      gawkInteractive

      wget
      ascii
      file
      shared-mime-info
      firefox
      google-chrome
      libreoffice-fresh
      nixfmt

      config.boot.kernelPackages.bcc

      # iOS mounting
      libimobiledevice
      ifuse
    ];
    pathsToLink = [ "/share/zsh" ];
  };
}
