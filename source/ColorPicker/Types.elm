module ColorPicker.Types exposing (..)

import Mouse exposing (Position)
import Color exposing (Color)
import MouseEvents exposing (MouseEvent)
import Array exposing (Array)
import Palette.Types as Palette
import MouseEvents exposing (MouseEvent)


type ExternalMessage
    = SetColor Int Color
    | SetFocus Bool
    | UpdateHistory Int Color


type Message
    = HeaderMouseDown MouseEvent
    | HeaderMouseMove Position
    | HeaderMouseUp Position
    | WakeUp Color Int
    | Close
    | HandleFocus Bool
    | StealSubmit
    | UpdateColorHexField String
    | MouseDownOnPointer Gradient
    | SetNoGradientClickedOn
    | MouseMoveInGradient Gradient MouseEvent
    | FieldUpdate Gradient String


type Gradient
    = Red
    | Green
    | Blue
    | Hue
    | Saturation
    | Lightness


type alias Model =
    { position : Position
    , clickState : Maybe Position
    , color : Color
    , index : Int
    , redField : String
    , greenField : String
    , blueField : String
    , hueField : String
    , saturationField : String
    , lightnessField : String
    , show : Bool
    , colorHexField : String
    , gradientClickedOn : Maybe Gradient
    }


newFrom : Int -> Color -> Model -> Model
newFrom index color model =
    let
        { red, green, blue } =
            Color.toRgb color

        { hue, saturation, lightness } =
            Color.toHsl color
    in
        { model
            | color = color
            , index = index
            , redField = toString red
            , greenField = toString green
            , blueField = toString blue
            , hueField =
                ((radians hue) / (2 * pi) * 360)
                    |> floor
                    |> toString
            , saturationField =
                (saturation * 255)
                    |> floor
                    |> toString
            , lightnessField =
                (lightness * 255)
                    |> floor
                    |> toString
            , colorHexField =
                String.dropLeft 1 (Palette.toHex color)
        }


init : Array Color -> Model
init colors =
    let
        color =
            case Array.get 0 colors of
                Just color ->
                    color

                Nothing ->
                    Color.black

        { red, green, blue } =
            Color.toRgb color

        { hue, saturation, lightness } =
            Color.toHsl color
    in
        { position = Position 50 350
        , clickState = Nothing
        , color = color
        , index = 0
        , redField = toString red
        , greenField = toString green
        , blueField = toString blue
        , hueField =
            ((radians hue) / (2 * pi) * 360)
                |> floor
                |> toString
        , saturationField =
            (saturation * 255)
                |> floor
                |> toString
        , lightnessField =
            (lightness * 255)
                |> floor
                |> toString
        , show = False
        , colorHexField =
            String.dropLeft 1 (Palette.toHex color)
        , gradientClickedOn = Nothing
        }
