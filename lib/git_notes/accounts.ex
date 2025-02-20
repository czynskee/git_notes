defmodule GitNotes.Accounts do
  @moduledoc """
  The Accounts context.
  """

  alias GitNotes.Accounts.User
  alias GitNotes.Repo

  def register_user(attrs \\ %{}) do
    %User{}
    |> User.registration_changeset(attrs)
    |> Repo.insert!()
  end

  def change_user(%User{} = user, attrs \\ %{}) do
    User.changeset(user, attrs)
  end

  def get_user_by(params) do
    Repo.get_by(User, params)
  end

  def get_user(id) when is_integer(id) do
    Repo.get(User, id)
  end

  def get_user(%User{} = user) do
    get_user(user.id)
  end

  def get_user_and_notes_repo(repo_id) do
    Repo.get_by(User, [notes_repo_id: repo_id])
    |> Repo.preload(:notes_repo)
  end

  def list_users() do
    Repo.all(User)
  end

  def delete_user(%User{} = user) do
    Repo.delete!(user)
  end

  def update_user(%User{} = user, attrs) do
    user
    |> User.changeset(attrs)
    |> Repo.update!()
  end

  def update_github_credentials(%User{} = user, credentials) do
    user
    |> User.github_credentials_changeset(credentials)
    |> Repo.update!()
  end

  def update_installation_access_token(%User{} = user, credentials) do
    user
    |> User.installation_access_token_changeset(credentials)
    |> Repo.update()
  end
end
