module Tool.RectangleFilled.Update exposing (update)

import Canvas exposing (Size)
import Draw exposing (makeRectParams)
import History
import Mouse exposing (Position)
import Tool exposing (Tool(..))
import Tool.RectangleFilled exposing (Msg(..))
import Tool.Util exposing (adjustPosition)
import Types exposing (Model)
import Util exposing (tbw)


update : Msg -> Maybe Position -> Model -> Model
update message toolModel model =
    case ( message, toolModel ) of
        ( ScreenMouseDown { clientPos }, Nothing ) ->
            let
                adjustedPosition =
                    adjustPosition model tbw clientPos
            in
            { model
                | tool =
                    RectangleFilled
                        (Just adjustedPosition)
                , drawAtRender =
                    Draw.filledRectangle
                        model.swatches.primary
                        (Size 1 1)
                        adjustedPosition
            }
                |> History.addCanvas

        ( SubMouseMove position, Just priorPosition ) ->
            let
                ( drawPosition, size ) =
                    makeRectParams
                        (adjustPosition model tbw position)
                        priorPosition
            in
            { model
                | drawAtRender =
                    Draw.filledRectangle
                        model.swatches.primary
                        size
                        drawPosition
            }

        ( SubMouseUp position, Just priorPosition ) ->
            let
                ( drawPosition, size ) =
                    makeRectParams
                        (adjustPosition model tbw position)
                        priorPosition
            in
            { model
                | tool = RectangleFilled Nothing
                , drawAtRender = Canvas.batch []
                , pendingDraw =
                    Canvas.batch
                        [ model.pendingDraw
                        , Draw.filledRectangle
                            model.swatches.primary
                            size
                            drawPosition
                        ]
            }

        _ ->
            model
