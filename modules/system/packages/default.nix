{ config, pkgs, lib, ... }: {
  programs = {
    dconf.enable = true;
    iftop.enable = true;
    iotop.enable = true;
    nano.syntaxHighlight = true;
    zsh.enable = true;
  };

  services = {
    teamviewer.enable = false;
    usbmuxd.enable = true;
  };

  environment = {
    systemPackages = with pkgs; [
      #utilities packages
      killall
      git
      lm_sensors
      pciutils
      hexchat
      upower
      unzip
      alacritty
      tmux
      bash-completion
      sqlite
      htop
      iotop
      neofetch
      ntfs3g
      zsh
      fish
      xclip
      xsel
      gnused
      gawkInteractive

      emacs
      nano
      vim
      neovim
      wget
      ascii
      file
      okular
      goldendict
      shared-mime-info
      firefox
      google-chrome
      libreoffice-fresh
      evince
      notify-osd
      libnotify

      fira
      roboto
      fira-code
      fira-mono
      font-awesome
      fira-code-symbols
      inconsolata
      corefonts
      mononoki
      google-fonts
      roboto-slab

      nix-index
      nixfmt
      nix-zsh-completions

      config.boot.kernelPackages.bcc

      # iOS mounting
      libimobiledevice
      ifuse
    ];
    pathsToLink = [ "/share/zsh" ];
  };
}
