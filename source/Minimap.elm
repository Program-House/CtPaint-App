module Minimap
    exposing
        ( css
        , init
        , subscriptions
        , update
        , view
        )

import Canvas
    exposing
        ( Canvas
        , DrawImageParams(..)
        , DrawOp(..)
        )
import Chadtech.Colors as Ct
import Css exposing (..)
import Css.Elements
import Css.Namespace exposing (namespace)
import Data.Minimap
    exposing
        ( ClickState(..)
        , Model
        , Msg(..)
        , Reply(..)
        , State(..)
        )
import Data.Selection as Selection
import Data.Tool exposing (Tool(..))
import Helpers.Zoom as Zoom
import Html exposing (Attribute, Html, a, div, p)
import Html.Attributes exposing (style)
import Html.CssHelpers
import Html.Custom exposing (card, cardBody, header, indent)
import Html.Events exposing (onClick)
import Mouse exposing (Position)
import MouseEvents exposing (MouseEvent)
import Tool
import Util exposing (toPoint)
import Window exposing (Size)


-- INIT --


init : Maybe Mouse.Position -> Size -> Model
init maybeInitialPosition { width, height } =
    { externalPosition =
        case maybeInitialPosition of
            Just position ->
                position

            Nothing ->
                { x = (width - floor minimapWidth) // 2
                , y = (height - floor minimapHeight) // 2
                }
    , internalPosition =
        { x = 0
        , y = 0
        }
    , zoom = 1
    , clickState = NoClicks
    }


extraHeight : Int
extraHeight =
    64


extraWidth : Int
extraWidth =
    8



-- SUBSCRIPTIONS --


subscriptions : Model -> Sub Msg
subscriptions model =
    case model.clickState of
        NoClicks ->
            Sub.none

        _ ->
            [ Mouse.moves MouseMoved
            , Mouse.ups (always MouseUp)
            ]
                |> Sub.batch



-- UPDATE --


update : Msg -> State -> State
update msg state =
    case state of
        NotInitialized ->
            NotInitialized

        Closed position ->
            Closed position

        Opened model ->
            updateOpened msg model


updateOpened : Msg -> Model -> State
updateOpened msg model =
    case msg of
        XButtonMouseUp ->
            Closed model.externalPosition

        XButtonMouseDown ->
            { model
                | clickState = XButtonIsDown
            }
                |> Opened

        ZoomInClicked ->
            zoomIn model |> Opened

        ZoomOutClicked ->
            zoomOut model |> Opened

        ZeroClicked ->
            { model | internalPosition = { x = 0, y = 0 } }
                |> Opened

        ScreenMouseDown { targetPos, clientPos } ->
            { model
                | clickState =
                    let
                        { x, y } =
                            model.internalPosition
                    in
                    { x = clientPos.x - x
                    , y = clientPos.y - y
                    }
                        |> ClickedInScreenAt
            }
                |> Opened

        HeaderMouseDown { targetPos, clientPos } ->
            case model.clickState of
                XButtonIsDown ->
                    Opened model

                _ ->
                    { model
                        | clickState =
                            { x = clientPos.x - targetPos.x
                            , y = clientPos.y - targetPos.y
                            }
                                |> ClickedInHeaderAt
                    }
                        |> Opened

        MouseMoved position ->
            case model.clickState of
                NoClicks ->
                    Opened model

                XButtonIsDown ->
                    Opened model

                ClickedInHeaderAt originalClick ->
                    { model
                        | externalPosition =
                            { x = position.x - originalClick.x
                            , y = position.y - originalClick.y
                            }
                    }
                        |> Opened

                ClickedInScreenAt originalClick ->
                    { model
                        | internalPosition =
                            { x = position.x - originalClick.x
                            , y = position.y - originalClick.y
                            }
                    }
                        |> Opened

        MouseUp ->
            { model
                | clickState = NoClicks
            }
                |> Opened


zoomOut : Model -> Model
zoomOut model =
    let
        newZoom =
            Zoom.prev model.zoom
    in
    if model.zoom == newZoom then
        model
    else
        adjust center 1 (set newZoom model)


zoomIn : Model -> Model
zoomIn model =
    let
        newZoom =
            Zoom.next model.zoom
    in
    if model.zoom == newZoom then
        model
    else
        adjust center -1 (set newZoom model)


center : Mouse.Position
center =
    { x = floor minimapWidth // 2
    , y = floor minimapHeight // 2
    }



-- HELPERS --


adjust : Mouse.Position -> Int -> Model -> Model
adjust { x, y } bias ({ zoom, internalPosition } as model) =
    let
        halfWindowSize =
            { width = floor minimapWidth // 2
            , height = floor minimapHeight // 2
            }

        x_ =
            (x - halfWindowSize.width) // zoom

        y_ =
            (y - halfWindowSize.height) // zoom
    in
    { model
        | internalPosition =
            { x = internalPosition.x + (x_ * bias)
            , y = internalPosition.y + (y_ * bias)
            }
    }


set : Int -> Model -> Model
set zoom ({ internalPosition } as model) =
    let
        halfWindowSize =
            { width = floor minimapWidth // 2
            , height = floor minimapHeight // 2
            }

        relZoom : Int -> Int
        relZoom d =
            d * zoom // model.zoom
    in
    { model
        | zoom = zoom
        , internalPosition =
            { x =
                halfWindowSize.width
                    |> (-) internalPosition.x
                    |> relZoom
                    |> (+) halfWindowSize.width
            , y =
                halfWindowSize.height
                    |> (-) internalPosition.y
                    |> relZoom
                    |> (+) halfWindowSize.height
            }
    }



-- STYLES --


type Class
    = Minimap
    | CanvasContainer
    | Screen
    | Button


minimapWidth : Float
minimapWidth =
    250


minimapHeight : Float
minimapHeight =
    250


css : Stylesheet
css =
    [ Css.class Minimap
        [ position absolute
        , paddingBottom (px 2)
        ]
    , Css.class Screen
        [ position absolute
        , left (px 0)
        , top (px 0)
        , height (px minimapHeight)
        , width (px minimapWidth)
        ]
    , (Css.class CanvasContainer << List.append indent)
        [ position relative
        , backgroundColor Ct.background2
        , overflow hidden
        , cursor move
        , width (px minimapWidth)
        , height (px minimapHeight)
        , children
            [ Css.Elements.canvas
                [ position absolute ]
            ]
        ]
    , Css.class Button
        [ marginRight (px 1)
        , marginTop (px 2)
        ]
    ]
        |> namespace minimapNamespace
        |> stylesheet


minimapNamespace : String
minimapNamespace =
    Html.Custom.makeNamespace "Minimap"



-- VIEW --


{ class, classList } =
    Html.CssHelpers.withNamespace minimapNamespace


view : Model -> Canvas -> Maybe Selection.Model -> Html Msg
view model canvas maybeSelection =
    card
        [ class [ Minimap ]
        , style
            [ Util.top model.externalPosition.y
            , Util.left model.externalPosition.x
            ]
        ]
        [ header
            { text = "mini map"
            , headerMouseDown = HeaderMouseDown
            , xButtonMouseDown = XButtonMouseDown
            , xButtonMouseUp = XButtonMouseUp
            }
        , cardBody
            []
            [ div
                [ class [ CanvasContainer ] ]
                [ Canvas.toHtml
                    (canvasAttrs model canvas)
                    (withSelection canvas maybeSelection)
                , screen
                ]
            , Html.Custom.toolButton
                { icon = Tool.icon ZoomIn
                , selected = False
                , attrs =
                    [ class [ Button ]
                    , onClick ZoomInClicked
                    ]
                }
            , Html.Custom.toolButton
                { icon = Tool.icon ZoomOut
                , selected = False
                , attrs =
                    [ class [ Button ]
                    , onClick ZoomOutClicked
                    ]
                }
            , Html.Custom.toolButton
                { icon = Tool.icon (Hand Nothing)
                , selected = False
                , attrs =
                    [ class [ Button ]
                    , onClick ZeroClicked
                    ]
                }
            ]
        ]


withSelection : Canvas -> Maybe Selection.Model -> Canvas
withSelection canvas maybeSelection =
    case maybeSelection of
        Nothing ->
            canvas

        Just selection ->
            Canvas.draw (drawSelectionOp selection) canvas


drawSelectionOp : Selection.Model -> DrawOp
drawSelectionOp { position, canvas } =
    DrawImage canvas (At (toPoint position))


canvasAttrs : Model -> Canvas -> List (Attribute Msg)
canvasAttrs { zoom, internalPosition } canvas =
    let
        size =
            Canvas.getSize canvas
    in
    [ Util.left internalPosition.x
    , Util.top internalPosition.y
    , Util.height (zoom * size.height)
    , Util.width (zoom * size.width)
    ]
        |> style
        |> List.singleton


screen : Html Msg
screen =
    div
        [ class [ Screen ]
        , MouseEvents.onMouseDown ScreenMouseDown
        ]
        []
