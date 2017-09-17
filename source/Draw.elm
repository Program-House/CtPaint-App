module Draw exposing (..)

import Array exposing (Array)
import Canvas
    exposing
        ( Canvas
        , DrawImageParams(..)
        , DrawOp(..)
        , Point
        , Size
        )
import Color exposing (Color)
import List.Extra exposing (groupsOf)
import Mouse exposing (Position)
import RasterShapes as Shapes
import Util exposing (positionMin, toPoint, toSize)


-- LINE --


line : Color -> Position -> Position -> DrawOp
line color p0 p1 =
    Shapes.line p0 p1
        |> List.map (toPoint >> pixel color)
        |> Canvas.batch



-- PIXEL --


pixel : Color -> Point -> DrawOp
pixel color point =
    PutImageData
        (fromColor color)
        (Size 1 1)
        point


fromColor : Color -> List Int
fromColor color =
    let
        { red, green, blue, alpha } =
            Color.toRgb color
    in
    [ red
    , green
    , blue
    , round (alpha * 255)
    ]



-- RECTANGLE --


rectangle : Color -> Position -> Position -> DrawOp
rectangle color p q =
    Shapes.rectangle2 p q
        |> List.map (toPoint >> pixel color)
        |> Canvas.batch


filledRectangle : Color -> Size -> Position -> DrawOp
filledRectangle color size position =
    [ BeginPath
    , Rect (toPoint position) size
    , FillStyle color
    , Fill
    ]
        |> Canvas.batch



-- SELECT --


pasteSelection : Position -> Canvas -> DrawOp
pasteSelection position selection =
    DrawImage selection (At (toPoint position))


getSelection : Position -> Position -> Color -> Canvas -> ( Canvas, DrawOp )
getSelection p q color canvas =
    let
        origin : Position
        origin =
            positionMin p q

        size : Size
        size =
            toSize p q

        cropOp : DrawOp
        cropOp =
            CropScaled
                (toPoint origin)
                size
                (Point 0 0)
                size
                |> DrawImage canvas
    in
    ( Canvas.draw
        cropOp
        (Canvas.initialize size)
    , filledRectangle color size origin
    )


crop : Position -> Position -> Canvas -> Canvas
crop p q canvas =
    let
        origin : Position
        origin =
            positionMin p q

        size : Size
        size =
            toSize p q

        cropOp : DrawOp
        cropOp =
            CropScaled
                (toPoint origin)
                size
                (Point 0 0)
                size
                |> DrawImage canvas
    in
    Canvas.draw
        cropOp
        (Canvas.initialize size)



-- UTIL --


makeRectParams : Position -> Position -> ( Position, Size )
makeRectParams p q =
    ( positionMin p q
    , Size (abs (p.x - q.x)) (abs (p.y - q.y))
    )


colorAt : Position -> Canvas -> Color
colorAt pos =
    Canvas.getImageData (toPoint pos) (Size 1 1)
        >> toColor


toColor : List Int -> Color
toColor values =
    case values of
        r :: g :: b :: a :: [] ->
            Color.rgb r g b

        _ ->
            Color.black


toGrid : Canvas -> Array (Array Color)
toGrid canvas =
    let
        size =
            Canvas.getSize canvas
    in
    canvas
        |> Canvas.getImageData (Point 0 0) size
        |> groupsOf 4
        |> List.map toColor
        |> groupsOf size.width
        |> List.map Array.fromList
        |> Array.fromList