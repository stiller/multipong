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
    schedule_update()
    {:ok, state}
  end

  def handle_info(:update, state) do
    schedule_update()
    {:noreply, Game.update(state, @interval / 1000.0)}
  end

  def handle_cast({:input, player, input}, state) do
    {:noreply, Game.input(state, player, input)}
  end

  def handle_call(:output, _from, state) do
    {:reply, state, state}
  end

  defp schedule_update do
    Process.send_after(self(), :update, @interval)
  end
end
