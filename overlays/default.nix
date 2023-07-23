{ pkgs, nixpkgs-stable, nur, dwm-flake, deploy-rs, neovim-flake, st-flake
, dwl-flake, scripts, homeage, system, lib, jdpkgs, impermanence
, nixpkgs-wayland, agenix, secrets, }: {
  overlays = [
    nur.overlay
    dwl-flake.overlays.default
    scripts.overlay

    (self: super: {
      waybar = nixpkgs-wayland.packages.${super.system}.waybar;

      # Version of xss-lock that supports logind SetLockedHint
      xss-lock = super.xss-lock.overrideAttrs (old: {
        src = super.fetchFromGitHub {
          owner = "xdbob";
          repo = "xss-lock";
          rev = "7b0b4dc83ff3716fd3051e6abf9709ddc434e985";
          sha256 = "TG/H2dGncXfdTDZkAY0XAbZ80R1wOgufeOmVL9yJpSk=";
        };
      });

      selected-nerdfonts = super.nerdfonts.override {
        fonts = [
          "FiraCode"
          "FiraMono"
          "SourceCodePro"
          "DejaVuSansMono"
          "DroidSansMono"
          "Inconsolata"
          "Iosevka"
          "RobotoMono"
          "JetBrainsMono"
          "Terminus"
        ];
        enableWindowsFonts = false;
      };

      bamboo = pkgs.ibus-engines.bamboo.overrideAttrs (oldAttrs: {
        version = "v0.8.1";
        src = pkgs.fetchFromGitHub {
          owner = "BambooEngine";
          repo = "ibus-bamboo";
          rev = "c0001c571d861298beb99463ef63816b17203791";
          sha256 = "sha256-7qU3ieoRPfv50qM703hEw+LTSrhrzwyzCvP9TOLTiDs=";
        };
        buildInputs = oldAttrs.buildInputs ++ [ pkgs.glib pkgs.gtk3 ];
      });

      # Commented out because need to update the patch
      # xorg = prev.xorg // {
      #   # Override xorgserver with patch to set x11 type
      #   xorgserver = lib.overrideDerivation prev.xorg.xorgserver (drv: {
      #     patches = drv.patches ++ [ ./x11-session-type.patch ];
      #   });
      # };

      inherit (import ../configs/editor.nix super
        neovim-flake.lib.neovimConfiguration)
        neovimJD;
      dwmJD = dwm-flake.packages.${system}.dwmJD;
      stJD = st-flake.packages.${system}.stJD;
      weechatJD = super.weechat.override {
        configure = { availablePlugins, ... }: {
          scripts = with super.weechatScripts; [ weechat-matrix ];
        };
      };
      agenix-cli = agenix.packages."${system}".default;
      deploy-rs = deploy-rs.packages."${system}".deploy-rs;
      jdpkgs = jdpkgs.packages."${system}";
      # bm-font = super.callPackage (secrets + "/bm") {};
      inherit homeage impermanence;
    })
  ];
}
