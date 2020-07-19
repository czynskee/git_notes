defmodule GitNotes.Github do
  @api_url Application.fetch_env!(:git_notes, :github_api_url)
  @api_version Application.fetch_env!(:git_notes, :github_api_version)

  alias HTTP.Adapter
  alias GitNotes.Token


  def add_param(url, param_key, param_val) do
    url <> "&#{param_key}=#{param_val}"
  end

  def add_params(url, nil) do
    url
  end

  def add_params(url, params) do
    url = url <> "?"
    Enum.reduce(params, url, fn ({key, value}, url) -> add_param(url, key, value) end)
  end

  def add_params(url, param_key, param_val) do
    add_params(url, [{param_key, param_val}])
  end
  # def make_requests(requests) when is_list(requests) do

  # end

  # def make_request(Github = request) do
  #   url = @api_version |> add_params(request.params)

  #   headers = [
  #     {"Authorization", "Bearer #{Token.get_token()}"},
  #     {"Accept", @api_version}
  #   ]

  #   options = []

  #   args = [url, headers, options]

  #   apply(HTTP.Adapter, request.method, args)
  # end


end
