defmodule MultipongWeb.PageController do
  use MultipongWeb, :controller

  def index(conn, _params) do
    render conn, "index.html"
  end
end
