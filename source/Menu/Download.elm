module Menu.Download exposing
    ( Flags
    , Model
    , Msg
    , init
    , track
    , update
    , view
    )

import Data.Tracking as Tracking
import Html exposing (Html, a, form, input, p, text)
import Html.Attributes exposing (placeholder, value)
import Html.Custom
import Html.Events exposing (onClick, onInput, onSubmit)
import Menu.Reply exposing (Reply(CloseMenu))
import Ports exposing (JsMsg(Download))
import Return2 as R2
import Return3 as R3 exposing (Return)



-- TYPES --


type Msg
    = FieldUpdated String
    | Submitted
    | DownloadButtonPressed


type alias Model =
    { field : String
    , placeholder : String
    }



-- UPDATE --


update : Msg -> Model -> Return Model Msg Reply
update msg model =
    case msg of
        FieldUpdated str ->
            { model | field = str }
                |> R3.withNothing

        Submitted ->
            download model

        DownloadButtonPressed ->
            download model


download : Model -> Return Model Msg Reply
download model =
    model
        |> R2.withCmd (downloadCmd model)
        |> R3.withReply CloseMenu


downloadCmd : Model -> Cmd Msg
downloadCmd =
    fileName >> Download >> Ports.send


fileName : Model -> String
fileName { field, placeholder } =
    case field of
        "" ->
            placeholder

        _ ->
            field



-- TRACK --


track : Msg -> Tracking.Event
track msg =
    case msg of
        DownloadButtonPressed ->
            "download-button-pressed"
                |> Tracking.noProps

        _ ->
            Tracking.none



-- VIEW --


view : Model -> Html Msg
view model =
    [ Html.Custom.field
        [ onSubmit Submitted
        ]
        [ p [] [ Html.text "file name" ]
        , input
            [ onInput FieldUpdated
            , value model.field
            , placeholder model.placeholder
            ]
            []
        ]
    , Html.Custom.menuButton
        [ onClick DownloadButtonPressed ]
        [ Html.text "download" ]
    ]
        |> Html.Custom.cardBody []



-- INIT --


type alias Flags =
    { name : String
    , nameIsGenerated : Bool
    }


init : Flags -> Model
init { name, nameIsGenerated } =
    { field =
        if nameIsGenerated then
            ""

        else
            name
    , placeholder = name
    }
