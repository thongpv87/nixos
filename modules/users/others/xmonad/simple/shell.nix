{ pkgs ? import <nixpkgs> {} }:
pkgs.mkShell {
  buildInputs = with pkgs.xorg; with pkgs.haskellPackages;
    [ libX11 libXext libXinerama
      libXrandr libXrender libXft
      libXScrnSaver pkgs.alsa-lib
      pkgs.pkg-config pkgs.xscreensaver
      libXdmcp.dev pkgs.expat.dev libXpm pkgs.wirelesstools
      haskell-language-server hlint cabal-install
    ] ++

    [ xmonad
      xmonad-contrib
      xmonad-extras
      xmobar
      containers
      directory
      X11
      async
      stm
    ];
}
