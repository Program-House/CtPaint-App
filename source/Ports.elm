port module Ports exposing
    ( JsMsg(..)
    , SavePayload
    , fromJs
    , returnFocus
    , send
    , sendTracking
    , stealFocus
    )

import Array exposing (Array)
import Canvas exposing (Canvas, Size)
import Canvas.Helpers
import Color exposing (Color)
import Color.Palette.Data as Palette
import Color.Swatches.Data as Swatches
    exposing
        ( Swatches
        )
import Data.Config as Config exposing (Config)
import Data.Tracking as Tracking
import Data.User as User exposing (User)
import Id exposing (Id, Origin(Local, Remote))
import Json.Encode as Encode exposing (Value)
import Util exposing (def)


type JsMsg
    = StealFocus
    | ReturnFocus
    | Save SavePayload
    | Download String
    | AttemptLogin String String
    | Logout
    | OpenNewWindow String
    | RedirectPageTo String
    | OpenUpFileUpload
    | ReadFile
    | LoadDrawing Id
    | Track Tracking.Payload


type alias SavePayload =
    { canvas : Canvas
    , swatches : Swatches
    , palette : Array Color
    , name : String
    , nameIsGenerated : Bool
    , email : String
    , id : Origin
    }


sendTracking : Config -> User.State -> Tracking.Event -> Cmd msg
sendTracking config user event =
    case Tracking.toMaybe (Tracking.namespace "desktop" event) of
        Just ( name, properties ) ->
            { sessionId = config.sessionId
            , email = User.getEmail user
            , name = name
            , properties = properties
            }
                |> Track
                |> send

        Nothing ->
            Cmd.none


returnFocus : Cmd msg
returnFocus =
    send ReturnFocus


stealFocus : Cmd msg
stealFocus =
    send StealFocus


toCmd : String -> Value -> Cmd msg
toCmd type_ payload =
    [ def "type" <| Encode.string type_
    , def "payload" payload
    ]
        |> Encode.object
        |> toJs


send : JsMsg -> Cmd msg
send msg =
    case msg of
        StealFocus ->
            toCmd "stealFocus" Encode.null

        ReturnFocus ->
            toCmd "returnFocus" Encode.null

        Save { swatches, palette, canvas, name, nameIsGenerated, id, email } ->
            [ def "canvas" <| Canvas.Helpers.encode canvas
            , def "palette" <| Palette.encode palette
            , def "swatches" <| Swatches.encode swatches
            , def "name" <| Encode.string name
            , def "nameIsGenerated" <| Encode.bool nameIsGenerated
            , def "email" <| Encode.string email
            , def "id" <| Util.encodeOrigin id
            ]
                |> Encode.object
                |> toCmd "save"

        Download fn ->
            toCmd "download" (Encode.string fn)

        AttemptLogin email password ->
            [ def "email" <| Encode.string email
            , def "password" <| Encode.string password
            ]
                |> Encode.object
                |> toCmd "attemptLogin"

        Logout ->
            toCmd "logout" Encode.null

        OpenNewWindow url ->
            url
                |> Encode.string
                |> toCmd "openNewWindow"

        RedirectPageTo url ->
            url
                |> Encode.string
                |> toCmd "redirectPageTo"

        OpenUpFileUpload ->
            toCmd "openUpFileUpload" Encode.null

        ReadFile ->
            toCmd "readFile" Encode.null

        LoadDrawing id ->
            toCmd "loadDrawing" (Id.encode id)

        Track payload ->
            toCmd "track" (Tracking.encode payload)


port toJs : Value -> Cmd msg


port fromJs : (Value -> msg) -> Sub msg
