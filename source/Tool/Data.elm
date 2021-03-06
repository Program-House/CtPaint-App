module Tool.Data
    exposing
        ( Tool(..)
        , all
        , handIcon
        , icon
        , init
        , name
        , zoomInIcon
        , zoomOutIcon
        )

import Char
import Mouse exposing (Position)
import Tool.Eraser.Model as Eraser
import Tool.Hand.Model as Hand
import Tool.Line.Model as Line
import Tool.Pencil.Model as Pencil
import Tool.Rectangle.Model as Rectangle
import Tool.RectangleFilled.Model as RectangleFilled


type Tool
    = Hand (Maybe Hand.Model)
    | Sample
    | Fill
    | Select (Maybe Position)
    | ZoomIn
    | ZoomOut
    | Pencil (Maybe Pencil.Model)
    | Line (Maybe Line.Model)
    | Rectangle (Maybe Rectangle.Model)
    | RectangleFilled (Maybe RectangleFilled.Model)
    | Eraser (Maybe Eraser.Model)


init : Tool
init =
    Pencil Nothing



-- HELPERS --


all : List Tool
all =
    [ Select Nothing
    , ZoomIn
    , ZoomOut
    , Hand Nothing
    , Sample
    , Fill
    , Eraser Nothing
    , Pencil Nothing
    , Line Nothing
    , Rectangle Nothing
    , RectangleFilled Nothing
    ]


icon : Tool -> String
icon =
    iconHelper >> Char.fromCode >> String.fromChar


iconHelper : Tool -> Int
iconHelper tool =
    case tool of
        Hand _ ->
            --"\xEA0A"
            59914

        Sample ->
            --"\xEA08"
            59912

        Fill ->
            --"\xEA16"
            59926

        Pencil _ ->
            --"\xEA02"
            59906

        Line _ ->
            --"\xEA09"
            59913

        Rectangle _ ->
            --"\xEA03"
            59907

        RectangleFilled _ ->
            --"\xEA04"
            59908

        Select _ ->
            --"\xEA07"
            59911

        ZoomIn ->
            --"\xEA17"
            59927

        ZoomOut ->
            --"\xEA18"
            59928

        Eraser _ ->
            --"\xEA1B"
            59931


name : Tool -> String
name tool =
    case tool of
        Hand _ ->
            "hand"

        Sample ->
            "sample"

        Fill ->
            "fill"

        Pencil _ ->
            "pencil"

        Line _ ->
            "line"

        Rectangle _ ->
            "rectangle"

        RectangleFilled _ ->
            "rectangle-filled"

        Select _ ->
            "select"

        ZoomIn ->
            "zoom-in"

        ZoomOut ->
            "zoom-out"

        Eraser _ ->
            "eraser"


{-| The hand icon is used else where, but in
a different context than indicating this tool
-}
handIcon : String
handIcon =
    icon (Hand Nothing)


{-| The zoom in icon is used else where, but in
a different context than indicating this tool
-}
zoomInIcon : String
zoomInIcon =
    icon ZoomIn


{-| The zoom out icon is used else where, but in
a different context than indicating this tool
-}
zoomOutIcon : String
zoomOutIcon =
    icon ZoomOut
