{ pkgs, config, lib, ... }: {
  imports = [
    ./applications
    ./graphical
    ./git
    ./gpg
    ./zsh
    ./nushell
    ./ssh
    ./office365
    ./wine
    ./keybase
    ./pijul
    ./secrets
    ./weechat
    ./terminal
    ./others
  ];
}
