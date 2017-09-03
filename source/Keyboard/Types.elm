module Keyboard.Types exposing (..)

import Keyboard exposing (KeyCode)
import Keyboard.Extra exposing (Key(..))
import Dict exposing (Dict)
import Util exposing ((:=))


type Direction
    = Up KeyCode
    | Down KeyCode


type Message
    = KeyEvent Direction


type QuickKey
    = SwatchesOneTurn
    | SwatchesThreeTurns
    | SwatchesTwoTurns
    | SetToolToPencil
    | SetToolToHand
    | SetToolToSelect
    | SetToolToFill
    | Undo
    | Redo
    | ZoomIn
    | ZoomOut
    | ShowMinimap
    | Download
    | Import
    | NoCommand


type alias Config =
    Dict (List KeyCode) QuickKey



-- KEY DOWN CONFIG --


defaultKeyDownConfig : Config
defaultKeyDownConfig =
    [ [ Number2 ] := SwatchesOneTurn
    , [ Number3 ] := SwatchesTwoTurns
    , [ Number4 ] := SwatchesThreeTurns
    ]
        |> List.map keysToCodes
        |> Dict.fromList



-- KEY UP CONFIG --


initKeyUp : Bool -> Maybe (Key -> Config) -> Config
initKeyUp isMac customConfig =
    let
        cmdKey =
            if isMac then
                Super
            else
                Control
    in
        case customConfig of
            Nothing ->
                defaultKeyUpConfig cmdKey

            Just config ->
                config cmdKey


defaultKeyUpConfig : Key -> Config
defaultKeyUpConfig cmd =
    [ [ Number1 ] := SwatchesOneTurn
    , [ Number2 ] := SwatchesThreeTurns
    , [ Number3 ] := SwatchesTwoTurns
    , [ Number4 ] := SwatchesOneTurn
    , [ Number5 ] := SwatchesThreeTurns
    , [ CharP ] := SetToolToPencil
    , [ CharH ] := SetToolToHand
    , [ CharS ] := SetToolToSelect
    , [ CharG ] := SetToolToFill
    , [ CharZ, cmd ] := Undo
    , [ CharY, cmd ] := Redo
    , [ Equals ] := ZoomIn
    , [ Minus ] := ZoomOut
    , [ BackQuote ] := ShowMinimap
    , [ CharD, Shift ] := Download
    , [ CharI, cmd ] := Import
    ]
        |> List.map keysToCodes
        -- ff and chrome have different codes for equals
        |>
            (::) ([ 187 ] := ZoomIn)
        |> Dict.fromList


keysToCodes : ( List Key, QuickKey ) -> ( List KeyCode, QuickKey )
keysToCodes ( keys, cmds ) =
    ( List.map Keyboard.Extra.toCode keys, cmds )
