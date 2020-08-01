defmodule GitNotes.Accounts.User do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :integer, autogenerate: false}

  schema "users" do
    field :login, :string
    field :installation_id, :integer
    field :refresh_token, :string
    field :refresh_token_expiration, :utc_datetime
    has_many :repos, GitNotes.GitRepos.GitRepo

    timestamps()
  end

  @doc false
  def changeset(user, attrs) do
    user
    |> cast(attrs, [:refresh_token, :installation_id, :refresh_token_expiration])
    |> validate_required([:installation_id])
  end

  def registration_changeset(user, attrs) do
    user
    |> cast(attrs, [:login, :refresh_token, :installation_id, :refresh_token_expiration, :id])
    |> validate_required([:installation_id, :login, :id])
    |> unique_constraint([:installation_id, :login, :id])
  end
end
