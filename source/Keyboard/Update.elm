module Keyboard.Update exposing (update)

import Canvas
import Clipboard
import Dict exposing (Dict)
import Draw
import History
import Menu exposing (Menu(..))
import Menu.Download.Types as Download
import Menu.Import.Types as Import
import Menu.Scale.Types as Scale
import Minimap.Types as Minimap
import Mouse exposing (Position)
import Tool exposing (Tool(..))
import Tool.Zoom as Zoom
import Types
    exposing
        ( Command(..)
        , Direction(..)
        , KeyPayload
        , Model
        , Msg(..)
        , payloadToString
        )
import Util exposing ((&))


update : Direction -> KeyPayload -> Model -> ( Model, Cmd Msg )
update direction payload model =
    case direction of
        Up ->
            updateUp payload model

        Down ->
            updateDown payload model & Cmd.none


updateUp : KeyPayload -> Model -> ( Model, Cmd Msg )
updateUp payload model =
    case getCommand payload model.cmdKey model.keyboardUpConfig of
        NoCommand ->
            model & Cmd.none

        SetToolToPencil ->
            { model | tool = Pencil Nothing } & Cmd.none

        SetToolToHand ->
            { model | tool = Hand Nothing } & Cmd.none

        SetToolToSelect ->
            { model | tool = Select Nothing } & Cmd.none

        SetToolToFill ->
            { model | tool = Fill } & Cmd.none

        SwatchesOneTurn ->
            { model
                | swatches =
                    { primary = model.swatches.first
                    , first = model.swatches.second
                    , second = model.swatches.third
                    , third = model.swatches.primary
                    , keyIsDown = False
                    }
            }
                & Cmd.none

        SwatchesThreeTurns ->
            { model
                | swatches =
                    { primary = model.swatches.third
                    , first = model.swatches.primary
                    , second = model.swatches.first
                    , third = model.swatches.second
                    , keyIsDown = False
                    }
            }
                & Cmd.none

        SwatchesTwoTurns ->
            { model
                | swatches =
                    { primary = model.swatches.second
                    , first = model.swatches.third
                    , second = model.swatches.primary
                    , third = model.swatches.first
                    , keyIsDown = False
                    }
            }
                & Cmd.none

        Undo ->
            History.undo model & Cmd.none

        Redo ->
            History.redo model & Cmd.none

        Copy ->
            Clipboard.copy model & Cmd.none

        Cut ->
            Clipboard.cut model & Cmd.none

        Paste ->
            Clipboard.paste model & Cmd.none

        SelectAll ->
            { model
                | selection = Just ( Position 0 0, model.canvas )
                , canvas =
                    let
                        drawOp =
                            Draw.filledRectangle
                                model.swatches.second
                                (Canvas.getSize model.canvas)
                                (Position 0 0)
                    in
                    Canvas.getSize model.canvas
                        |> Canvas.initialize
                        |> Canvas.draw drawOp
            }
                & Cmd.none

        Types.ZoomIn ->
            let
                newZoom =
                    Zoom.next model.zoom
            in
            if model.zoom == newZoom then
                model & Cmd.none
            else
                Zoom.set newZoom model & Cmd.none

        Types.ZoomOut ->
            let
                newZoom =
                    Zoom.prev model.zoom
            in
            if model.zoom == newZoom then
                model & Cmd.none
            else
                Zoom.set newZoom model & Cmd.none

        ShowMinimap ->
            case model.minimap of
                Nothing ->
                    { model
                        | minimap =
                            model.windowSize
                                |> Minimap.init
                                |> Just
                    }
                        & Cmd.none

                Just _ ->
                    { model | minimap = Nothing } & Cmd.none

        Types.Download ->
            let
                ( downloadModel, seed ) =
                    Download.init
                        model.projectName
                        model.seed
                        model.windowSize
            in
            { model
                | seed = seed
                , menu = Menu.Download downloadModel
            }
                ! [ Menu.stealFocus () ]

        Types.Import ->
            { model
                | menu =
                    model.windowSize
                        |> Import.init
                        |> Menu.Import
            }
                ! [ Menu.stealFocus () ]

        Types.Scale ->
            { model
                | menu =
                    case model.selection of
                        Just ( position, canvas ) ->
                            Scale.init
                                model.windowSize
                                (Canvas.getSize canvas)
                                |> Menu.Scale

                        Nothing ->
                            Scale.init
                                model.windowSize
                                (Canvas.getSize model.canvas)
                                |> Menu.Scale
            }
                & Menu.stealFocus ()

        SwitchGalleryView ->
            { model
                | galleryView = not model.galleryView
            }
                & Cmd.none


updateDown : KeyPayload -> Model -> Model
updateDown payload model =
    case getCommand payload model.cmdKey model.keyboardDownConfig of
        NoCommand ->
            model

        SwatchesOneTurn ->
            if not model.swatches.keyIsDown then
                { model
                    | swatches =
                        { primary = model.swatches.first
                        , first = model.swatches.second
                        , second = model.swatches.third
                        , third = model.swatches.primary
                        , keyIsDown = True
                        }
                }
            else
                model

        SwatchesTwoTurns ->
            if not model.swatches.keyIsDown then
                { model
                    | swatches =
                        { primary = model.swatches.second
                        , first = model.swatches.third
                        , second = model.swatches.primary
                        , third = model.swatches.first
                        , keyIsDown = True
                        }
                }
            else
                model

        SwatchesThreeTurns ->
            if not model.swatches.keyIsDown then
                { model
                    | swatches =
                        { primary = model.swatches.third
                        , first = model.swatches.primary
                        , second = model.swatches.first
                        , third = model.swatches.second
                        , keyIsDown = True
                        }
                }
            else
                model

        _ ->
            model


getCommand : KeyPayload -> (KeyPayload -> Bool) -> Dict String Command -> Command
getCommand payload cmdKey config =
    case Dict.get (payloadToString cmdKey payload) config of
        Just command ->
            command

        Nothing ->
            NoCommand
