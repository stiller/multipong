defmodule MultipongWeb.PageView do
  use MultipongWeb, :view

  def ws_url do
    System.get_env("WS_URL") ||
      Application.get_env(:multipong, MultipongWeb.Endpoint)[:ws_url]
  end
end
