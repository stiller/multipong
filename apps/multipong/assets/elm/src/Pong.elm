module Pong exposing (..)

import Html exposing (Html, button, div, text)
import Html.Events exposing (onClick)
import Phoenix.Socket exposing (Socket)
import Phoenix.Channel exposing (Channel)
import Phoenix.Push

type alias Model =
  { phxSocket : Phoenix.Socket.Socket Msg
  , counter: Int
  }

init : Flags -> ( Model, Cmd Msg )
init flags =
  let
      socketUrl = flags.wsUrl ++ "?token=" ++ flags.authToken
      model =
        { phxSocket = Phoenix.Socket.init socketUrl
        , counter = 0 }
  in
  ( model, Cmd.none )

type alias Flags =
  { authToken : String
  , wsUrl : String
  }

main =
  Html.programWithFlags
      { init = init
      , view = view
      , update = update
      , subscriptions = (\_ -> Sub.none )
      }

-- UPDATE

type Msg
  = Increment
  | Decrement
  | PhoenixMsg (Phoenix.Socket.Msg Msg)

update msg model =
  case msg of
    Increment ->
      ( { model | counter = model.counter + 1 }, Cmd.none)

    Decrement ->
      ( { model | counter = model.counter - 1 }, Cmd.none)

    PhoenixMsg msg ->
      let
        ( phxSocket, phxCmd ) = Phoenix.Socket.update msg model.phxSocket
      in
        ( { model | phxSocket = phxSocket }
        , Cmd.map PhoenixMsg phxCmd
        )

-- VIEW

view model =
  div []
  [ button [ onClick Decrement ] [ text
  "-" ]
  , div [] [ text (toString model.counter) ]
  , button [ onClick Increment ]
  [ text "+" ]
  ]

-- SUBSCRIPTIONS

subscriptions : Model -> Sub Msg
subscriptions model =
  Phoenix.Socket.listen model.phxSocket PhoenixMsg
