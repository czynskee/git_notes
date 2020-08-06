defmodule GitNotes.Repo.Migrations.CreateUsersTable do
  use Ecto.Migration

  def change do
    create table(:users) do
      add :installation_id, :integer, null: false
      add :login, :string, null: false
      add :refresh_token, :string
      add :refresh_token_expiration, :utc_datetime
      timestamps()
    end

    create unique_index(:users, [:id])
    create unique_index(:users, [:installation_id])
    create unique_index(:users, [:login])
  end
end
