defmodule GitNotes.Accounts.User do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :integer, autogenerate: false}

  schema "users" do
    field :login, :string
    field :installation_id, :integer
    field :access_token, :string
    field :access_token_expiration, :utc_datetime
    field :refresh_token, :string
    field :refresh_token_expiration, :utc_datetime
    field :installation_access_token, :string
    field :installation_access_token_expiration, :utc_datetime
    has_many :repos, GitNotes.GitRepos.GitRepo
    has_many :topics, GitNotes.Notes.Topic
    belongs_to :notes_repo, GitNotes.GitRepos.GitRepo, foreign_key: :notes_repo_id


    timestamps()
  end

  @doc false
  def changeset(user, attrs) do
    user
    |> cast(attrs, [:notes_repo_id])
    |> foreign_key_constraint(:notes_repo_id)
  end

  def registration_changeset(user, attrs) do
    user
    |> cast(attrs, [:login, :installation_id, :id])
    |> validate_required([:installation_id, :login, :id])
    |> unique_constraint([:installation_id])
    |> unique_constraint([:login])
    |> unique_constraint([:id], name: :users_pkey)
  end

  def github_credentials_changeset(user, attrs) do
    user
    |> cast(attrs, [:access_token, :refresh_token])
    |> put_change(:access_token_expiration, convert_exp_to_date(attrs["expires_in"]))
    |> put_change(:refresh_token_expiration, convert_exp_to_date(attrs["refresh_token_expires_in"]))
  end

  def installation_access_token_changeset(user, attrs) do
    user
    |> cast(attrs, [])
    |> put_change(:installation_access_token, attrs["token"])
    |> put_change(:installation_access_token_expiration, convert_exp_to_date(attrs["expires_at"]))
  end

  defp convert_exp_to_date(expiration) when is_binary(expiration) do
    case DateTime.from_iso8601(expiration) do
      {:error, _} ->
        DateTime.now("Etc/UTC")
        |> elem(1)
        |> DateTime.add(Integer.parse(expiration)
        |> elem(0))
        |> DateTime.truncate(:second)
      {:ok, date, _tz} ->
        date
    end
  end

end
