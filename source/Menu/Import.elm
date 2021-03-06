module Menu.Import exposing
    ( Model
    , Msg
    , css
    , init
    , track
    , update
    , view
    )

import Canvas exposing (Canvas, Error)
import Chadtech.Colors as Ct
import Css exposing (..)
import Css.Elements
import Css.Namespace exposing (namespace)
import Data.Tracking as Tracking
import Helpers.Import exposing (loadCmd)
import Html exposing (Html, a, div, form, input, p, text)
import Html.Attributes exposing (placeholder, value)
import Html.CssHelpers
import Html.Custom
import Html.Events exposing (onClick, onInput, onSubmit)
import Json.Encode as E
import Menu.Loaded as Loaded
import Menu.Reply exposing (Reply)
import Return2 as R2
import Return3 as R3 exposing (Return)
import Util exposing (def)



-- TYPES --


type Msg
    = FieldUpdated String
    | ImportPressed
    | Submitted
    | CanvasLoaded (Result Error Canvas)
    | TryAgainPressed
    | LoadedMsg Loaded.Msg


type Model
    = Url String
    | Loading
    | Loaded Canvas
    | Fail



-- STYLES --


type Class
    = Field
    | LoadingText
    | FailText
    | Error


css : Stylesheet
css =
    [ Css.class Field
        [ children
            [ Css.Elements.input
                [ width (px 360) ]
            , Css.Elements.p
                [ width (px 40) ]
            ]
        ]
    , Css.class LoadingText
        [ textAlign center
        , marginTop (px 8)
        ]
    , Css.class FailText
        [ textAlign center
        , marginBottom (px 8)
        ]
    , Css.class Error
        [ backgroundColor Ct.lowWarning ]
    ]
        |> namespace importNamespace
        |> stylesheet


importNamespace : String
importNamespace =
    Html.Custom.makeNamespace "Import"



-- VIEW --


{ class } =
    Html.CssHelpers.withNamespace importNamespace


normalView : String -> Html Msg
normalView str =
    [ Html.Custom.field
        [ class [ Field ]
        , onSubmit Submitted
        ]
        [ p [] [ Html.text "url" ]
        , input
            [ onInput FieldUpdated
            , value str
            , placeholder "http://"
            ]
            []
        ]
    , Html.Custom.menuButton
        [ onClick ImportPressed ]
        [ Html.text "import" ]
    ]
        |> Html.Custom.cardBody []


errorView : Html Msg
errorView =
    [ p
        [ class [ FailText ] ]
        [ Html.text "Sorry, I couldnt load that image" ]
    , Html.Custom.menuButton
        [ onClick TryAgainPressed ]
        [ Html.text "try again" ]
    ]
        |> Html.Custom.cardBody
            [ class [ Error ] ]


loadingView : Html Msg
loadingView =
    [ Html.Custom.spinner []
    , p
        [ class [ LoadingText ] ]
        [ Html.text "Loading.." ]
    ]
        |> Html.Custom.cardBody []


view : Model -> Html Msg
view model =
    case model of
        Url str ->
            normalView str

        Loading ->
            loadingView

        Loaded canvas ->
            canvas
                |> Loaded.view
                |> Html.map LoadedMsg

        Fail ->
            errorView



-- INIT --


init : Model
init =
    Url ""



-- UPDATE --


update : Msg -> Model -> Return Model Msg Reply
update msg model =
    case msg of
        FieldUpdated str ->
            case model of
                Url _ ->
                    Url str
                        |> R3.withNothing

                _ ->
                    model
                        |> R3.withNothing

        ImportPressed ->
            attemptLoad model

        Submitted ->
            attemptLoad model

        CanvasLoaded (Ok canvas) ->
            canvas
                |> Loaded
                |> R3.withNothing

        CanvasLoaded (Err err) ->
            Fail
                |> R3.withNothing

        TryAgainPressed ->
            init
                |> R3.withNothing

        LoadedMsg subMsg ->
            case model of
                Loaded canvas ->
                    Loaded.update subMsg canvas
                        |> R3.withTuple ( model, Cmd.none )

                _ ->
                    model
                        |> R3.withNothing


attemptLoad : Model -> Return Model Msg Reply
attemptLoad model =
    case model of
        Url url ->
            sendLoadCmd url

        _ ->
            model
                |> R3.withNothing


sendLoadCmd : String -> Return Model Msg Reply
sendLoadCmd url =
    Loading
        |> R2.withCmd (loadCmd url CanvasLoaded)
        |> R3.withNoReply



-- TRACK --


track : Msg -> Model -> Tracking.Event
track msg model =
    case msg of
        FieldUpdated _ ->
            Tracking.none

        ImportPressed ->
            "import-pressed"
                |> Tracking.noProps

        Submitted ->
            "submitted"
                |> Tracking.noProps

        CanvasLoaded result ->
            [ def "error" (canvasLoadedTrackingPayload result) ]
                |> Tracking.withProps
                    "canvas-loaded"

        TryAgainPressed ->
            "try-again-pressed"
                |> Tracking.noProps

        LoadedMsg subMsg ->
            case model of
                Loaded _ ->
                    Loaded.track subMsg

                _ ->
                    [ "loaded msg while no loaded state"
                        |> E.string
                        |> def "mismatch"
                    ]
                        |> Tracking.withProps
                            "msg-mismatch"


canvasLoadedTrackingPayload : Result Error Canvas -> E.Value
canvasLoadedTrackingPayload result =
    case result of
        Ok _ ->
            E.null

        Err _ ->
            E.string "Errored!"
