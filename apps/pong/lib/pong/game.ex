defmodule Pong.Game do

  @halfWidth 300
  @halfHeight 200
  defstruct playing: false, ball: Ball, player1: Player, player2: Player

  alias Pong.{Game, Player, Ball}

  def new do
    %Game{ playing: false,
           ball: %Ball{ x: 0, y: 0, vx: 200, vy: 200},
           player1: Player.new(20-@halfWidth),
           player2: Player.new(@halfWidth-20)
         }
  end

  def input game, player, input do
    case input do
      "space" -> %Game{ game | playing: !game.playing }
      "up" -> update(game, player, 1)
      "down" -> update(game, player, -1)
    end
  end

  defp update game, player, direction do
    p = Map.get(game, player) |> Map.put(:direction, direction)
    Map.put(game, player, p)
  end

  def update game, delta do
    score1 = if game.ball.x >  @halfWidth, do: 1, else: 0
    score2 = if game.ball.x < -@halfWidth, do: 1, else: 0
    newBall = if game.playing do
      updateBall(delta, game.ball, game.player1, game.player2)
    else
      game.ball
    end
    player1 = %{ game.player1 | score: game.player1.score + score1 }
    player2 = %{ game.player2 | score: game.player2.score + score2 }
    %Game{ game | player1: player1, player2: player2, ball: newBall }
  end

  defp updateBall delta, ball, paddle1, paddle2 do
    if !near(0, @halfWidth, ball.x) do
      %Ball{ ball | x: 0, y: 0 }
    else
      physicsUpdate(
        delta,
        %Ball{ ball | vx: stepV(ball.vx, within(paddle1, ball), within(paddle2, ball)),
                      vy: stepV(ball.vy, (ball.y < 7 - @halfHeight), (ball.y > @halfHeight - 7 ))
        }
      )
    end
  end

  defp stepV v, lowerCollision, upperCollision do
    cond do
      lowerCollision -> abs(v)
      upperCollision -> -abs(v)
      true -> v
    end
  end

  defp physicsUpdate delta, obj do
    %{ obj | x: obj.x + obj.vx * delta, y: obj.y + obj.vy * delta }
  end

  defp near k, c, n do
    n >= k-c && n <= k+c
  end

  defp within paddle, ball do
    near(paddle.x, 8, ball.x) && near(paddle.y, 20, ball.y)
  end
end
