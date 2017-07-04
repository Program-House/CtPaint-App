module Main.View exposing (view)

import Html exposing (Html, div, p, text)
import Html.Attributes exposing (class)
import Main.Model exposing (Model)
import Main.Message exposing (Message(..))
import Toolbar.Vertical.View as ToolbarVertical


-- VIEW --


view : Model -> Html Message
view model =
    div
        [ class "main" ]
        [ ToolbarVertical.view
        ]
