module Tool.Rectangle.Update exposing (update)

import Canvas exposing (Size)
import Draw.Rectangle as Rectangle
import History.Update as History
import Model exposing (Model)
import Mouse exposing (Position)
import Tool.Rectangle.Types exposing (Msg(..))
import Tool.Types exposing (Tool(..))
import Tool.Util exposing (adjustPosition)
import Util exposing (tbw)


update : Msg -> Maybe Position -> Model -> Model
update message toolModel model =
    case ( message, toolModel ) of
        ( OnScreenMouseDown position, Nothing ) ->
            let
                adjustedPosition =
                    adjustPosition model 0 position
            in
            { model
                | tool =
                    Rectangle (Just adjustedPosition)
                , drawAtRender =
                    Rectangle.draw
                        model.swatches.primary
                        adjustedPosition
                        adjustedPosition
            }
                |> History.addCanvas

        ( SubMouseMove position, Just priorPosition ) ->
            { model
                | drawAtRender =
                    Rectangle.draw
                        model.swatches.primary
                        priorPosition
                        (adjustPosition model tbw position)
            }

        ( SubMouseUp position, Just priorPosition ) ->
            { model
                | tool = Rectangle Nothing
                , drawAtRender = Canvas.batch []
                , pendingDraw =
                    Canvas.batch
                        [ model.pendingDraw
                        , Rectangle.draw
                            model.swatches.primary
                            priorPosition
                            (adjustPosition model tbw position)
                        ]
            }

        _ ->
            model
