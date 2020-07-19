defmodule GitNotesWeb.TestController do
  use GitNotesWeb, :controller

  def get(conn, params) do
    IO.inspect params
    send_resp(conn, 200, "success")
  end
end
