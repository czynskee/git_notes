defmodule GitNotesWeb.Auth do
  use GitNotesWeb, :controller

  @oauth_url Application.fetch_env!(:git_notes, :oauth_url)
  @client_id Application.fetch_env!(:git_notes, :client_id)

  def put_oauth_url(conn) do
    state = get_state()
    conn
    |> assign(:oauth_url, oauth_url(state))
    |> put_session(:state, state)
  end

  defp oauth_url(state) do
    "#{@oauth_url}?client_id=#{@client_id}&state=#{state}"
  end

  defp get_state() do
    :crypto.strong_rand_bytes(64) |> Base.url_encode64()
  end

end
