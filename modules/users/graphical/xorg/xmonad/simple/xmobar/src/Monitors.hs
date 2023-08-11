module Monitors
    (CombinedMonitor
    , guardedMonitor
    , altMonitor
    , concatMonitor
    , toggleMonitor
    )
where

import Xmobar
import Themes
import Control.Concurrent
import Control.Concurrent.Async (async)
import Control.Concurrent.STM
import qualified Data.Char as Char
import qualified Text.Printf as Printf

data CombinedMonitor a b = CombinedMonitor a b (String -> String -> String)

instance (Show a, Show b) => Show (CombinedMonitor a b) where
  show (CombinedMonitor a b _) = "Alt (" ++ show a ++ ") (" ++ show b ++ ")"

instance (Read a, Read b) => Read (CombinedMonitor a b) where
  readsPrec _ = undefined

instance (Exec a, Exec b) => Exec (CombinedMonitor a b) where
  alias (CombinedMonitor a b _) = alias a ++ "_" ++ alias b
  rate (CombinedMonitor a b _) = min (rate a) (rate b)
  start (CombinedMonitor a b comb) cb
    = startMonitors a b (\s t -> cb $ comb s t)

startMonitors a b cmb =  do
    sta <- atomically $ newTVar ""
    stb <- atomically $ newTVar ""
    _ <- async $ start a (atomically . writeTVar sta)
    _ <- async $ start b (atomically . writeTVar stb)
    go sta stb
      where go sta' stb' = do
              s <- readTVarIO sta'
              t <- readTVarIO stb'
              cmb s t
              tenthSeconds $ min (rate b) (rate a)
              go sta' stb'

guardedMonitor a p = CombinedMonitor (PipeReader p (alias a ++ "_g")) a f
  where f s t = if null s || head s == '0' then "" else t

altMonitor a b = CombinedMonitor a b (\s t -> if null s then t else s)
concatMonitor sep a b = CombinedMonitor a b (\s t -> s ++ sep ++ t)
toggleMonitor path a = altMonitor (guardedMonitor a path)

-- "https://wttr.in?format=" ++ fnn 3 "%c" ++ "+%t+%C+%w++" ++ fnn 1 "%m"
-- , Run (ComX "curl" [wttrURL "Edinburgh"] "" "wttr" 18000)
wttrURL l = "https://wttr.in/" ++ l ++ "?format=" ++ fmt
  where fmt = fnn 2 "+%c+" ++ "+%t+%C+" ++ fn 5 "%w"
        fnn n x = urlEncode ("<fn=" ++ show n ++ ">") ++ x ++ urlEncode "</fn>"
        encode c
          | c == ' ' = "+"
          | Char.isAlphaNum c || c `elem` ("-._~"::String) = [c]
          | otherwise = Printf.printf "%%%02X" c
        urlEncode = concatMap encode

netdev name icon = Network name ["-t", "<up>", "-x", "", "--", "--up", icon] 20
vpnMark n = netdev n $ fn 2 "🔒 "
proton0 = vpnMark "proton0"
tun0 = vpnMark "tun0"

trayPadding = Com "padding-width.sh" [] "tray" 20
