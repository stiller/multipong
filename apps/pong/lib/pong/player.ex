defmodule Pong.Player do
  defstruct x: 0.0, y: 0.0, vx: 0.0, vy: 0.0, score: 0, direction: 0

  alias Pong.Player

  def new x do
    %Player{x: x}
  end
end
