module Tool.Pencil.Update exposing (..)

import Canvas exposing (DrawOp(..))
import Draw.Line as Line
import History.Update as History
import Mouse exposing (Position)
import Tool exposing (Tool(..))
import Tool.Pencil.Types exposing (Msg(..))
import Tool.Util exposing (adjustPosition)
import Types exposing (Model)
import Util exposing (tbw)


update : Msg -> Maybe Position -> Model -> Model
update message tool ({ canvasPosition } as model) =
    case ( message, tool ) of
        ( OnScreenMouseDown position, Nothing ) ->
            let
                adjustedPosition =
                    adjustPosition model 0 position
            in
            { model
                | tool = Pencil (Just adjustedPosition)
                , pendingDraw =
                    Canvas.batch
                        [ model.pendingDraw
                        , Line.draw
                            model.swatches.primary
                            adjustedPosition
                            adjustedPosition
                        ]
            }
                |> History.addCanvas

        ( SubMouseMove position, Just priorPosition ) ->
            let
                adjustedPosition =
                    adjustPosition model tbw position
            in
            { model
                | tool = Pencil (Just adjustedPosition)
                , pendingDraw =
                    Canvas.batch
                        [ model.pendingDraw
                        , Line.draw
                            model.swatches.primary
                            priorPosition
                            adjustedPosition
                        ]
            }

        ( SubMouseUp, _ ) ->
            { model
                | tool = Pencil Nothing
            }

        _ ->
            model
