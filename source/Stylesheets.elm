port module Stylesheets exposing (..)

import ColorPicker
import Css.File exposing (CssCompilerProgram, CssFileStructure)
import Error
import Html.Custom
import Import
import Menu
import Minimap
import Palette
import ReplaceColor
import Scale
import Taskbar
import Text
import Toolbar
import Tuple.Infix exposing ((:=))
import Upload
import View


port files : CssFileStructure -> Cmd msg


main : CssCompilerProgram
main =
    [ Html.Custom.css
    , View.css
    , Toolbar.css
    , Taskbar.css
    , Palette.css
    , ColorPicker.css
    , Minimap.css
    , Menu.css
    , ReplaceColor.css
    , Import.css
    , Scale.css
    , Text.css
    , Error.css
    , Upload.css
    ]
        |> Css.File.compile
        |> (,) "./development/paint-app-styles.css"
        |> List.singleton
        |> Css.File.toFileStructure
        |> Css.File.compiler files
