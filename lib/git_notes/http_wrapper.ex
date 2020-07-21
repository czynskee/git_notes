defmodule HTTP.Adapter do
  @http_adapter Application.fetch_env!(:git_notes, :http_adapter)

  def get(url, headers \\ [], options \\ []) do
    url
    |> get_url(headers, options)
  end

  def post(url, body, headers \\ [], options \\ []) do
    url
    |> post_url(body, headers, options)
  end

  defp post_url(url, body, headers, options) do
    @http_adapter.post url, body, headers, options
  end

  defp get_url(url, headers, options) do
    @http_adapter.get url, headers, options
  end

  def request(request) do
    @http_adapter.request(request)
  end
end
