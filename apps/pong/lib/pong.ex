defmodule Pong do
  use Application

  def start(_type, _args) do
    children = [Pong.GameServer]

    opts = [strategy: :one_for_one, name: Pong.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
