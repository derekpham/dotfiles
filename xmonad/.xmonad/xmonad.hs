-- TODO:
-- +) Clean out imports

import XMonad
import XMonad.Config.Xfce
import XMonad.Hooks.DynamicLog
import XMonad.Hooks.ManageDocks
import XMonad.Util.Run(spawnPipe)
import XMonad.Util.EZConfig
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
  xmonad $ xfceConfig
    {
      manageHook = myManageHook
    , layoutHook = myLayoutHook
    , workspaces = myWorkspaces
    , terminal = myTerminal
    , modMask = mod4Mask
    , borderWidth = 2
    , logHook = myLogHook
    }
    `removeKeys` removedKeys
    `additionalKeys` myKeys -- TODO: hopefully at some point to just set keys = myKeys instead of this


myManageHook = manageDocks <+> manageHook xfceConfig

myLayoutHook = avoidStruts $
               gaps [(U,5),(L,5),(R,5),(D,5)] $
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
  , ((mod4Mask .|. shiftMask, xK_f), shiftNextScreen)
  , ((mod4Mask .|. shiftMask, xK_b), shiftPrevScreen)

  , ((controlMask, xK_backslash), spawn "rofi -show run")
  , ((controlMask, xK_bracketright), spawn "rofi -show window")

  , ((mod1Mask, xK_F4), kill)
  ]

removedKeys =
  [
    ((mod4Mask .|. shiftMask, xK_c))
  ]

myTerminal = "xfce4-terminal"

myLogHook = dynamicLog >> updatePointer (0.5, 0.5) (0, 0)
