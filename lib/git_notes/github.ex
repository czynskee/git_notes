defmodule GitNotes.Github do
  @github_api Application.fetch_env!(:git_notes, :github_api)

  def get_access_token(code) do
    @github_api.get_access_token(code)
  end

  def get_installation_access_token(installation_id) do
    @github_api.get_installation_access_token(installation_id)
  end

  def get_user(token) do
    @github_api.get_user(token)
    |> elem(1)
  end

  @doc """
  This function will be called when a new user has installed the app. It will handle getting an
  access token for that user, pulling some necessary information from their github account, and
  loading it into the database. This will be an atomic operation and will return {:error, reason} to the caller
  if any part of it goes wrong. Otherwise it will return {:ok, %User}

  This function is meant to be called from the user_controller when a user gets redirected to our
  site after installing the application. It's also meant to be catch up in case that doesn't work
  (e.g. our site is down but someone registers, we would not get the request when they get redirected
  and so would never know about them. Another potential is someone registers for the app but for some
  reason the redirect doesn't happen. This way we'll be able to handle those cases one way or another)
  """
  def new_installation(installation_id, oauth_code \\ nil) do

  end

end
