module Pong exposing(..)
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
  , wsUrl : String }

init : Flags -> ( Game, Cmd Msg )
init flags =
  let
    socketUrl = flags.wsUrl ++ "?token=" ++ flags.authToken
    socket = Phoenix.Socket.init socketUrl
      |> Phoenix.Socket.on "output" "game" ReceiveGameSummary
      |> Phoenix.Socket.withDebug
    channel = Phoenix.Channel.init "game"
    ( newSocket, phxCmd ) = Phoenix.Socket.join channel socket
  in
  (initialGame socket, Cmd.map PhoenixMsg phxCmd)

main = Html.programWithFlags
            { init = init
            , view = view
            , update = update
            , subscriptions = subscriptions
            }

-- KeyDown/KeyUp/keysDown technique taken from this answer :
--     http://stackoverflow.com/a/39127092/509928
--
-- to this question :
--     http://stackoverflow.com/questions/39125989/keyboard-combinations-in-elm-0-17-and-later
--

type Msg = KeyDown KeyCode
         | KeyUp KeyCode
         | NoOp
         | ReceiveGameSummary Decode.Value
         | PhoenixMsg (Phoenix.Socket.Msg Msg)

getInput : Game -> Float -> Input
getInput game delta
         = { space = Set.member (Char.toCode ' ') (game.keysDown)
           , reset = Set.member (Char.toCode 'R') (game.keysDown)
           , pause = Set.member (Char.toCode 'P') (game.keysDown)
           , dir = if Set.member 38 (game.keysDown) then 1 -- down arrow
                   else if Set.member 40 (game.keysDown) then -1 -- up arrow
                   else 0
           , delta = inSeconds delta
           }

update msg game =
  case msg of
    KeyDown key ->
      let
        input = if key == Char.toCode ' ' then
            "space"
          else if key == 38 then
            "up"
          else if key == 40 then
            "down"
          else
            "noop"

        pushMsg = Phoenix.Push.init "input" "game"
          |> Phoenix.Push.withPayload (Encode.string input)
        ( newSocket, phxCmd ) = Phoenix.Socket.push pushMsg game.phxSocket

        cmd = if input /= "noop" then
            Cmd.map PhoenixMsg phxCmd
          else
            Cmd.none
      in
        ({ game | keysDown = Set.insert key game.keysDown }, cmd)
    KeyUp key ->
      ({ game | keysDown = Set.remove key game.keysDown }, Cmd.none)
    NoOp ->
      (game, Cmd.none)
    ReceiveGameSummary payload ->
      let
        ball = case decodeBall payload of
          Ok  ball -> ball
          Err _ -> game.ball

        player1 = case (decodePlayer payload "player1") of
          Ok  player -> player
          Err _ -> initialPlayer1

        player2 = case (decodePlayer payload "player2") of
          Ok  player -> player
          Err _ -> initialPlayer1

        newGame = { game | ball = ball, player1 = player1, player2 = player2 }
      in
        ( newGame, Cmd.none )
    PhoenixMsg msg ->
      let
        ( phxSocket, phxCmd ) = Phoenix.Socket.update msg game.phxSocket
      in
        ( { game | phxSocket = phxSocket }
        , Cmd.map PhoenixMsg phxCmd
        )

decodeBall payload =
  Decode.decodeValue (Decode.at ["ball"] ballDecoder) payload

decodePlayer payload player =
  Decode.decodeValue (Decode.at [player] playerDecoder) payload

playerDecoder =
  Decode.map5 Player
    (field "x"  Decode.float)
    (field "y"  Decode.float)
    (field "vx" Decode.float)
    (field "vy" Decode.float)
    (field "score" Decode.int)

ballDecoder =
  Decode.map4 Ball
    (field "x"  Decode.float)
    (field "y"  Decode.float)
    (field "vx" Decode.float)
    (field "vy" Decode.float)

subscriptions model =
    Sub.batch
        [ Keyboard.downs KeyDown
        , Keyboard.ups KeyUp
        , Phoenix.Socket.listen model.phxSocket PhoenixMsg
        ]

-- MODEL

(gameWidth, gameHeight) = (600, 400)
(halfWidth, halfHeight) = (gameWidth / 2, gameHeight / 2)

type State = Play | Pause

type alias Ball = {
    x: Float,
    y: Float,
    vx: Float,
    vy: Float
}

type alias Player = {
    x: Float,
    y: Float,
    vx: Float,
    vy: Float,
    score: Int
}

type alias Game =
  { keysDown : Set KeyCode,
    windowDimensions : (Int, Int),
    state: State,
    ball: Ball,
    player1: Player,
    player2: Player,
    phxSocket : Phoenix.Socket.Socket Msg
  }

player : Float -> Player
player initialX =
  { x = initialX
  , y = 0
  , vx = 0
  , vy = 0
  , score = 0
  }

initialBall = { x = 0, y = 0, vx = 200, vy = 200 }

initialPlayer1 = player (20 - halfWidth)

initialPlayer2 = player (halfWidth - 20)

initialGame socket =
  { keysDown = Set.empty
  , windowDimensions = (600,400)
  , state   = Pause
  , ball    = initialBall
  , player1 = initialPlayer1
  , player2 = initialPlayer2
  , phxSocket = socket
  }

type alias Input = {
    space : Bool,
    reset : Bool,
    pause : Bool,
    dir : Int,
    delta : Time
}

-- UPDATE

updateGame : Input -> Game -> Game
updateGame {space, reset, pause, dir, delta} ({state, ball, player1, player2} as game) =
  let score1 = if ball.x >  halfWidth then 1 else 0
      score2 = if ball.x < -halfWidth then 1 else 0

      newState =
        if  space then Play
        else if (pause) then Pause
        else if (score1 /= score2) then Pause
        else state

      newBall =
        if state == Pause
            then ball
            else updateBall delta ball player1 player2

  in
    if reset
    then { game | state   = Pause
                , ball    = initialBall
                , player1 = initialPlayer1
                , player2 = initialPlayer2
        }

    else { game | state   = newState
                , ball    = newBall
                , player1 = updatePlayer delta dir score1 player1
                , player2 = updateComputer newBall score2 player2
        }

updateBall : Time -> Ball -> Player -> Player -> Ball
updateBall t ({x, y, vx, vy} as ball) p1 p2 =
  if not (ball.x |> near 0 halfWidth)
    then { ball | x = 0, y = 0 }
    else physicsUpdate t
            { ball |
                vx = stepV vx (within ball p1) (within ball p2),
                vy = stepV vy (y < 7-halfHeight) (y > halfHeight-7)
            }


updatePlayer : Time -> Int -> Int -> Player -> Player
updatePlayer t dir points player =
  let player1 = physicsUpdate  t { player | vy = toFloat dir * 200 }
  in
      { player1 |
          y = clamp (22 - halfHeight) (halfHeight - 22) player1.y,
          score = player.score + points
      }

updateComputer : Ball -> Int -> Player -> Player
updateComputer ball points player =
    { player |
        y = clamp (22 - halfHeight) (halfHeight - 22) ball.y,
        score = player.score + points
    }

physicsUpdate t ({x, y, vx, vy} as obj) =
  { obj |
      x = x + vx * t,
      y = y + vy * t
  }

near : Float -> Float -> Float -> Bool
near k c n =
    n >= k-c && n <= k+c

within ball paddle =
    near paddle.x 8 ball.x && near paddle.y 20 ball.y


stepV v lowerCollision upperCollision =
  if lowerCollision then abs v
  else if upperCollision then 0 - abs v
  else v

-- VIEW

view : Game -> Html Msg
view {windowDimensions, state, ball, player1, player2} =
  let scores : Element
      scores = txt (Text.height 50) (toString player1.score ++ "  " ++ toString player2.score)
      (w,h) = windowDimensions
  in
      toHtml <|
      container w h middle <|
      collage gameWidth gameHeight
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
            |> move (0, gameHeight/2 - 40)
        , toForm (statusMessage state)
            |> move (0, 40 - gameHeight/2)
        ]

statusMessage state =
    case state of
        Play    -> txt identity ""
        Pause   -> txt identity pauseMessage

verticalLine height =
     path [(0, height), (0, -height)]

pongGreen = rgb 60 100 60
textGreen = rgb 160 200 160
txt f = Text.fromString >> Text.color textGreen >> Text.monospace >> f >> leftAligned
pauseMessage = "SPACE to start, P to pause, R to reset, WS and &uarr;&darr; to move"

make obj shape =
    shape
      |> filled white
      |> move (obj.x,obj.y)

