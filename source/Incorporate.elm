module Incorporate
    exposing
        ( colorModel
        , menu
        )

import Canvas
import Canvas.Draw as Draw
import Color.Model as Color
import Color.Reply as CR
import Data.Drawing as Drawing
import Data.Flags exposing (Init(NormalInit), projectNameGenerator)
import Data.Size as Size exposing (Size)
import Data.Taco as Taco
import Data.User as User
import Helpers.Drawing
import Helpers.Random as Random
import History.Helpers as History
import Init
import Menu.Model as Menu
import Menu.Reply as MR
import Model exposing (Model)
import Msg exposing (Msg)
import Ports
import Position.Data as Position
    exposing
        ( Position
        )
import Position.Helpers
import Return2 as R2
import Selection.Model as Selection


colorModel : Color.Model -> Maybe CR.Reply -> Model -> ( Model, Cmd Msg )
colorModel colorModel maybeReply model =
    case maybeReply of
        Nothing ->
            { model | color = colorModel }
                |> R2.withNoCmd

        Just (CR.UpdateColorHistory index color) ->
            { model | color = colorModel }
                |> History.color index color
                |> R2.withNoCmd


menu : Menu.Model -> Maybe MR.Reply -> Model -> ( Model, Cmd Msg )
menu menu maybeReply model =
    case maybeReply of
        Nothing ->
            { model
                | menu = Just menu
            }
                |> R2.withNoCmd

        Just reply ->
            menuReply menu reply model


menuReply : Menu.Model -> MR.Reply -> Model -> ( Model, Cmd Msg )
menuReply menu reply model =
    case reply of
        MR.CloseMenu ->
            Model.closeMenu model

        MR.IncorporateImageAsSelection image ->
            let
                { width, height } =
                    Canvas.getSize image
            in
            { model
                | selection =
                    { canvas = image
                    , position =
                        model.canvas.main
                            |> Canvas.getSize
                            |> Size.subtractFromWidth width
                            |> Size.subtractFromHeight height
                            |> Size.divideBy 2
                            |> Size.toPosition
                    , origin = Selection.Other
                    }
                        |> Just
            }
                |> Model.closeMenu

        MR.IncorporateImageAsCanvas image ->
            { model
                | canvas =
                    { main = image
                    , position =
                        Position.Helpers.centerInWorkarea
                            model.windowSize
                            (Canvas.getSize image)
                    }
            }
                |> Model.closeMenu

        MR.ScaleTo w h ->
            case model.selection of
                Nothing ->
                    model
                        |> History.canvas
                        |> Model.mapMainCanvas (Canvas.scale w h)
                        |> Model.closeMenu

                Just selection ->
                    { model
                        | selection =
                            Selection.mapCanvas
                                (Canvas.scale w h)
                                selection
                                |> Just
                    }
                        |> Model.closeMenu

        MR.AddText str ->
            addText str model

        MR.Replace target replacement ->
            case model.selection of
                Just selection ->
                    { model
                        | selection =
                            Selection.mapCanvas
                                (Draw.replace target replacement)
                                selection
                                |> Just
                    }
                        |> Model.closeMenu

                Nothing ->
                    model
                        |> History.canvas
                        |> Model.mapMainCanvas (Draw.replace target replacement)
                        |> Model.closeMenu

        MR.SetUser user ->
            { model
                | menu = Nothing
                , taco =
                    user
                        |> User.initModel Drawing.Local
                        |> User.LoggedIn
                        |> Taco.setUser model.taco
            }
                |> R2.withNoCmd

        MR.AttemptingLogin ->
            { model
                | menu = Just menu
                , taco =
                    User.LoggingIn
                        |> Taco.setUser model.taco
            }
                |> R2.withNoCmd

        MR.NoLongerLoggingIn ->
            { model
                | menu = Just menu
                , taco =
                    User.LoggedOut
                        |> Taco.setUser model.taco
            }
                |> R2.withNoCmd

        MR.ResizeTo position size ->
            model
                |> History.canvas
                |> Model.mapMainCanvas
                    (Draw.resize position size model.color.swatches.bottom)
                |> Model.closeMenu

        MR.IncorporateDrawing drawing ->
            { model
                | taco =
                    case model.taco.user of
                        User.LoggedIn user ->
                            user
                                |> User.setDrawing drawing
                                |> User.LoggedIn
                                |> Taco.setUser model.taco

                        _ ->
                            model.taco
            }
                |> Model.closeMenu

        MR.TrySaving ->
            Helpers.Drawing.save model

        MR.Logout ->
            { windowSize = model.windowSize
            , isMac = model.taco.config.isMac
            , browser = model.taco.config.browser
            , user = User.LoggedOut
            , init = NormalInit
            , mountPath = model.taco.config.mountPath
            , buildNumber = model.taco.config.buildNumber
            , randomValues =
                let
                    ( newProjectName, newSeed ) =
                        identity
                            |> Random.from model.seed
                            |> Random.value projectNameGenerator
                in
                { sessionId = model.taco.config.sessionId
                , projectName = newProjectName
                , seed = newSeed
                }
            }
                |> Init.fromFlags
                |> R2.addCmd (Ports.send Ports.Logout)

        MR.SaveDrawingAttrs name ->
            let
                newModel =
                    { model | drawingName = name }
            in
            case Model.toSavePayload newModel of
                Just savePayload ->
                    newModel
                        |> Model.closeMenu
                        |> R2.addCmd
                            (Ports.send (Ports.Save savePayload))

                Nothing ->
                    newModel
                        |> Model.closeMenu

        MR.StartNewDrawing name nameIsGenerated canvas ->
            { model
                | canvas =
                    { main = canvas
                    , position =
                        Position.Helpers.centerInWorkarea
                            model.windowSize
                            (Canvas.getSize canvas)
                    }
                , drawingName = name
                , drawingNameIsGenerated = nameIsGenerated
            }
                |> Model.closeMenu


addText : String -> Model -> ( Model, Cmd msg )
addText str ({ color } as model) =
    let
        selection =
            Draw.text str color.swatches.top
    in
    { model
        | menu = Nothing
        , selection =
            { canvas = selection
            , position =
                selection
                    |> Canvas.getSize
                    |> Size.divideBy 2
                    |> Size.toPosition
                    |> Position.subtractFrom
                        (Position.Helpers.canvasPosInCenterOfWindow model)
            , origin = Selection.Other
            }
                |> Just
    }
        |> R2.withCmd Ports.returnFocus
