defmodule MemorexWeb.PageController do
  use MemorexWeb, :controller

  def index(conn, _params) do
    render(conn, "index.html")
  end
end
