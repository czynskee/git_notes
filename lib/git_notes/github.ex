defmodule GitNotes.Github do
  @api_url Application.fetch_env!(:git_notes, :github_api_url)
  @api_version Application.fetch_env!(:git_notes, :github_api_version)
  @http_adapter Application.fetch_env!(:git_notes, :http_adapter)

  alias HTTP.Adapter
  alias GitNotes.Token

  defstruct requests: [], after_requests: &Github.after_requests/1

  def get_access_token(installation_id) do
    %@http_adapter.Request{
      method: :post,
      url: @api_url <> "/installations/#{installation_id}/access_tokens"
    }
  end

  def make_request(%@http_adapter.Request{} = request) do
    request
      |> add_required_headers()
      |> Adapter.request()
  end

  def enqueue_request(requester, request) do
    response = make_request(request)
    send(requester, response)
  end

  def add_required_headers(%@http_adapter.Request{} = request) do
    {:ok, token, _} = Token.get_token()

    headers = [
      Authorization: "Bearer #{token}",
      Accept: @api_version
    ]

    request
      |> Map.put(:headers, headers)
  end

  def after_requests(responses) do
    responses
  end

  # def make_request()
  # # def make_requests(requests) when is_list(requests) do

  # # end

  # # def make_request(Github = request) do
  # #   url = @api_version |> add_params(request.params)

  # #   headers = [
  # #     {"Authorization", "Bearer #{Token.get_token()}"},
  # #     {"Accept", @api_version}
  # #   ]

  # #   options = []

  # #   args = [url, headers, options]

  # #   apply(HTTP.Adapter, request.method, args)
  # end
end
