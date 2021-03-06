module Data.Config exposing (Config, init)

import Data.Flags exposing (Flags)
import Data.Keys as Key
import Data.User exposing (State(LoggedIn))
import Dict exposing (Dict)
import Id exposing (Id)
import Keyboard.Extra.Browser exposing (Browser)


type alias Config =
    { quickKeys : Dict String String
    , keyCmds : Dict String Key.Cmd
    , cmdKey : Key.Event -> Bool
    , isMac : Bool
    , mountPath : String
    , buildNumber : Int
    , browser : Browser
    , sessionId : Id
    }


init : Flags -> Config
init flags =
    let
        keyConfig =
            getKeyConfig flags
    in
    { quickKeys =
        Key.initQuickKeysLookUp
            flags.browser
            keyConfig
            flags.isMac
    , keyCmds =
        Key.initCmdLookUp flags.browser keyConfig
    , cmdKey =
        if flags.isMac then
            .meta
        else
            .ctrl
    , isMac = flags.isMac
    , mountPath = flags.mountPath
    , buildNumber = flags.buildNumber
    , browser = flags.browser
    , sessionId = flags.randomValues.sessionId
    }


getKeyConfig : Flags -> Key.Config
getKeyConfig flags =
    case flags.user of
        LoggedIn { user } ->
            user.keyConfig

        _ ->
            Key.defaultConfig
