module Main.Subscriptions exposing (subscriptions)

import Main.Model exposing (Model)
import Main.Message exposing (Message(..))
import Util exposing (maybeCons)
import Tool.Types exposing (Tool(..))
import Tool.Hand.Mouse as Hand
import Tool.Pencil.Mouse as Pencil
import Mouse
import Window
import AnimationFrame
import Keyboard
import Keyboard.Types as Keyboard


subscriptions : Model -> Sub Message
subscriptions model =
    let
        toolSubs =
            case model.tool of
                Hand _ ->
                    List.map (Sub.map HandMessage) Hand.subs

                Pencil _ ->
                    List.map (Sub.map PencilMessage) Pencil.subs
    in
        Sub.batch
            [ generalSubs model
            , Sub.batch toolSubs
            ]


generalSubs : Model -> Sub Message
generalSubs model =
    [ Window.resizes GetWindowSize
    , AnimationFrame.diffs Tick
    , Keyboard.ups
        (KeyboardMessage << Keyboard.KeyEvent << Keyboard.Up)
    ]
        |> maybeCons (Maybe.map Mouse.moves model.subMouseMove)
        |> Sub.batch
