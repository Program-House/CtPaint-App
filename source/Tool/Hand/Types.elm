module Tool.Hand.Types exposing (Message(..))

import Mouse exposing (Position)


type Message
    = OnScreenMouseDown Position
    | SubMouseMove Position
    | SubMouseUp