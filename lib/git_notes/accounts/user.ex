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
    belongs_to :notes_repo, GitNotes.GitRepos.GitRepo, foreign_key: :notes_repo_id


    timestamps()
  end

  @doc false
  def changeset(user, attrs) do
    user
    |> cast(attrs, [:id, :refresh_token, :refresh_token_expiration, :notes_repo_id])
    |> foreign_key_constraint(:notes_repo_id)
    |> validate_required([:id])
  end

  def registration_changeset(user, attrs) do
    user
    |> cast(attrs, [:login, :refresh_token, :installation_id, :refresh_token_expiration, :id])
    |> validate_required([:installation_id, :login, :id])
    |> unique_constraint([:installation_id])
    |> unique_constraint([:login])
    |> unique_constraint([:id], name: :users_pkey)
  end
end
