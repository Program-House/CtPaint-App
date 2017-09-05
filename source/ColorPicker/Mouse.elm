module ColorPicker.Mouse exposing (subscriptions)

import ColorPicker.Types exposing (Message(..), Model)
import Mouse


subscriptions : Model -> Sub Message
subscriptions model =
    if model.show && model.clickState /= Nothing then
        Sub.batch
            [ Mouse.moves HeaderMouseMove
            , Mouse.ups HeaderMouseUp
            ]
    else
        Sub.none
