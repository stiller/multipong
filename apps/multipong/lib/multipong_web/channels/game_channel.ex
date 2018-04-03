defmodule MultipongWeb.GameChannel do
  use MultipongWeb, :channel
  alias Pong.GameServer

  require Logger

  def join("game", _params, socket) do
    case GameServer.output do
      output when is_map(output) ->
        send(self(), {:after_join, output})
        {:ok, socket}
      _ ->
        {:error, %{reason: "Game does not exist"}}
    end
  end

  def handle_info({:after_join, output}, socket) do
    push(socket, "output", output)
    {:noreply, socket}
  end

  defp is_game?(%Pong.Game{}), do: true
  defp is_game?(_), do: false
end
