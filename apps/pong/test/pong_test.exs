defmodule PongTest do
  use ExUnit.Case
  doctest Pong

  test "greets the world" do
    assert Pong.hello() == :world
  end
end
