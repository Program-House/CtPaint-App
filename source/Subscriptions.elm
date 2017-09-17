port module Subscriptions exposing (subscriptions)

import AnimationFrame
import ColorPicker
import Json.Decode exposing (Value)
import Menu exposing (Menu(..))
import Menu.Download.Mouse as Download
import Menu.Import.Mouse as Import
import Menu.MsgMap
import Menu.Scale.Mouse as Scale
import Minimap.Mouse as Minimap
import Ports as Ports
import Tool
import Types exposing (Direction(..), Model, Msg(..))
import Window


subscriptions : Model -> Sub Msg
subscriptions model =
    [ Window.resizes GetWindowSize
    , AnimationFrame.diffs Tick
    , Sub.map
        ColorPickerMsg
        (ColorPicker.subscriptions model.colorPicker)
    , Sub.map
        MinimapMsg
        (Minimap.subscriptions model.minimap)
    , keyboardUps
    , keyboardDowns
    , Sub.map ToolMsg (Tool.subscriptions model.tool)
    , menu model
    , Ports.windowFocus HandleWindowFocus
    ]
        --|> maybeCons (Maybe.map Mouse.moves model.subMouseMove)
        |> Sub.batch



-- MENU --


menu : Model -> Sub Msg
menu model =
    case model.menu of
        None ->
            Sub.none

        Download _ ->
            Sub.map
                Menu.MsgMap.download
                Download.subscriptions

        Import _ ->
            Sub.map
                Menu.MsgMap.import_
                Import.subscriptions

        Scale _ ->
            Sub.map
                Menu.MsgMap.scale
                Scale.subscriptions

        _ ->
            Sub.none



-- KEYBOARD --


port keyDown : (Value -> msg) -> Sub msg


port keyUp : (Value -> msg) -> Sub msg


keyboardUps : Sub Msg
keyboardUps =
    keyUp (KeyboardEvent Up)


keyboardDowns : Sub Msg
keyboardDowns =
    keyDown (KeyboardEvent Down)
