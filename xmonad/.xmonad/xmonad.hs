
-- TODO:
-- +) Clean out imports

import Control.Monad

import XMonad
import XMonad.Config.Xfce
import XMonad.Hooks.DynamicLog
import XMonad.Hooks.ManageDocks
import XMonad.Util.Run(spawnPipe)
import XMonad.Util.EZConfig
import XMonad.Util.SpawnOnce
import System.IO

import XMonad.Layout.Gaps
import XMonad.Layout.Spacing(spacing)
import XMonad.Layout.Minimize

import XMonad.Actions.CycleWS
import XMonad.Actions.CycleWindows
import XMonad.Actions.UpdatePointer

import qualified XMonad.StackSet as W
import qualified Data.Map as M

main = do
  mapM spawn [dzenCommand ++ show x | x <- [1, 2, 3]]
  xmonad $ xfceConfig
    {
      manageHook = myManageHook
    , layoutHook = myLayoutHook
    , workspaces = myWorkspaces
    , terminal = myTerminal
    , modMask = mod4Mask
    , borderWidth = 2
    , logHook = dynamicLog >> updatePointer (0.5, 0.5) (0, 0)
    --, startupHook = startUp
    }
    `removeKeys` removedKeys
    `additionalKeys` myKeys -- TODO: hopefully at some point to just set keys = myKeys instead of this


myManageHook = manageDocks <+> manageHook xfceConfig

leftGap = 0
rightGap = 0
downGap = 0
upGap = 25
myLayoutHook = avoidStruts $
               gaps [(U,upGap),(L,leftGap),(R,rightGap),(D,downGap)] $
               spacing 5 $
               layoutHook xfceConfig

myWorkspaces = [show x | x <- [1..9]]

myKeys =
  [
    ((mod1Mask, xK_Tab), windows W.focusDown) -- TODO: cycle focus through windows in all visible workspaces??
  , ((mod4Mask, xK_j), windows W.swapDown)
  , ((mod4Mask, xK_k), windows W.swapUp)

  , ((mod4Mask .|. shiftMask, xK_p), moveTo Prev NonEmptyWS)
  , ((mod4Mask .|. shiftMask, xK_n), moveTo Next NonEmptyWS)
  , ((mod4Mask, xK_f), nextScreen)
  , ((mod4Mask, xK_b), prevScreen)
  , ((mod4Mask .|. shiftMask, xK_f), shiftNextScreen >> nextScreen)
  , ((mod4Mask .|. shiftMask, xK_b), shiftPrevScreen >> prevScreen)

  , ((mod4Mask .|. shiftMask, xK_semicolon), spawn "firefox")
  , ((controlMask, xK_Print), spawn "xfce4-screenshooter")
  , ((mod4Mask .|. shiftMask, xK_h), spawn "thunar")

  , ((mod1Mask, xK_F4), kill)
  ]

removedKeys =
  [
    ((mod4Mask .|. shiftMask, xK_c))
  ]

myTerminal = "termite"

--startUp :: X()

myLogHook h = dynamicLogWithPP $ def
  {
    ppCurrent = dzenColor (colorDarkGray) (colorOrange) . pad
  , ppVisible = dzenColor (colorBlue) (colorWhite) . pad
  , ppHidden = dzenColor (colorWhite) (colorGreen) . pad
  , ppHiddenNoWindows = dzenColor (colorWhite) (colorDarkGray) . pad
  , ppUrgent = dzenColor (colorRed) (colorPureWhite) . pad
  , ppWsSep = ""
  , ppSep = "     "
  , ppOutput = hPutStrLn h
  }

colorOrange         = "#FD971F"
colorDarkGray       = "#1B1D1E"
colorPink           = "#F92672"
colorNormalBorder   = "#CCCCC6"
colorFocusedBorder  = "#fd971f"

colorBlack          = "#121212"
colorRed            = "#c90c25"
colorGreen          = "#2a5b6a"
colorYellow         = "#54777d"
colorBlue           = "#5c5dad"
colorMagen          = "#6f4484"
colorCyan           = "#2B7694"
colorWhite          = "#D6D6D6"
colorPureBlack      = "#000000"
colorPureWhite = "#FFFFFF"

dzenCommand = "while sleep 1; do date +'%a %b %d %H:%M'; done | dzen2 -w 4000 -h 30 -xs "
