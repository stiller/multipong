defmodule MultipongWeb.PageController do
  use MultipongWeb, :controller

  def index(conn, _params) do
    render conn, "index.html"
  end

  def show(conn, %{"id" => player_id}) do
    conn
    |> assign(:player_id, player_id)
    |> assign(:auth_token, Phoenix.Token.sign(conn, "player auth", player_id))
    |> render("show.html")
  end
end
