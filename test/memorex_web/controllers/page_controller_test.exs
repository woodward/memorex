defmodule MemorexWeb.PageControllerTest do
  @moduledoc false
  use MemorexWeb.ConnCase

  test "GET /", %{conn: conn} do
    conn = get(conn, "/page")
    assert html_response(conn, 200) =~ "Welcome to Phoenix!"
  end
end
