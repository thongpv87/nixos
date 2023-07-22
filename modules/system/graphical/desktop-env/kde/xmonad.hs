{-# LANGUAGE RecordWildCards #-}

module Main where

import Control.Monad (void)
import qualified Data.Map as M
import Graphics.X11.ExtraTypes.XF86
import XMonad.Util.Replace
import Graphics.X11.Xlib.Display
import Graphics.X11.Xlib.Types
import Data.Char
import XMonad
import XMonad
  ( Default (def),
    ManageHook,
    X,
    XConfig (..),
    appName,
    className,
    composeAll,
    doFloat,
    doIgnore,
    doShift,
    mod4Mask,
    resource,
    spawn,
    xmonad,
    (-->),
    (<+>),
    (=?),
  )
import XMonad.Actions.Volume (lowerVolume, raiseVolume, toggleMute)
import XMonad.Config.Xfce(xfceConfig)
import XMonad.Hooks.DynamicLog
  ( PP (..),
    filterOutWsPP,
    shorten,
    wrap,
    xmobarBorder,
    xmobarColor,
    xmobarRaw,
    xmobarStrip,
  )
import XMonad.Hooks.EwmhDesktops (ewmh)
import XMonad.Hooks.ManageDocks (ToggleStruts (..), avoidStruts, manageDocks)
import XMonad.Hooks.ManageHelpers
  ( doCenterFloat,
    doFullFloat,
    isDialog,
    isFullscreen,
  )
import XMonad.Hooks.RefocusLast (refocusLastLogHook)
import XMonad.Hooks.StatusBar (statusBarProp, withSB)
import XMonad.Hooks.WallpaperSetter
  ( Wallpaper (..),
    WallpaperConf (..),
    WallpaperList (..),
    defWallpaperConf,
    wallpaperSetter,
  )
import XMonad.Layout (Mirror (..), Tall (..))
import XMonad.Layout.Fullscreen (fullscreenManageHook)
import XMonad.Layout.Gaps (Direction2D (..), GapMessage (..), gaps)
import XMonad.Layout.LimitWindows (limitWindows)
import XMonad.Layout.Magnifier as LM (MagnifyMsg (..), MagnifyThis (..), magnifierOff, magnifiercz', magnifierczOff', magnify)
import XMonad.Layout.MultiToggle as LMT (EOT (..), Toggle (..), mkToggle, single, (??))
import XMonad.Layout.MultiToggle.Instances (StdTransformers (..))
import XMonad.Layout.Named (named)
import XMonad.Layout.NoBorders (smartBorders)
import XMonad.Layout.PerScreen (ifWider)
import XMonad.Layout.PerWorkspace (onWorkspace)
import XMonad.Layout.Reflect (REFLECTX (..), REFLECTY (..), reflectHoriz, reflectVert)
import XMonad.Layout.SimplestFloat (simplestFloat)
import XMonad.Layout.Spacing (Border (..), spacingRaw, toggleWindowSpacingEnabled)
import XMonad.Layout.ThreeColumns (ThreeCol (..))
import XMonad.Layout.ToggleLayouts (toggleLayouts)
import XMonad.Layout.ToggleLayouts as LTL
  ( ToggleLayout (..),
  )
import XMonad.Layout.ShowWName
import XMonad.ManageHook
import qualified XMonad.StackSet as W
import XMonad.Util.EZConfig
import XMonad.Util.ExclusiveScratchpads (ExclusiveScratchpad, hideAll, mkXScratchpads, scratchpadAction)
import XMonad.Util.Loggers (logTitles)
import XMonad.Util.NamedScratchpad
import XMonad.Util.NamedScratchpad (namedScratchpadManageHook, nsHideOnFocusLoss, scratchpadWorkspaceTag)
import XMonad.Util.SpawnOnce (spawnOnce)

------------------ COMMON --------------------------
data MyWorkspace
  = Cmd
  | Web
  | Code
  | Doc
  | Tasks
  | Mail
  | Media
  | Remote
  | Float
  deriving (Show, Eq, Enum, Bounded)

wsName :: MyWorkspace -> String
wsName Cmd = "\62601"
wsName Web = "\63288"
wsName Code = "\58911"
wsName Doc = "\57995"
wsName Tasks = "\61953"
wsName Mail = "\63215"
wsName Media = "\xf001"
wsName Remote = "\63074"
wsName Float = "\xf313"

myWorkspaces :: [MyWorkspace]
myWorkspaces = [minBound :: MyWorkspace .. maxBound]

myWorkspaceNames :: [String]
myWorkspaceNames = fmap toLower . show <$> myWorkspaces

------------------- CONFIG --------------------------
data DisplayConfig = DisplayConfig
  { dcPrimary :: !Bool,
    dcEnable :: !Bool,
    dcOutput :: !String,
    dcPosX :: !Integer,
    dcPosY :: !Integer,
    dcWidth :: !Integer,
    dcHeight :: !Integer
  }
  deriving (Show, Eq)

data XMobarPlacement
  = OnAllDisplay
  | OnPrimaryDisplay
  | OnSecondaryDisplay
  deriving (Show, Eq, Enum, Bounded)

data XMobarTheme
  = XMobarThemeSimple
  deriving (Show, Eq)

data DisplayMode
  = DisplayOff
  | DisplayOn
  deriving (Show)

data DualDisplayMode
  = IntegratedDisplayOnly
  | ExternalDisplayOnly
  | DualDisplayVertical
  | DualDisplayHorizontal
  deriving (Show, Eq)

data XMonadConfig = XMonadConfig
  { xcDisplay :: !Display,
    xcXMobarPlacement :: !XMobarPlacement,
    xcXMobarTheme :: !XMobarTheme,
    xcDualDisplayMode :: !DualDisplayMode
  }
  deriving (Show)

mkDefaultXMonadConfig :: IO XMonadConfig
mkDefaultXMonadConfig = do
  xcDisplay <- openDisplay ""
  let xcXMobarPlacement = OnAllDisplay
      xcXMobarTheme = XMobarThemeSimple
      xcDualDisplayMode = IntegratedDisplayOnly
  pure $ XMonadConfig {..}

------------------ LAYOUTS --------------------------
basicTallLayout :: Tall a
basicTallLayout = Tall nmaster delta ratio
  where
    nmaster = 1
    delta = 3 / 100
    ratio = 3 / 5

tallLayout =
  named "Tall" $
    -- LM.magnifierczOff' 1.5 $ -- LM.magnifierOff $ -- LM.magnifiercz' 1.5
    LM.magnify 1.5 (NoMaster 1) False $
      mkToggle (single MIRROR) $
        mkToggle (single REFLECTX) $
          mkToggle (single REFLECTY) $
            limitWindows 4 $
              reflectHoriz $
                basicTallLayout

verticalLayout =
  named "Vert" $
    LM.magnifiercz' 1.5 $
      reflectVert $
        limitWindows 5 $
          Mirror $
            XMonad.Layout.ThreeColumns.ThreeCol 1 (3 / 100) 0.4

toggleGapsLayout layout = toggleLayouts layout (addGaps layout)

toggleFullScreenLayout =
  mkToggle (NBFULL ?? EOT)
    . avoidStruts
    . mkToggle (single FULL)

addGaps layout =
  gaps [(L, 20), (R, 20), (U, 24), (D, 20)] $
    spacingRaw True (Border 0 0 0 0) False (Border 5 10 10 10) True layout

tallOrFull =
  smartBorders
    . toggleFullScreenLayout
    . onWorkspace (wsName Float) simplestFloat
    $ layouts
  where
    layouts =
      ifWider 1920 (ifWider 3800 (toggleGapsLayout tallLayout) verticalLayout) tallLayout

centerFloatMedium = customFloating $ W.RationalRect (1 / 4) (1 / 4) (2 / 4) (2 / 4)

centerFloatBig = customFloating $ W.RationalRect (1 / 8) (1 / 8) (6 / 8) (6 / 8)

nsOpenDoc pdf = NS pdf (concat ["evince --class \"", pdf, "\" -f \"/home/thongpv87/", pdf, "\""]) (className =? pdf)

namedScratchpads :: [NamedScratchpad]
namedScratchpads =
  [ NS "file-manager" "alacritty -t ns-file-manager -e ranger" (title =? "ns-file-manager") centerFloatMedium,
    NS "terminal" "alacritty -t ns-terminal -e tmux new-session -A -s scratch" (title =? "ns-terminal") centerFloatBig,
    NS "emacs" spawnEmacs (title =? "ns-emacs") centerFloatBig,
    nsOpenDoc "Documents/vi-vim-tutorial.pdf" centerFloatBig,
    nsOpenDoc "Documents/Vim cheatsheet.pdf" centerFloatBig
  ]
  where
    spawnEmacs = "emacsclient -a -n -c --frame-parameters='(quote (name . \"ns-emacs\"))'"

namedScratchpadKeymaps c =
  mkKeymap
    c
    [ ("M-s f", namedScratchpadAction namedScratchpads "file-manager"),
      ("M-s t", namedScratchpadAction namedScratchpads "terminal"),
      ("M-s e", namedScratchpadAction namedScratchpads "emacs"),
      ("M-s 1", namedScratchpadAction namedScratchpads "~/Documents/Vim cheatsheet.pdf"),
      ("M-s 2", namedScratchpadAction namedScratchpads "~/Documents/vi-vim-tutorial.pdf")
    ]

exclusiveScratchPads :: [ExclusiveScratchpad]
exclusiveScratchPads =
  mkXScratchpads
    [ ("file-manager", "alacritty -t ns-file-manager -e ranger", title =? "ns-file-manager"),
      ("terminal", "alacritty -t ns-terminal -e tmux new-session -A -s scratch", title =? "ns-terminal"),
      ("emacs", spawnEmacs, title =? "ns-emacs")
    ]
    centerFloatBig
  where
    spawnEmacs = "emacsclient -a -n -c --frame-parameters='(quote (name . \"ns-emacs\"))'"

exclusiveScratchPadKeymaps c =
  mkKeymap
    c
    [ ("M-s f", scratchpadAction exclusiveScratchPads "file-manager"),
      ("M-s t", scratchpadAction exclusiveScratchPads "terminal"),
      ("M-s e", scratchpadAction exclusiveScratchPads "emacs"),
      ("M-s s", hideAll exclusiveScratchPads)
    ]

------------------- MAIN ----------------------------

data Terminal
  = Alacritty
  | GnomeTerminal

instance Show Terminal where
  show Alacritty = "alacritty"
  show GnomeTerminal = "gnome-terminal"

-- mkXConfig :: XMonadConfig -> XConfig l
mkXConfig XMonadConfig {..} =
  ewmh $ xfceConfig
    { terminal = show Alacritty,
      modMask = mod4Mask,
      clickJustFocuses = True,
      focusFollowsMouse = False,
      borderWidth = 2,
      normalBorderColor = "#3b4252",
      focusedBorderColor = "#E57254", -- "#E95065"
      keys = myKeyBindings,
      mouseBindings = myMouseBindings,
      workspaces = myWorkspaceNames,
      manageHook = myManageHook,
      layoutHook = showWName' myShowWNameTheme tallOrFull,
      startupHook = myStartupHook,
      logHook = refocusLastLogHook >> nsHideOnFocusLoss namedScratchpads
    }

myShowWNameTheme :: SWNConfig
myShowWNameTheme = def
  { swn_font              = "xft:FiraCode Nerd Font:style=regular:size=60"
  , swn_fade              = 1.0
  , swn_bgcolor           = "#1c1f24"
  , swn_color             = "#ffffff"
  }

statusbarPP :: PP
statusbarPP =
  filterOutWsPP [scratchpadWorkspaceTag] $
    def
      { ppSep = blue " | ",
        ppTitleSanitize = xmobarStrip,
        ppCurrent = yellow . xmobarBorder "Top" "#8be9fd" 2 . wsSpacing,
        ppVisible = yellow . wsSpacing,
        ppHidden = white . wsSpacing,
        ppHiddenNoWindows = gray . wsSpacing,
        ppUrgent = red . wrap (yellow "!") (yellow "!"),
        ppOrder = \[ws, l, _, wins] -> [ws, l],
        ppExtras = [logTitles formatFocused formatUnfocused]
      }
  where
    formatFocused = wrap (white "[") (white "]") . magenta . ppWindow
    formatUnfocused = wrap (lowWhite "[") (lowWhite "]") . blue . ppWindow

    -- Windows should have *some* title, which should not not exceed a
    -- sane length.
    ppWindow :: String -> String
    ppWindow = xmobarRaw . (\w -> if null w then "untitled" else w) . shorten 30

    blue, lowWhite, magenta, red, white, gray, yellow :: String -> String
    magenta = xmobarColor "#ff79c6" ""
    blue = xmobarColor "#bd93f9" ""
    white = xmobarColor "#fbfbf8" ""
    yellow = xmobarColor "#f1fa8c" ""
    red = xmobarColor "#ff5555" ""
    gray = xmobarColor "#666666" ""
    lowWhite = xmobarColor "#bbbbbb" ""
    wsSpacing = wrap "" " "

xfceWsPP :: PP
xfceWsPP=
  filterOutWsPP [scratchpadWorkspaceTag] $
    def
      { ppSep = " ",
        ppTitleSanitize = xmobarStrip,
        ppCurrent = id,
        ppVisible = id,
        ppHidden = id,
        ppHiddenNoWindows = const "",
        ppUrgent = red . wrap (yellow "!") (yellow "!"),
        ppOrder = \[ws, l, _, wins] -> [ws, l],
        ppExtras = [logTitles formatFocused formatUnfocused]
      }
  where
    formatFocused = wrap (white "[") (white "]") . magenta . ppWindow
    formatUnfocused = wrap (lowWhite "[") (lowWhite "]") . blue . ppWindow

    -- Windows should have *some* title, which should not not exceed a
    -- sane length.
    ppWindow :: String -> String
    ppWindow = xmobarRaw . (\w -> if null w then "untitled" else w) . shorten 30

    blue, lowWhite, magenta, red, white, gray, yellow :: String -> String
    magenta = xmobarColor "#ff79c6" ""
    blue = xmobarColor "#bd93f9" ""
    white = xmobarColor "#fbfbf8" ""
    yellow = xmobarColor "#f1fa8c" ""
    red = xmobarColor "#ff5555" ""
    gray = xmobarColor "#666666" ""
    lowWhite = xmobarColor "#bbbbbb" ""
    wsSpacing = wrap "" " "




myManageHook :: ManageHook
myManageHook =
  fullscreenManageHook
    <+> manageHook xfceConfig
    <+> manageDocks
    <+> composeAll
      [ className =? "confirm" --> doFloat,
        className =? "file_progress" --> doFloat,
        className =? "dialog" --> doFloat,
        className =? "download" --> doFloat,
        className =? "error" --> doFloat,
        className =? "notification" --> doFloat,
        className =? "pinentry-gtk-2" --> doFloat,
        className =? "splash" --> doFloat,
        className =? "toolbar" --> doFloat,
        className =? "org.gnome.Nautilus" --> doCenterFloat,
        className =? "music-hub" --> doCenterFloat,
        appName =? "Music" --> doCenterFloat,
        className =? "Thunderbird" --> shiftToWs Mail,
        className =? "Gnome-calculator" --> doCenterFloat,
        className =? "Pavucontrol" --> doCenterFloat,
        className =? "Gimp" --> doFloat,
        className =? "Xmessage" --> doCenterFloat,
        resource =? "desktop_window" --> doIgnore,
        resource =? "kdesktop" --> doIgnore,
        className =? "trayer" --> doIgnore,
        isDialog --> doCenterFloat,
        isFullscreen --> doFullFloat
      ]
    <+> namedScratchpadManageHook namedScratchpads
  where
    shiftToWs = doShift . wsName

myStartupHook :: X ()
myStartupHook = do
  -- spawnOnce "systemctl --user start emacs"
  -- spawn "xrandr --setprovideroutputsource modesetting NVIDIA-0 && autorandr --change"
  -- spawn "ibus-daemon"
  spawn "xsetroot -cursor_name left_ptr"
  spawn "setxkbmap -model thinkpad -layout us -option caps:escape -option altwin:prtsc_rwin"
  -- spawn "systemctl --user start random-background"

main :: IO ()
main = do
  replace
  myConfig <- mkDefaultXMonadConfig
  let cfg = mkXConfig myConfig
  getDirectories >>= launch cfg

------------------ KEY BINDINGS -------------------------
myMouseBindings (XConfig {XMonad.modMask = modm}) =
  M.fromList
    -- mod-button1, Set the window to floating mode and move by dragging
    [ ((modm, button1), \w -> focus w >> mouseMoveWindow w >> windows W.shiftMaster),
      -- mod-button2, Raise the window to the top of the stack
      ((modm, button2), \w -> focus w >> windows W.shiftMaster),
      -- mod-button3, Set the window to floating mode and resize by dragging
      ((modm, button3), \w -> focus w >> mouseResizeWindow w >> windows W.shiftMaster)
      -- you may also bind events to the mouse scroll wheel (button4 and button5)
    ]

myKeyBindings :: XConfig Layout -> M.Map (KeyMask, KeySym) (X ())
myKeyBindings conf@(XConfig {XMonad.modMask = modm}) =
  M.fromList $
    -- launch a terminal
    [ ((modm .|. shiftMask, xK_Return), spawn $ XMonad.terminal conf),
      -- launch rofi and dashboard
      ((modm, xK_p), spawn "launcher"),
      -- , ((modm,               xK_o     ), calcPrompt dtXPConfig' "qalc")

      -- Toggle the status bar gap
      -- Use this binding with avoidStruts from Hooks.ManageDocks.
      -- See also the statusBar function from Hooks.DynamicLog.
      --
      ((modm, xK_b), sendMessage ToggleStruts),
      -- Quit xmonad
      ((modm .|. shiftMask, xK_q), spawn "powermenu"),
      -- Restart xmonad
      ((modm, xK_q), restart "xmonad" True),
      ((0, xF86XK_Display), spawn "autorandr --change"),
      -- Screenshot
      ((modm, xK_backslash), spawn "maimcopy"),
      ((modm .|. shiftMask, xK_backslash), spawn "maimclip"),
      ((modm .|. controlMask, xK_backslash), spawn "maimscreen"),
      -- others customized shortcuts
      ((modm .|. shiftMask, xK_u), spawn "toggle-glava toggle"),
      ((modm, xK_u), spawn "toggle-glava restart"),
      ((modm, xK_v), sendMessage LM.Toggle),
      ((modm, xK_f), sendMessage $ LMT.Toggle FULL),
      ((modm .|. shiftMask, xK_f), sendMessage $ LMT.Toggle NBFULL),
      ((modm, xK_z), sendMessage $ LMT.Toggle MIRROR),
      ((modm, xK_y), sendMessage $ LMT.Toggle REFLECTX),
      ((modm, xK_x), sendMessage $ LMT.Toggle REFLECTY),
      ((modm, xK_slash), spawn "switch-input-method"),
      -- Audio keys
      ((0, xF86XK_AudioPlay), spawn "playerctl play-pause"),
      ((0, xF86XK_AudioPrev), spawn "playerctl previous"),
      ((0, xF86XK_AudioNext), spawn "playerctl next"),
      ((0, xF86XK_AudioRaiseVolume), void (raiseVolume 3)),
      ((0, xF86XK_AudioLowerVolume), void (lowerVolume 3)),
      ((0, xF86XK_AudioMute), void toggleMute),
      -- , ((0,                    xF86XK_AudioRaiseVolume), spawn "~/.xmonad/bin/raise-volume.sh")
      -- , ((0,                    xF86XK_AudioLowerVolume), spawn "pactl set-sink-volume @DEFAULT_SINK@ -5%")
      -- , ((0,                    xF86XK_AudioMute), spawn "pactl set-sink-mute 0 toggle")

      -- Brightness keys
      ((0, xF86XK_MonBrightnessUp), spawn "brightnessctl -d intel_backlight s +5% || xbacklight + 5%"),
      ((0, xF86XK_MonBrightnessDown), spawn "brightnessctl -d intel_backlight s 5%- || xbacklight - 5%"),
      -- close focused window
      ((modm .|. shiftMask, xK_c), kill),
      -- GAPS!!!
      ((modm .|. shiftMask, xK_g), sendMessage ToggleGaps >> toggleWindowSpacingEnabled), -- toggle all spacing
      ((modm, xK_g), sendMessage ToggleLayout), -- toggle all spacing

      -- Rotate through the available layout algorithms
      ((modm, xK_space), sendMessage NextLayout),
      --  Reset the layouts on the current workspace to default
      ((modm .|. shiftMask, xK_space), setLayout $ XMonad.layoutHook conf),
      -- Resize viewed windows to the correct size
      ((modm, xK_n), refresh),
      -- Move focus to the next window
      ((modm, xK_Tab), windows W.focusDown),
      -- Move focus to the next window
      ((modm, xK_j), windows W.focusDown),
      -- Move focus to the previous window
      ((modm, xK_k), windows W.focusUp),
      -- Move focus to the master window
      ((modm, xK_m), windows W.focusMaster),
      -- Swap the focused window and the master window
      ((modm, xK_Return), windows W.swapMaster),
      -- Swap the focused window with the next window
      ((modm .|. shiftMask, xK_j), windows W.swapDown),
      -- Swap the focused window with the previous window
      ((modm .|. shiftMask, xK_k), windows W.swapUp),
      -- Shrink the master area
      ((modm, xK_h), sendMessage Shrink),
      -- Expand the master area
      ((modm, xK_l), sendMessage Expand),
      -- Push window back into tiling
      ((modm, xK_t), withFocused $ windows . W.sink),
      -- Increment the number of windows in the master area
      ((modm, xK_comma), sendMessage (IncMasterN 1)),
      -- Deincrement the number of windows in the master area
      ((modm, xK_period), sendMessage (IncMasterN (-1)))
    ]
      ++
      --
      -- mod-[1..9], Switch to workspace N
      -- mod-shift-[1..9], Move client to workspace N
      --
      [ ((m .|. modm, k), windows $ f i)
        | (i, k) <- zip (XMonad.workspaces conf) [xK_1 .. xK_9],
          (f, m) <- [(W.greedyView, 0), (W.shift, shiftMask)]
      ]
      ++
      --
      -- mod-{w,e,r}, Switch to physical/Xinerama screens 1, 2, or 3
      -- mod-shift-{w,e,r}, Move client to screen 1, 2, or 3
      --
      [ ((m .|. modm, key), screenWorkspace sc >>= flip whenJust (windows . f))
        | (key, sc) <- zip [xK_w, xK_e, xK_r] [0 ..],
          (f, m) <- [(W.view, 0), (W.shift, shiftMask)]
      ]
      ++ M.toList (namedScratchpadKeymaps conf)
