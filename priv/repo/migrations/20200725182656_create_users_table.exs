defmodule GitNotes.Repo.Migrations.CreateUsersTable do
  use Ecto.Migration

  def change do
    create table(:users) do
      add :installation_id, :integer, null: false
      add :username, :string, null: false
      add :refresh_token, :string
      add :refresh_token_expiration, :utc_datetime

      timestamps()
    end
  end
end
