import XMonad
import XMonad.Config.Xfce
import XMonad.Hooks.DynamicLog
import XMonad.Hooks.ManageDocks
import XMonad.Util.Run(spawnPipe)
import XMonad.Util.EZConfig(additionalKeys)
import System.IO

main = do
  xmonad $ xfceConfig
    {
      manageHook = manageDocks <+> manageHook xfceConfig
    , layoutHook = avoidStruts $ layoutHook xfceConfig
    , terminal = "xfce4-terminal"
    , modMask = mod4Mask
    , borderWidth = 0
    }
