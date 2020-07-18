defmodule GitNotes.Github do
  @api_url Application.fetch_env!(:git_notes, :github_api_url)
  @api_version Application.fetch_env!(:git_notes, :github_api_version)

  def add_param(url, param_key, param_val) do
    url <> "&#{param_key}=#{param_val}"
  end

  def add_params(url, params) do
    url = url <> "?"
    Enum.reduce(params, url, fn ({key, value}, url) -> add_param(url, key, value) end)
  end



end
