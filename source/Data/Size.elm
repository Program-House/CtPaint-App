module Data.Size
    exposing
        ( Size
        , center
        , divideBy
        , encode
        , fromPositions
        , subtractFromHeight
        , subtractFromWidth
        , toPosition
        )

import Position.Data as Position exposing (Position)
import Json.Encode as JE
import Style
import Util exposing (def)


type alias Size =
    { width : Int
    , height : Int
    }



-- HELPERS --


center : Size -> Position
center { width, height } =
    { x = width // 2
    , y = height // 2
    }


subtractFromHeight : Int -> Size -> Size
subtractFromHeight int { width, height } =
    { width = width
    , height = height - int
    }


subtractFromWidth : Int -> Size -> Size
subtractFromWidth int { width, height } =
    { width = width - int
    , height = height
    }


divideBy : Int -> Size -> Size
divideBy int { width, height } =
    { width = width // int
    , height = height // int
    }


fromPositions : Position -> Position -> Size
fromPositions p q =
    let
        minPos =
            Position.min p q

        maxPos =
            Position.max p q
    in
    Size
        (maxPos.x - minPos.x + 1)
        (maxPos.y - minPos.y + 1)


toPosition : Size -> Position
toPosition { width, height } =
    { x = width, y = height }


encode : Size -> JE.Value
encode { width, height } =
    [ def "width" <| JE.int width
    , def "height" <| JE.int height
    ]
        |> JE.object
