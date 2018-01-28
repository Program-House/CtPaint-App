module Data.Flags exposing (Flags, decoder)

import Data.Project as Project exposing (Project)
import Data.User as User
import Json.Decode as Decode exposing (Decoder)
import Json.Decode.Pipeline
    exposing
        ( custom
        , decode
        , optional
        , required
        )
import Keyboard.Extra.Browser exposing (Browser(Chrome, FireFox))
import Random.Pcg as Random exposing (Seed)
import Window exposing (Size)


type alias Flags =
    { windowSize : Size
    , seed : Seed
    , isMac : Bool
    , browser : Browser
    , user : User.Model
    , init : Init
    , localWork : LocalWork
    , mountPath : String
    , buildNumber : Int
    }


type LocalWork
    = NoLocalWork
    | ExistingWork (Maybe Project) String


type Init
    = NoInit
    | New
    | Drawing String
    | Image String



-- DECODER --


decoder : Decoder Flags
decoder =
    decode Flags
        |> custom windowDecoder
        |> optional "seed" seedDecoder (Random.initialSeed 1776)
        |> optional "isMac" Decode.bool True
        |> required "browser" browserDecoder
        |> custom userDecoder
        |> required "init" initDecoder
        |> required "localWork" localWorkDecoder
        |> required "mountPath" Decode.string
        |> required "buildNumber" Decode.int


userDecoder : Decoder User.Model
userDecoder =
    browserDecoder
        |> Decode.field "browser"
        |> Decode.andThen
            (User.modelDecoder >> Decode.field "user")


browserDecoder : Decoder Browser
browserDecoder =
    Decode.string
        |> Decode.andThen toBrowser


toBrowser : String -> Decoder Browser
toBrowser browser =
    case browser of
        "Firefox" ->
            Decode.succeed FireFox

        "Chrome" ->
            Decode.succeed Chrome

        "Unknown" ->
            Decode.succeed Chrome

        other ->
            Decode.fail ("Unknown browser type " ++ other)


localWorkDecoder : Decoder LocalWork
localWorkDecoder =
    [ Decode.null NoLocalWork
    , existingLocalWorkDecoder
    ]
        |> Decode.oneOf


existingLocalWorkDecoder : Decoder LocalWork
existingLocalWorkDecoder =
    decode ExistingWork
        |> optional "project" (Decode.map Just Project.decoder) Nothing
        |> required "data" Decode.string


initDecoder : Decoder Init
initDecoder =
    Decode.field "type" Decode.string
        |> Decode.andThen toInit


toInit : String -> Decoder Init
toInit type_ =
    case type_ of
        "init new drawing" ->
            Decode.succeed New

        "init image" ->
            Decode.string
                |> Decode.field "payload"
                |> Decode.map Image

        "init drawing" ->
            Decode.string
                |> Decode.field "payload"
                |> Decode.map Drawing

        "init paint app" ->
            Decode.succeed NoInit

        _ ->
            Decode.fail ("Unknown init type : " ++ type_)


seedDecoder : Decoder Seed
seedDecoder =
    Decode.map Random.initialSeed Decode.int


windowDecoder : Decoder Size
windowDecoder =
    Decode.map2 Size
        (Decode.field "windowWidth" Decode.int)
        (Decode.field "windowHeight" Decode.int)
