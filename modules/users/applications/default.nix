{ pkgs, config, lib, ... }:
with lib;
let cfg = config.thongpv87.applications;
in {
  imports = [ ./taskwarrior ./direnv ./syncthing ./neomutt ./emacs ];

  options.thongpv87.applications = {
    enable = mkOption {
      description = "Enable a set of common applications";
      type = types.bool;
      default = false;
    };
  };

  config = mkIf (cfg.enable) {
    home.sessionVariables = { EDITOR = "vim"; };

    xdg.enable = true;

    # TTY compatible CLI applications
    home.packages = with pkgs; [
      home-manager

      # Text editor
      neovimJD

      # ssh mount
      sshfs

      # CLI tools
      glow
      nnn # file manager
      grit # to-do
      buku # bookmarks
      yt-dlp # download youtube
      pdftk # pdf editing
      graphviz # dot

      # Spell checking
      # Setting up dictionary modified from:
      # https://www.thedroneely.com/posts/nixos-in-the-wild/#libreoffice-and-spell-checking
      # https://github.com/NixOS/nixpkgs/issues/14430
      # https://github.com/NixOS/nixpkgs/blob/nixos-22.11/pkgs/development/libraries/hunspell/0001-Make-hunspell-look-in-XDG_DATA_DIRS-for-dictionaries.patch
      hunspell
      hunspellDicts.en_US-large
      hyphen
      nixfmt

      # nixpkgs
      # nixpkgs-review

      # terminal session recorder
      asciinema

      # terminal art
      pipes-rs
      cbonsai

      # Themes
      theme-sh

      # music
      playerctl

      discord
      upwork
      telegram-desktop
      google-cloud-sdk
      openvpn
    ];

    programs.mpv = {
      enable = true;
      config = {
        profile = "gpu-hq";
        vo = "gpu";
        hwdec = "auto-safe";
        ytdl-format =
          "ytdl-format=bestvideo[height<=?1920][fps<=?30][vcodec!=?vp9]+bestaudio/best";
      };
    };

    services.playerctld.enable = true;
  };
}
