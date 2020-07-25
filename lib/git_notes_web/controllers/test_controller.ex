defmodule GitNotesWeb.TestController do
  use GitNotesWeb, :controller

  def get(conn, params) do
    # if JWT token is not present, set result to failure




    delay = params["sleep"]

    if delay do
      {amount, _} = Integer.parse(delay)
      :timer.sleep(amount)
    end

    result = params["result"]
    cond do
      result == "success" ->
        send_resp(conn, 200, "success")
      result == "failure" ->
        send_resp(conn, 400, "failure")
      true ->
        send_resp(conn, 200, "success")
    end
  end
end
