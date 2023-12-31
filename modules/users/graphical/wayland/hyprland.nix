{ pkgs, config, lib, ... }:
with lib;
let
  cfg = config.thongpv87.graphical.wayland;
  systemCfg = config.machineData.systemConfig;

  switch-input-method = pkgs.writeShellScriptBin "switch-input-method" ''
    if [ $(ibus engine) == xkb:us::eng ]; then ibus engine Bamboo; else ibus engine xkb:us::eng ; fi
  '';

in {
  options.thongpv87.graphical.wayland = {
    type = mkOption {
      type = types.enum [ "hyprland" ];
      description = "What desktop/wm to use";
    };
  };

  config = mkIf cfg.enable (mkMerge [
    {
      assertions = [{
        assertion = systemCfg.graphical.wayland.enable;
        message = "To enable wayland for user, it must be enabled for system";
      }];

      home.packages = with pkgs; [
        switch-input-method
        pamixer
        dunst
        qt5.qtwayland
        qt6.qtwayland
      ];
      programs = {
        wofi = {
          enable = true;
          settings = {
            layer = "top";
            allow_images = true;
            allow_markup = true;
            mode = "drun";
            matching = "fuzzy";
            insensitive = true;
            key_left = "Control_L-b";
            key_right = "Control_L-f";
            key_up = "Control_L-p";
            key_down = "Control_L-n";
          };
        };
      };

      fonts.fontconfig.enable = true;
      services.copyq = { enable = true; };
    }

    {
      wayland.windowManager.hyprland = {
        enable = true;
        enableNvidiaPatches = true;
        systemdIntegration = true;

        settings = {
          exec-once = [
            "ibus-daemon -d"
            "${pkgs.dunst}/bin/dunst"
            #"${pkgs.wpaperd}/bin/wpaperd"
            "setxkbmap -option altwin:prtsc_rwin -option caps:escape"
          ];

          monitor = [
            "eDP-1,1920x1080@60,960x2160,1"
            "DP-2,3840x2160@30,0x0,1,bitdepth,10"
          ];

          input = {
            kb_layout = "us";
            kb_model = "thinkpad";
            kb_options = "altwin:prtsc_rwin,caps:escape";
            follow_mouse = 1;
            touchpad = { natural_scroll = false; };
            sensitivity = 0; # -1.0 - 1.0, 0 mean no modification
          };

          general = {
            gaps_in = 5;
            gaps_out = 15;
            border_size = 2;
            "col.active_border" = "rgba(33ccffee) rgba(00ff99ee) 45deg";
            "col.inactive_border" = "rgba(595959aa)";

            layout = "master";
          };

          decoration = {
            rounding = 10;
            drop_shadow = true;
            shadow_range = 4;
            shadow_render_power = 3;
            "col.shadow" = "rgba(1a1a1aee)";
          };

          animations = {
            enabled = true;

            # Some default animations, see https://wiki.hyprland.org/Configuring/Animations/ for more

            bezier = "myBezier, 0.05, 0.9, 0.1, 1.05";

            animation = [
              "windows, 1, 7, myBezier"
              "windowsOut, 1, 7, default, popin 80%"
              "border, 1, 10, default"
              "borderangle, 1, 8, default"
              "fade, 1, 7, default"
              "workspaces, 1, 6, default"
            ];
          };

          dwindle = {
            # See https://wiki.hyprland.org/Configuring/Dwindle-Layout/ for more
            pseudotile =
              true; # master switch for pseudotiling. Enabling is bound to mainMod + P in the keybinds section below
            preserve_split = true; # you probably want this
          };

          master = {
            # See https://wiki.hyprland.org/Configuring/Master-Layout/ for more
            new_is_master = true;
            new_on_top = true;
            no_gaps_when_only = 1;
            orientation = "right";
          };

          gestures = { workspace_swipe = true; };

          "$mod" = "SUPER";

          bind = [
            "$mod SHIFT, RETURN, exec, alacritty"
            "$mod SHIFT, C, killactive,"
            "$mod SHIFT, Q, exit,"
            "$mod, RETURN, layoutmsg, swapwithmaster"
            "$mod, J, layoutmsg, cyclenext"
            "$mod, K, layoutmsg, cycleprev"
            "$mod SHIFT,J,layoutmsg,swapnext"
            "$mod SHIFT,K,layoutmsg,swapprev"

            "$mod, B, exec, firefox"
            "$mod, T, togglefloating,"
            "$mod, P, exec, wofi --show drun"
            "$mod, I, pseudo," # dwindle
            "$mod, U, togglesplit," # dwindle
            "$mod, F, fullscreen,1"
            "$mod SHIFT, F, fullscreen,0"
            # media keys
            ",121,exec, pamixer --toggle-mute"
            ",122,exec, pamixer -d 5"
            ",123,exec, pamixer -i 5"

            "$mod,slash,exec,switch-input-method"

            "$mod,W, focusmonitor, DP-2"
            "$mod,E, focusmonitor,eDP-1"

            # Move focus with mod + arrow keys
            "$mod, left, movefocus, l"
            "$mod, right, movefocus, r"
            "$mod, up, movefocus, u"
            "$mod, down, movefocus, d"

            # Switch workspaces with mod + [0-9]
            "$mod,1,moveworkspacetomonitor,1 current"
            "$mod, 1, workspace, 1"
            "$mod,2,moveworkspacetomonitor,2 current"
            "$mod, 2, workspace, 2"
            "$mod,3,moveworkspacetomonitor,3 current"
            "$mod, 3, workspace, 3"
            "$mod,4,moveworkspacetomonitor,4 current"
            "$mod, 4, workspace, 4"
            "$mod,5,moveworkspacetomonitor,5 current"
            "$mod, 5, workspace, 5"
            "$mod,6,moveworkspacetomonitor,6 current"
            "$mod, 6, workspace, 6"
            "$mod,7,moveworkspacetomonitor,7 current"
            "$mod, 7, workspace, 7"
            "$mod,8,moveworkspacetomonitor,8 current"
            "$mod, 8, workspace, 8"
            "$mod,9,moveworkspacetomonitor,9 current"
            "$mod, 9, workspace, 9"
            "$mod,0,moveworkspacetomonitor,10 current"
            "$mod, 0, workspace, 10"
            "$mod, space, togglespecialworkspace,"

            # Move active window to a workspace with mod + SHIFT + [0-9]
            "$mod SHIFT, 1, movetoworkspacesilent, 1"
            "$mod SHIFT, 2, movetoworkspacesilent, 2"
            "$mod SHIFT, 3, movetoworkspacesilent, 3"
            "$mod SHIFT, 4, movetoworkspacesilent, 4"
            "$mod SHIFT, 5, movetoworkspacesilent, 5"
            "$mod SHIFT, 6, movetoworkspacesilent, 6"
            "$mod SHIFT, 7, movetoworkspacesilent, 7"
            "$mod SHIFT, 8, movetoworkspacesilent, 8"
            "$mod SHIFT, 9, movetoworkspacesilent, 9"
            "$mod SHIFT, 0, movetoworkspacesilent, 10"
            "$mod SHIFT, space, movetoworkspacesilent, special"

            # # Scroll through existing workspaces with mod + scroll
            "$mod, mouse_down, workspace, e+1"
            "$mod, mouse_up, workspace, e-1"
          ];
          # Move/resize windows with mod + LMB/RMB and dragging
          bindm =
            [ "$mod, mouse:272, movewindow" "$mod, mouse:273, resizewindow" ];

        };

        extraConfig = ''
          # Execute your favorite apps at launch
          # exec-once = waybar & hyprpaper & firefox
          # Source a file (multi-file configs)
          # source = ~/.config/hypr/myColors.conf

        '';
      };

      xdg.configFile."dunst" = {
        source = ./dunst;
        recursive = true;
      };
    }
  ]);
}
