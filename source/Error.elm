module Error exposing (css, view)

import Chadtech.Colors
    exposing
        ( critical
        , ignorable2
        , pointier
        )
import Css exposing (..)
import Css.Elements
import Css.Namespace exposing (namespace)
import Html exposing (Attribute, Html, div, p)
import Html.CssHelpers


-- STYLES --


type Class
    = ScreenFiller
    | TextContainer


css : Stylesheet
css =
    [ Css.class ScreenFiller
        [ width (pct 100)
        , height (pct 100)
        , backgroundColor critical
        , zIndex (int 5)
        , position fixed
        , top (px 0)
        , left (px 0)
        ]
    , Css.class TextContainer
        [ width (px 800)
        , transform (translate2 (pct -50) (pct -50))
        , position absolute
        , left (pct 50)
        , top (pct 50)
        , children
            [ Css.Elements.p
                [ color pointier ]
            ]
        ]
    ]
        |> namespace errorNamespace
        |> stylesheet


errorNamespace : String
errorNamespace =
    "Error"



-- VIEW --


{ class } =
    Html.CssHelpers.withNamespace errorNamespace


view : String -> List (Html msg)
view err =
    [ div
        [ class [ ScreenFiller ] ]
        [ div
            [ class [ TextContainer ] ]
            [ p [] [ Html.text "Error!" ]
            , p [] [ Html.text "Oh no, something went wrong. Im so sorry." ]
            , p [] [ Html.text "------" ]
            , p [] [ Html.text err ]
            ]
        ]
    ]