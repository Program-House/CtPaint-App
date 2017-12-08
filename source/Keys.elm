module Keys exposing (..)

import Canvas exposing (Canvas)
import Clipboard
import Data.Keys as Key exposing (Cmd(..))
import Data.Minimap exposing (State(..))
import Data.Tool as Tool exposing (Tool(..))
import Draw
import Helpers.History as History
import Helpers.Menu
import Menu
import Minimap
import Model exposing (Model)
import Platform.Cmd as Platform
import Ports exposing (JsMsg(..))
import Tool.Zoom as Zoom
import Tool.Zoom.Util as Zoom
import Tuple.Infix exposing ((&), (|&))


exec : Key.Cmd -> Model -> ( Model, Platform.Cmd msg )
exec keyCmd model =
    case keyCmd of
        NoCmd ->
            model & Cmd.none

        SetToolToPencil ->
            { model | tool = Pencil Nothing } & Cmd.none

        SetToolToHand ->
            { model | tool = Hand Nothing } & Cmd.none

        SetToolToSelect ->
            { model | tool = Select Nothing } & Cmd.none

        SetToolToFill ->
            { model | tool = Fill } & Cmd.none

        SetToolToSample ->
            { model | tool = Sample } & Cmd.none

        SetToolToLine ->
            { model | tool = Line Nothing } & Cmd.none

        SetToolToRectangle ->
            { model | tool = Rectangle Nothing } & Cmd.none

        SetToolToRectangleFilled ->
            { model | tool = RectangleFilled Nothing } & Cmd.none

        SwatchesTurnLeft ->
            swatchesTurnLeft model & Cmd.none

        SwatchesTurnRight ->
            swatchesTurnRight model & Cmd.none

        SwatchesQuickTurnLeft ->
            if model.swatches.keyIsDown then
                model & Cmd.none
            else
                model
                    |> swatchesTurnLeft
                    |> setKeyAsDown
                    & Cmd.none

        RevertQuickTurnLeft ->
            swatchesTurnRight (setKeyAsUp model)
                & Cmd.none

        SwatchesQuickTurnRight ->
            if model.swatches.keyIsDown then
                model & Cmd.none
            else
                model
                    |> swatchesTurnRight
                    |> setKeyAsDown
                    & Cmd.none

        RevertQuickTurnRight ->
            swatchesTurnLeft (setKeyAsUp model)
                & Cmd.none

        SwatchesQuickTurnDown ->
            if model.swatches.keyIsDown then
                model & Cmd.none
            else
                model
                    |> swatchesTurnLeft
                    |> swatchesTurnLeft
                    |> setKeyAsDown
                    & Cmd.none

        RevertQuickTurnDown ->
            model
                |> swatchesTurnLeft
                |> swatchesTurnLeft
                |> setKeyAsUp
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
                | selection = Just ( { x = 0, y = 0 }, model.canvas )
                , canvas =
                    let
                        drawOp =
                            Draw.filledRectangle
                                model.swatches.second
                                (Canvas.getSize model.canvas)
                                { x = 0, y = 0 }
                    in
                    Canvas.getSize model.canvas
                        |> Canvas.initialize
                        |> Canvas.draw drawOp
            }
                & Cmd.none

        Key.ZoomIn ->
            let
                newZoom =
                    Zoom.next model.zoom
            in
            if model.zoom == newZoom then
                model & Cmd.none
            else
                Zoom.set newZoom model & Cmd.none

        Key.ZoomOut ->
            let
                newZoom =
                    Zoom.prev model.zoom
            in
            if model.zoom == newZoom then
                model & Cmd.none
            else
                Zoom.set newZoom model & Cmd.none

        ToggleMinimap ->
            case model.minimap of
                Opened minimapModel ->
                    { model
                        | minimap =
                            minimapModel.externalPosition
                                |> Closed
                    }
                        & Cmd.none

                Closed position ->
                    { model
                        | minimap =
                            model.windowSize
                                |> Minimap.init (Just position)
                                |> Opened
                    }
                        & Cmd.none

                NotInitialized ->
                    { model
                        | minimap =
                            model.windowSize
                                |> Minimap.init Nothing
                                |> Opened
                    }
                        & Cmd.none

        SwitchGalleryView ->
            { model
                | galleryView = not model.galleryView
            }
                & Cmd.none

        InitImport ->
            { model
                | menu =
                    model.windowSize
                        |> Menu.initImport
                        |> Just
            }
                & Ports.send StealFocus

        InitDownload ->
            let
                ( menuModel, seed ) =
                    Menu.initDownload
                        (Maybe.map .name model.project)
                        model.seed
                        model.windowSize
            in
            { model
                | menu = Just menuModel
                , seed = seed
            }
                & Ports.send StealFocus

        InitText ->
            { model
                | menu =
                    model.windowSize
                        |> Menu.initText
                        |> Just
            }
                & Ports.send StealFocus

        InitScale ->
            let
                menu =
                    case model.selection of
                        Just ( _, selection ) ->
                            Menu.initScale
                                (Canvas.getSize selection)
                                model.windowSize
                                |> Just

                        Nothing ->
                            Menu.initScale
                                (Canvas.getSize model.canvas)
                                model.windowSize
                                |> Just
            in
            { model | menu = menu }
                & Ports.send StealFocus

        InitImgur ->
            model & Cmd.none

        InitReplaceColor ->
            Helpers.Menu.initReplaceColor model & Cmd.none

        ToggleColorPicker ->
            let
                { colorPicker } =
                    model

                { window } =
                    colorPicker

                newWindow =
                    { window
                        | show = not window.show
                    }
            in
            { model
                | colorPicker =
                    { colorPicker
                        | window = newWindow
                    }
            }
                & Cmd.none

        Delete ->
            case model.selection of
                Just _ ->
                    { model
                        | selection = Nothing
                    }
                        & Cmd.none

                Nothing ->
                    model & Cmd.none

        FlipHorizontal ->
            transform Draw.flipHorizontal model

        FlipVertical ->
            transform Draw.flipVertical model

        Rotate90 ->
            transform Draw.rotate90 model

        Rotate180 ->
            transform Draw.rotate180 model

        Rotate270 ->
            transform Draw.rotate270 model

        InvertColors ->
            transform Draw.invert model

        Save ->
            { canvas = model.canvas
            , project = model.project
            }
                |> SaveLocally
                |> Ports.send
                |& model

        SetTransparency ->
            case model.selection of
                Nothing ->
                    model & Cmd.none

                Just ( pos, selection ) ->
                    { model
                        | selection =
                            selection
                                |> Canvas.transparentColor model.swatches.second
                                |& pos
                                |> Just
                    }
                        & Cmd.none

        Upload ->
            OpenUpFileUpload
                |> Ports.send
                |& model


transform : (Canvas -> Canvas) -> Model -> ( Model, Platform.Cmd msg )
transform transformation model =
    case model.selection of
        Just ( position, selection ) ->
            { model
                | selection =
                    ( position
                    , transformation selection
                    )
                        |> Just
            }
                & Cmd.none

        Nothing ->
            { model
                | canvas =
                    transformation model.canvas
            }
                & Cmd.none


swatchesTurnLeft : Model -> Model
swatchesTurnLeft ({ swatches } as model) =
    { model
        | swatches =
            { swatches
                | primary = model.swatches.first
                , first = model.swatches.second
                , second = model.swatches.third
                , third = model.swatches.primary
            }
    }


swatchesTurnRight : Model -> Model
swatchesTurnRight ({ swatches } as model) =
    { model
        | swatches =
            { swatches
                | primary = model.swatches.third
                , first = model.swatches.primary
                , second = model.swatches.first
                , third = model.swatches.second
            }
    }


setKeyAsUp : Model -> Model
setKeyAsUp ({ swatches } as model) =
    { model
        | swatches =
            { swatches | keyIsDown = False }
    }


setKeyAsDown : Model -> Model
setKeyAsDown ({ swatches } as model) =
    { model
        | swatches =
            { swatches | keyIsDown = True }
    }
