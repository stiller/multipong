module Pong exposing (..)

-- See this document for more information on making Pong:
-- http://elm-lang.org/blog/Pong.elm

import Color exposing (..)
import Collage exposing (..)
import Element exposing (..)
import Text
import Char
import Time exposing (..)
import Window
import Html exposing (..)
import Json.Decode as Decode exposing (Decoder, field)
import Json.Encode as Encode
import Keyboard exposing (..)
import Set exposing (Set)
import Task
import AnimationFrame
import Phoenix.Socket exposing (Socket)
import Phoenix.Channel exposing (Channel)
import Phoenix.Push


type alias Flags =
    { authToken : String
    , wsUrl : String
    }


init : Flags -> ( Game, Cmd Msg )
init flags =
    let
        socketUrl =
            flags.wsUrl ++ "?token=" ++ flags.authToken

        socket =
            Phoenix.Socket.init socketUrl
                |> Phoenix.Socket.on "output" "game" ReceiveGameSummary
                |> Phoenix.Socket.withDebug

        channel =
            Phoenix.Channel.init "game"

        ( newSocket, phxCmd ) =
            Phoenix.Socket.join channel socket
    in
        ( initialGame socket, Cmd.map PhoenixMsg phxCmd )


main =
    Html.programWithFlags
        { init = init
        , view = view
        , update = update
        , subscriptions = subscriptions
        }



-- UPDATE


type Msg
    = KeyDown KeyCode
    | NoOp
    | ReceiveGameSummary Decode.Value
    | PhoenixMsg (Phoenix.Socket.Msg Msg)


update msg game =
    case msg of
        KeyDown key ->
            let
                input =
                    if key == Char.toCode ' ' then
                        "space"
                    else if key == 38 then
                        "up"
                    else if key == 40 then
                        "down"
                    else
                        "noop"

                pushMsg =
                    Phoenix.Push.init "input" "game"
                        |> Phoenix.Push.withPayload (Encode.string input)

                ( newSocket, phxCmd ) =
                    Phoenix.Socket.push pushMsg game.phxSocket

                cmd =
                    if input /= "noop" then
                        Cmd.map PhoenixMsg phxCmd
                    else
                        Cmd.none
            in
                ( { game | keysDown = Set.insert key game.keysDown }, cmd )

        NoOp ->
            ( game, Cmd.none )

        ReceiveGameSummary payload ->
            let
                ball =
                    case decodeBall payload of
                        Ok ball ->
                            ball

                        Err _ ->
                            game.ball

                player1 =
                    case (decodePlayer payload "player1") of
                        Ok player ->
                            player

                        Err _ ->
                            initialPlayer1

                player2 =
                    case (decodePlayer payload "player2") of
                        Ok player ->
                            player

                        Err _ ->
                            initialPlayer1

                newGame =
                    { game | ball = ball, player1 = player1, player2 = player2 }
            in
                ( newGame, Cmd.none )

        PhoenixMsg msg ->
            let
                ( phxSocket, phxCmd ) =
                    Phoenix.Socket.update msg game.phxSocket
            in
                ( { game | phxSocket = phxSocket }
                , Cmd.map PhoenixMsg phxCmd
                )



-- DECODERS


decodeBall payload =
    Decode.decodeValue (Decode.at [ "ball" ] ballDecoder) payload


decodePlayer payload player =
    Decode.decodeValue (Decode.at [ player ] playerDecoder) payload


playerDecoder =
    Decode.map5 Player
        (field "x" Decode.float)
        (field "y" Decode.float)
        (field "vx" Decode.float)
        (field "vy" Decode.float)
        (field "score" Decode.int)


ballDecoder =
    Decode.map4 Ball
        (field "x" Decode.float)
        (field "y" Decode.float)
        (field "vx" Decode.float)
        (field "vy" Decode.float)



-- SUBSCRIPTIONS


subscriptions model =
    Sub.batch
        [ Keyboard.downs KeyDown
        , Phoenix.Socket.listen model.phxSocket PhoenixMsg
        ]



-- MODEL


( gameWidth, gameHeight ) =
    ( 600, 400 )
( halfWidth, halfHeight ) =
    ( gameWidth / 2, gameHeight / 2 )


type alias Ball =
    { x : Float
    , y : Float
    , vx : Float
    , vy : Float
    }


type alias Player =
    { x : Float
    , y : Float
    , vx : Float
    , vy : Float
    , score : Int
    }


type alias Game =
    { keysDown : Set KeyCode
    , ball : Ball
    , player1 : Player
    , player2 : Player
    , phxSocket : Phoenix.Socket.Socket Msg
    }


player : Float -> Player
player initialX =
    { x = initialX
    , y = 0
    , vx = 0
    , vy = 0
    , score = 0
    }


initialBall =
    { x = 0, y = 0, vx = 200, vy = 200 }


initialPlayer1 =
    player (20 - halfWidth)


initialPlayer2 =
    player (halfWidth - 20)


initialGame socket =
    { keysDown = Set.empty
    , ball = initialBall
    , player1 = initialPlayer1
    , player2 = initialPlayer2
    , phxSocket = socket
    }



-- VIEW


view : Game -> Html Msg
view { ball, player1, player2 } =
    let
        scores : Element
        scores =
            txt (Text.height 50) (toString player1.score ++ "  " ++ toString player2.score)
    in
        toHtml <|
            container gameWidth gameHeight middle <|
                collage gameWidth
                    gameHeight
                    [ rect gameWidth gameHeight
                        |> filled pongGreen
                    , verticalLine gameHeight
                        |> traced (dashed red)
                    , oval 15 15
                        |> make ball
                    , rect 10 40
                        |> make player1
                    , rect 10 40
                        |> make player2
                    , toForm scores
                        |> move ( 0, gameHeight / 2 - 40 )
                    ]


verticalLine height =
    path [ ( 0, height ), ( 0, -height ) ]


pongGreen =
    rgb 60 100 60


textGreen =
    rgb 160 200 160


txt f =
    Text.fromString >> Text.color textGreen >> Text.monospace >> f >> leftAligned


pauseMessage =
    "SPACE to start and pause, R to reset, WS and &uarr;&darr; to move"


make obj shape =
    shape
        |> filled white
        |> move ( obj.x, obj.y )
