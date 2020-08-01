defmodule GitNotes.Accounts do
  @moduledoc """
  The Accounts context.
  """

  alias GitNotes.Accounts.User
  alias GitNotes.Repo

  def register_user(attrs \\ %{}) do
    %User{}
    |> User.registration_changeset(attrs)
    |> Repo.insert()
  end

  def get_user_by(params) do
    Repo.get_by(User, params)
  end

  def get_user(id) do
    Repo.get(User, id)
  end

  def list_users() do
    Repo.all(User)
  end

  def delete_user(%User{} = user) do
    Repo.delete(user)
  end

  def update_user(%User{} = user, attrs) do
    user
    |> User.changeset(attrs)
    |> Repo.update()
  end
end
