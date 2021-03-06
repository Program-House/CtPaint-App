module Menu.Scale exposing
    ( Model
    , Msg
    , css
    , init
    , track
    , update
    , view
    )

import Css exposing (..)
import Css.Elements
import Css.Namespace exposing (namespace)
import Data.Size exposing (Size)
import Data.Tracking as Tracking
import Html exposing (Attribute, Html)
import Html.Attributes as Attrs
import Html.CssHelpers
import Html.Custom
import Html.Events as Events
import Json.Encode as E
import Menu.Reply exposing (Reply(ScaleTo))
import Return2 as R2
import Return3 as R3 exposing (Return)
import Util exposing (def, valueIfFocus)



-- TYPES --


type alias Model =
    { fixedWidth : Int
    , fixedHeight : Int
    , percentWidth : Float
    , percentHeight : Float
    , fixedWidthField : String
    , fixedHeightField : String
    , percentWidthField : String
    , percentHeightField : String
    , initialSize : Size
    , lockRatio : Bool
    , focus : Maybe Field
    }


type Msg
    = FieldUpdated Field String
    | LockButtonClicked
    | FieldFocused Field
    | ScaleClick


type Field
    = FixedWidth
    | FixedHeight
    | PercentWidth
    | PercentHeight


fieldToString : Field -> String
fieldToString field =
    case field of
        FixedWidth ->
            "fixed-width"

        FixedHeight ->
            "fixed-height"

        PercentWidth ->
            "percent-width"

        PercentHeight ->
            "percent-height"



-- INIT --


init : Size -> Model
init size =
    { fixedWidth = size.width
    , fixedHeight = size.height
    , percentWidth = 100
    , percentHeight = 100
    , fixedWidthField = toString size.width
    , fixedHeightField = toString size.height
    , percentWidthField = "100"
    , percentHeightField = "100"
    , initialSize = size
    , lockRatio = True
    , focus = Nothing
    }



-- STYLES --


type Class
    = Lock
    | LockContainer
    | Field
    | Row


css : Stylesheet
css =
    [ Css.class LockContainer
        [ display inlineBlock
        , children
            [ Css.Elements.p
                [ display inlineBlock
                , width (px 120)
                ]
            ]
        ]
    , Css.class Field
        [ margin4 (px 4) (px 0) (px 0) (px 0)
        , children
            [ Css.Elements.input
                [ width (px 80)
                , withClass Lock
                    [ width (px 24) ]
                ]
            , Css.Elements.p
                [ width (px 80) ]
            ]
        ]
    , Css.class Lock
        [ height (px 24)
        , borderRadius (px 0)
        , paddingBottom (px 2)
        , cursor pointer
        , textAlign center
        , marginBottom (px 8)
        , children
            [ Css.Elements.input
                [ width auto ]
            ]
        ]
    , Css.class Row
        [ marginBottom (px 8) ]
    ]
        |> namespace scaleNamespace
        |> stylesheet


scaleNamespace : String
scaleNamespace =
    Html.Custom.makeNamespace "Scale"



-- VIEW --


{ class } =
    Html.CssHelpers.withNamespace scaleNamespace


view : Model -> Html Msg
view model =
    [ percentScaling model
    , absoluteScaling model
    , Html.div
        []
        [ lock model.lockRatio
        ]
    , Html.Custom.menuButton
        [ Events.onClick ScaleClick ]
        [ Html.text "set size" ]
    ]
        |> Html.Custom.cardBody []


lock : Bool -> Html Msg
lock locked =
    Html.form
        [ class [ Field, LockContainer ] ]
        [ Html.p [] [ Html.text "lock" ]
        , Html.input
            [ class [ Lock ]
            , lockedValue locked
            , Events.onClick LockButtonClicked
            , Attrs.type_ "button"
            ]
            []
        ]


lockedValue : Bool -> Attribute Msg
lockedValue locked =
    if locked then
        Attrs.value "x"

    else
        Attrs.value " "


percentScaling : Model -> Html Msg
percentScaling model =
    Html.div
        [ class [ Row ] ]
        [ Html.p [] [ Html.text "percent" ]
        , field
            [ Html.p [] [ Html.text "width" ]
            , Html.input
                [ Attrs.placeholder (Util.pct model.percentWidth)
                , Events.onFocus (FieldFocused PercentWidth)
                , valueIfFocus
                    PercentWidth
                    model.focus
                    model.percentWidthField
                , Events.onInput (FieldUpdated PercentWidth)
                ]
                []
            ]
        , field
            [ Html.p [] [ Html.text "height" ]
            , Html.input
                [ Attrs.placeholder (Util.pct model.percentHeight)
                , Events.onFocus (FieldFocused PercentHeight)
                , valueIfFocus
                    PercentHeight
                    model.focus
                    model.percentHeightField
                , Events.onInput (FieldUpdated PercentHeight)
                ]
                []
            ]
        ]


absoluteScaling : Model -> Html Msg
absoluteScaling model =
    Html.div
        [ class [ Row ] ]
        [ Html.p [] [ Html.text "absolute" ]
        , field
            [ Html.p [] [ Html.text "width" ]
            , Html.input
                [ Attrs.placeholder (Util.px model.fixedWidth)
                , Events.onFocus (FieldFocused FixedWidth)
                , valueIfFocus
                    FixedWidth
                    model.focus
                    model.fixedWidthField
                , Events.onInput (FieldUpdated FixedWidth)
                ]
                []
            ]
        , field
            [ Html.p [] [ Html.text "height" ]
            , Html.input
                [ Attrs.placeholder (Util.px model.fixedHeight)
                , Events.onFocus (FieldFocused FixedHeight)
                , valueIfFocus
                    FixedHeight
                    model.focus
                    model.fixedHeightField
                , Events.onInput (FieldUpdated FixedHeight)
                ]
                []
            ]
        ]


field : List (Html Msg) -> Html Msg
field =
    Html.Custom.field
        [ class [ Field ]
        , Events.onSubmit ScaleClick
        ]



-- UPDATE --


update : Msg -> Model -> Return Model Msg Reply
update msg model =
    case msg of
        FieldUpdated field str ->
            updateField field str model
                |> R3.withNothing

        LockButtonClicked ->
            { model
                | lockRatio =
                    not model.lockRatio
            }
                |> R3.withNothing

        FieldFocused field ->
            { model
                | focus = Just field
            }
                |> R3.withNothing

        ScaleClick ->
            model
                |> R2.withNoCmd
                |> R3.withReply (scaleReply model)


scaleReply : Model -> Reply
scaleReply model =
    ScaleTo model.fixedWidth model.fixedHeight


updateField : Field -> String -> Model -> Model
updateField field str model =
    case field of
        FixedWidth ->
            { model | fixedWidthField = str }
                |> parseFixedWidth

        FixedHeight ->
            { model | fixedHeightField = str }
                |> parseFixedHeight

        PercentWidth ->
            { model | percentWidthField = str }
                |> parsePercentWidth

        PercentHeight ->
            { model | percentHeightField = str }
                |> parsePercentHeight


parseFixedWidth : Model -> Model
parseFixedWidth model =
    case String.toInt model.fixedWidthField of
        Ok fixedWidth ->
            { model | fixedWidth = fixedWidth }
                |> percentWidthFromFixedWidth
                |> heightFromFixedWidth

        Err err ->
            model


percentWidthFromFixedWidth : Model -> Model
percentWidthFromFixedWidth model =
    let
        percentWidth =
            let
                fixedWidth_ =
                    toFloat model.fixedWidth

                initialWidth =
                    toFloat model.initialSize.width
            in
            (fixedWidth_ / initialWidth) * 100
    in
    { model
        | percentWidthField = toString percentWidth
        , percentWidth = percentWidth
    }


heightFromFixedWidth : Model -> Model
heightFromFixedWidth model =
    if model.lockRatio then
        let
            fixedHeight =
                [ toFloat model.initialSize.height
                , toFloat model.fixedWidth
                , 1 / toFloat model.initialSize.width
                ]
                    |> List.product
                    |> Basics.round
        in
        { model
            | fixedHeight = fixedHeight
            , fixedHeightField = toString fixedHeight
            , percentHeight =
                let
                    initialHeight =
                        toFloat model.initialSize.height
                in
                (toFloat fixedHeight / initialHeight) * 100
        }

    else
        model


parseFixedHeight : Model -> Model
parseFixedHeight model =
    case String.toInt model.fixedHeightField of
        Ok fixedHeight ->
            { model | fixedHeight = fixedHeight }
                |> percentHeightFromFixedHeight
                |> widthFromFixedHeight

        Err err ->
            model


percentHeightFromFixedHeight : Model -> Model
percentHeightFromFixedHeight model =
    let
        percentHeight =
            let
                fixedHeight_ =
                    toFloat model.fixedHeight

                initialHeight =
                    toFloat model.initialSize.height
            in
            (fixedHeight_ / initialHeight) * 100
    in
    { model
        | percentHeightField = toString (Basics.round percentHeight)
        , percentHeight = percentHeight
    }


widthFromFixedHeight : Model -> Model
widthFromFixedHeight model =
    if model.lockRatio then
        let
            fixedWidth =
                [ toFloat model.initialSize.width
                , toFloat model.fixedHeight
                , 1 / toFloat model.initialSize.height
                ]
                    |> List.product
                    |> Basics.round
        in
        { model
            | fixedWidth = fixedWidth
            , fixedWidthField = toString fixedWidth
            , percentWidth =
                let
                    initialWidth =
                        toFloat model.initialSize.width
                in
                (toFloat fixedWidth / initialWidth) * 100
        }

    else
        model


parsePercentWidth : Model -> Model
parsePercentWidth model =
    case String.toFloat model.percentWidthField of
        Ok percentWidth ->
            { model | percentWidth = percentWidth }
                |> fixedWidthFromPercentWidth
                |> heightFromPercentWidth

        Err err ->
            model


fixedWidthFromPercentWidth : Model -> Model
fixedWidthFromPercentWidth model =
    let
        fixedWidth =
            let
                initialWidth =
                    toFloat model.initialSize.width
            in
            Basics.round (initialWidth * (model.percentWidth / 100))
    in
    { model
        | fixedWidth = fixedWidth
        , fixedWidthField = toString fixedWidth
    }


heightFromPercentWidth : Model -> Model
heightFromPercentWidth model =
    if model.lockRatio then
        { model
            | percentHeight = model.percentWidth
            , percentHeightField = model.percentWidthField
            , fixedHeight =
                let
                    initialHeight =
                        toFloat model.initialSize.height
                in
                Basics.round (initialHeight * (model.percentWidth / 100))
        }

    else
        model


parsePercentHeight : Model -> Model
parsePercentHeight model =
    case String.toFloat model.percentHeightField of
        Ok percentHeight ->
            { model | percentHeight = percentHeight }
                |> fixedHeightFromPercentHeight
                |> widthFromPercentHeight

        Err err ->
            model


fixedHeightFromPercentHeight : Model -> Model
fixedHeightFromPercentHeight model =
    let
        fixedHeight =
            let
                initialHeight =
                    toFloat model.initialSize.height
            in
            Basics.round (initialHeight * (model.percentHeight / 100))
    in
    { model
        | fixedHeight = fixedHeight
        , fixedHeightField = toString fixedHeight
    }


widthFromPercentHeight : Model -> Model
widthFromPercentHeight model =
    if model.lockRatio then
        { model
            | percentWidth = model.percentHeight
            , percentWidthField = model.percentHeightField
            , fixedWidth =
                let
                    initialWidth =
                        toFloat model.initialSize.width
                in
                Basics.round (initialWidth * (model.percentWidth / 100))
        }

    else
        model



-- TRACK --


track : Msg -> Tracking.Event
track msg =
    case msg of
        FieldUpdated _ _ ->
            Tracking.none

        LockButtonClicked ->
            "lock-button-clicked"
                |> Tracking.noProps

        FieldFocused field ->
            [ def "field" <| E.string (fieldToString field) ]
                |> Tracking.withProps
                    "field-focused"

        ScaleClick ->
            "scale-clicked"
                |> Tracking.noProps
