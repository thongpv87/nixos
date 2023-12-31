{ inputs, patchedPkgs, }:
{ pkgs, config, lib, ... }:
with lib;
let cfg = config.thongpv87.core;
in {
  options.thongpv87.core = {
    enable = mkOption {
      description = "Enable core options";
      type = types.bool;
      default = true;
    };

    time = mkOption {
      description = "Time zone";
      type = types.enum [ "west" "east" "asia" ];
      default = "east";
    };

    ccache = mkOption {
      description = "Enable ccache";
      type = types.bool;
      default = false;
    };
  };

  config = mkIf (cfg.enable) {
    i18n.defaultLocale = "en_US.UTF-8";
    time.timeZone = if (cfg.time == "east") then
      "US/Eastern"
    else
      (if cfg.time == "west" then "US/Pacific" else cfg.time);

    # Nix search paths/registries from:
    # https://github.com/gytis-ivaskevicius/flake-utils-plus/blob/166d6ebd9f0de03afc98060ac92cba9c71cfe550/lib/options.nix
    # Context thread: https://github.com/gytis-ivaskevicius/flake-utils-plus/blob/166d6ebd9f0de03afc98060ac92cba9c71cfe550/lib/options.nix
    nix = let
      flakes = filterAttrs (name: value: value ? outputs) inputs;
      flakesWithPkgs = filterAttrs (name: value:
        value.outputs ? legacyPackages || value.outputs ? packages) flakes;
      nixRegistry = builtins.mapAttrs (name: v: { flake = v; }) flakes;
    in {
      registry = nixRegistry;
      nixPath = mapAttrsToList (name: _: "${name}=/etc/nix/inputs/${name}")
        flakesWithPkgs;
      package = pkgs.nixUnstable;
      gc = {
        persistent = true;
        automatic = true;
        dates = "weekly";
        options = "--delete-older-than 14d";
      };
      extraOptions = ''
        keep-outputs = true
        keep-derivations = true
        experimental-features = nix-command flakes
      '';
      settings = {
        sandbox = true;
        trusted-users = [ "root" "@wheel" ];
        auto-optimise-store = true;
        # For nixpkgs-wayland: https://github.com/nix-community/nixpkgs-wayland#flake-usage
        substituters = [
          "https://cache.nixos.org"
          "https://nix-community.cachix.org"
          "https://cache.iog.io"
          "https://nixpkgs-wayland.cachix.org"
          "https://eigenvalue.cachix.org"
          "https://nrdxp.cachix.org"

        ];
        trusted-public-keys = [
          "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
          "nixpkgs-wayland.cachix.org-1:3lwxaILxMRkVhehr5StQprHdEo4IrE8sRho9R9HOLYA="
          "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
          "nrdxp.cachix.org-1:Fc5PSqY2Jm1TrWfm88l6cvGWwz3s93c6IOifQWnhNW4="
          "hydra.iohk.io:f/Ea+s+dFdN+3Y/G+FDgSq+a5NEWhJGzdjvKNGv0/EQ="
          "eigenvalue.cachix.org-1:ykerQDDa55PGxU25CETy9wF6uVDpadGGXYrFNJA3TUs="
        ];
      };
    };

    environment = {
      sessionVariables = { EDITOR = "vim"; };
      etc = mapAttrs' (name: value: {
        name = "nix/inputs/${name}";
        value = {
          source =
            if name == "nixpkgs" then patchedPkgs.outPath else value.outPath;
        };
      }) inputs;

      shells = [ pkgs.zsh pkgs.bash ];
      # ZSH completions
      pathsToLink = [ "/share/zsh" ];
      systemPackages = with pkgs; [
        # Misc.
        neofetch
        bat

        # Shells
        zsh

        # Files
        eza
        unzip
        lsof

        # Benchmarking
        hyperfine # benchmark multiple runs of commands

        # Hardware
        inxi # system information tool
        usbutils # tools for usb
        pciutils # tools for pci utils

        # Kernel
        systeroid
        strace

        # Network
        gping # ping with graph
        iftop # bandwith usage on interface
        tcpdump # packet analyzer
        nmap # scan remote ports/networks
        hping # tcp/ip packet assembler & analyzer
        traceroute # track route taken by packets
        ipcalc # ip network calculator

        # DNS
        dnsutils
        dnstop

        # secrets
        rage
        agenix-cli

        # Processors
        jq
        htmlq

        ripgrep
        gawk
        gnused

        # Downloaders
        wget
        curl

        # system monitors
        bottom
        htop
        acpi
        pstree

        # version ocntrol
        git
        git-lfs
        git-filter-repo
        difftastic

        # Nix tools
        patchelf
        nix-index
        nix-tree
        nix-diff
        nix-prefetch
        deploy-rs
        manix
        comma

        # Text editor
        vim

        # Calculator
        bc
        bitwise

        # Scripts
        scripts.sysTools

        # docs
        tldr
        man-pages
        man-pages-posix

        binutils
        coreutils
        curl
        direnv
        dnsutils
        fd
        git
        bottom
        moreutils
        nix-index
        nmap
        ripgrep
        skim
        tealdeer
        whois
        starship
      ];
    };

    environment.shellInit = ''
      export STARSHIP_CONFIG=${
        pkgs.writeText "starship.toml" (fileContents ./starship.toml)
      }
    '';

    security.sudo.extraConfig = "Defaults env_reset,timestamp_timeout=5";
    security.sudo.execWheelOnly = true;

    hardware.enableRedistributableFirmware = true;

    services.udisks2.enable = true;
    services.fwupd.enable = true;

    programs.ccache.enable = cfg.ccache;

    documentation = {
      enable = true;
      dev.enable = true;
      man = {
        enable = true;
        man-db.enable = false;
        mandoc.enable = true;
        generateCaches = true;
      };
      info.enable = true;
      nixos.enable = true;
    };
  };
}
