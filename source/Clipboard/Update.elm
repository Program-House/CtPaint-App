module Clipboard.Update exposing (..)

import Types exposing (Model)


copy : Model -> Model
copy model =
    { model | clipboard = model.selection }


cut : Model -> Model
cut model =
    { model
        | clipboard = model.selection
        , selection = Nothing
    }


paste : Model -> Model
paste model =
    { model | selection = model.clipboard }