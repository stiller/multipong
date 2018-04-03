defmodule Pong.GameServer do
  @name :game_server
  @interval 33

  use GenServer

  alias Pong.Game

  def start_link(_args) do
    IO.puts "Starting the game erver with #{@interval} millisecond interval..."
    GenServer.start_link(__MODULE__, Game.new, name: @name)
  end

  def input player, input do
    GenServer.cast @name, {:input, player, input}
  end

  def output do
    GenServer.call @name, :output
  end

  # Callbacks

  def init(state) do
    {:ok, state}
  end

  def handle_info(:update, state) do
    new_game = Game.update(state, @interval / 1000.0)
    if new_game.playing do
      schedule_update()
    end
    MultipongWeb.Endpoint.broadcast!("game", "output", new_game)
    {:noreply, new_game}
  end

  def handle_cast({:input, player, input}, state) do
    new_game = Game.input(state, player, input)
    schedule_update()
    {:noreply, new_game}
  end

  def handle_call(:output, _from, state) do
    {:reply, state, state}
  end

  defp schedule_update do
    Process.send_after(self(), :update, @interval)
  end
end
