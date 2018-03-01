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
import XMonad.Layout.Spacing (spacing)
import XMonad.Layout.Minimize

import XMonad.Actions.CopyWindow
import XMonad.Actions.CycleWS
import XMonad.Actions.CycleWindows
import XMonad.Actions.GroupNavigation

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
    } `additionalKeys` myKeys

myManageHook = manageDocks <+> manageHook xfceConfig

myLayoutHook = avoidStruts $
               gaps [(U,5),(L,5),(R,5),(D,5)] $
               spacing 5 $
               layoutHook xfceConfig

myWorkspaces = [show x | x <- [1..9]]

myKeys =
  [
    ((mod1Mask, xK_Tab), windows W.focusDown)
  , ((mod4Mask, xK_b), moveTo Prev NonEmptyWS)
  , ((mod4Mask, xK_f), moveTo Next NonEmptyWS)
  ]

myTerminal = "xfce4-terminal"
