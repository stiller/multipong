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

  def output output do
    MultipongWeb.Endpoint.broadcast!("game", "output", output)
  end

  def handle_info({:after_join, output}, socket) do
    push(socket, "output", output)
    {:noreply, socket}
  end

  def handle_in("input", input, socket) do
    GameServer.input(current_player(socket), input)
    {:noreply, socket}
  end

  def handle_in("output", output, socket) do
    Logger.info "output: #{output}"
    {:noreply, socket}
  end

  defp current_player(socket) do
    String.to_atom(socket.assigns.current_player)
  end
end
