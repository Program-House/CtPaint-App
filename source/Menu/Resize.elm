module Menu.Resize exposing
    ( Model
    , Msg(..)
    , css
    , init
    , track
    , update
    , view
    )

import Css exposing (..)
import Css.Elements
import Css.Namespace exposing (namespace)
import Data.Tracking as Tracking
import Html
    exposing
        ( Html
        , input
        , p
        )
import Html.Attributes as Attrs
import Html.CssHelpers
import Html.Custom
import Html.Events as Events
import Json.Encode as E
import Menu.Reply exposing (Reply(ResizeTo))
import Mouse
import Return3 as R3 exposing (Return)
import Util exposing (def, valueIfFocus)
import Window exposing (Size)



-- TYPES --


type alias Model =
    { leftField : String
    , rightField : String
    , topField : String
    , bottomField : String
    , widthField : String
    , heightField : String
    , left : Int
    , right : Int
    , top : Int
    , bottom : Int
    , width : Int
    , height : Int
    , sourceWidth : Int
    , sourceHeight : Int
    , focus : Maybe Field
    }


getSourceSize : Model -> Size
getSourceSize model =
    { width = model.sourceWidth
    , height = model.sourceHeight
    }


toPosition : Model -> Mouse.Position
toPosition model =
    { x = model.left, y = model.top }


type Msg
    = FieldUpdated Field String
    | FieldFocused Field
    | ResizeClicked


type Field
    = Left
    | Right
    | Top
    | Bottom
    | Width
    | Height


fieldToString : Field -> String
fieldToString field =
    case field of
        Left ->
            "left"

        Right ->
            "right"

        Top ->
            "top"

        Bottom ->
            "bottom"

        Width ->
            "width"

        Height ->
            "height"



-- INIT --


init : Size -> Model
init size =
    { leftField = "0"
    , rightField = "0"
    , topField = "0"
    , bottomField = "0"
    , widthField = toString size.width
    , heightField = toString size.height
    , left = 0
    , right = 0
    , top = 0
    , bottom = 0
    , width = size.width
    , height = size.height
    , sourceWidth = size.width
    , sourceHeight = size.height
    , focus = Nothing
    }



-- STYLES --


type Class
    = Field
    | Header
    | SubmitButton


css : Stylesheet
css =
    [ Css.class Field
        [ margin4 (px 0) (px 0) (px 4) (px 0)
        , children
            [ Css.Elements.input
                [ width (px 80) ]
            , Css.Elements.p
                [ width (px 80) ]
            ]
        ]
    , Css.class Header
        [ marginBottom (px 4) ]
    , Css.class SubmitButton
        [ marginTop (px 8) ]
    ]
        |> namespace resizeNamespace
        |> stylesheet


resizeNamespace : String
resizeNamespace =
    Html.Custom.makeNamespace "Resize"



-- VIEW --


{ class } =
    Html.CssHelpers.withNamespace resizeNamespace


view : Model -> Html Msg
view model =
    [ header "size"
    , widthField model
    , heightField model
    , header "sides"
    , topField model
    , bottomField model
    , leftField model
    , rightField model
    , Html.Custom.menuButton
        [ class [ SubmitButton ]
        , Events.onClick ResizeClicked
        ]
        [ Html.text "resize" ]
    ]
        |> Html.Custom.cardBody []


header : String -> Html Msg
header str =
    p
        [ class [ Header ] ]
        [ Html.text str ]


widthField : Model -> Html Msg
widthField model =
    [ p [] [ Html.text "width" ]
    , input
        [ Attrs.placeholder (Util.px model.width)
        , Events.onFocus (FieldFocused Width)
        , valueIfFocus
            Width
            model.focus
            model.widthField
        , Events.onInput (FieldUpdated Width)
        ]
        []
    ]
        |> field


heightField : Model -> Html Msg
heightField model =
    [ p [] [ Html.text "height" ]
    , input
        [ Attrs.placeholder (Util.px model.height)
        , Events.onFocus (FieldFocused Height)
        , valueIfFocus
            Height
            model.focus
            model.heightField
        , Events.onInput (FieldUpdated Height)
        ]
        []
    ]
        |> field


topField : Model -> Html Msg
topField model =
    [ p [] [ Html.text "top" ]
    , input
        [ Attrs.placeholder (Util.px model.top)
        , Events.onFocus (FieldFocused Top)
        , valueIfFocus
            Top
            model.focus
            model.topField
        , Events.onInput (FieldUpdated Top)
        ]
        []
    ]
        |> field


bottomField : Model -> Html Msg
bottomField model =
    [ p [] [ Html.text "bottom" ]
    , input
        [ Attrs.placeholder (Util.px model.bottom)
        , Events.onFocus (FieldFocused Bottom)
        , valueIfFocus
            Bottom
            model.focus
            model.bottomField
        , Events.onInput (FieldUpdated Bottom)
        ]
        []
    ]
        |> field


leftField : Model -> Html Msg
leftField model =
    [ p [] [ Html.text "left" ]
    , input
        [ Attrs.placeholder (Util.px model.left)
        , Events.onFocus (FieldFocused Left)
        , valueIfFocus
            Left
            model.focus
            model.leftField
        , Events.onInput (FieldUpdated Left)
        ]
        []
    ]
        |> field


rightField : Model -> Html Msg
rightField model =
    [ p [] [ Html.text "right" ]
    , input
        [ Attrs.placeholder (Util.px model.right)
        , Events.onFocus (FieldFocused Right)
        , valueIfFocus
            Right
            model.focus
            model.rightField
        , Events.onInput (FieldUpdated Right)
        ]
        []
    ]
        |> field


field : List (Html Msg) -> Html Msg
field =
    Html.Custom.field
        [ class [ Field ]
        , Events.onSubmit ResizeClicked
        ]



-- UPDATE --


update : Msg -> Model -> Return Model Msg Reply
update msg model =
    case msg of
        FieldUpdated Left str ->
            { model | leftField = str }
                |> cohere Left str
                |> R3.withNothing

        FieldUpdated Right str ->
            { model | rightField = str }
                |> cohere Right str
                |> R3.withNothing

        FieldUpdated Top str ->
            { model | topField = str }
                |> cohere Top str
                |> R3.withNothing

        FieldUpdated Bottom str ->
            { model | bottomField = str }
                |> cohere Bottom str
                |> R3.withNothing

        FieldUpdated Width str ->
            { model | widthField = str }
                |> cohere Width str
                |> R3.withNothing

        FieldUpdated Height str ->
            { model | heightField = str }
                |> cohere Height str
                |> R3.withNothing

        FieldFocused field ->
            { model | focus = Just field }
                |> R3.withNothing

        ResizeClicked ->
            { width = model.width
            , height = model.height
            }
                |> ResizeTo (toPosition model)
                |> R3.withTuple ( model, Cmd.none )


cohere : Field -> String -> Model -> Model
cohere field str model =
    case String.toInt str of
        Ok int ->
            case field of
                Left ->
                    { model | left = int }
                        |> cohereDimensions

                Right ->
                    { model | right = int }
                        |> cohereDimensions

                Top ->
                    { model | top = int }
                        |> cohereDimensions

                Bottom ->
                    { model | bottom = int }
                        |> cohereDimensions

                Width ->
                    { model | width = int }
                        |> coherePadding

                Height ->
                    { model | height = int }
                        |> coherePadding

        Err _ ->
            model


cohereDimensions : Model -> Model
cohereDimensions model =
    let
        width =
            model.sourceWidth + model.left + model.right

        height =
            model.sourceHeight + model.top + model.bottom
    in
    { model
        | width = width
        , height = height
        , widthField = toString width
        , heightField = toString height
    }


coherePadding : Model -> Model
coherePadding model =
    let
        dw =
            model.width - model.sourceWidth

        dh =
            model.height - model.sourceHeight

        left =
            dw // 2

        right =
            (dw // 2) + (dw % 2)

        top =
            dh // 2

        bottom =
            (dh // 2) + (dh % 2)
    in
    { model
        | left = left
        , leftField = toString left
        , right = right
        , rightField = toString right
        , top = top
        , topField = toString top
        , bottom = bottom
        , bottomField = toString bottom
    }



-- TRACK --


track : Msg -> Tracking.Event
track msg =
    case msg of
        FieldUpdated _ _ ->
            Tracking.none

        FieldFocused field ->
            [ def "field" <|
                E.string (fieldToString field)
            ]
                |> Tracking.withProps
                    "field-focused"

        ResizeClicked ->
            "resize-clicked"
                |> Tracking.noProps
