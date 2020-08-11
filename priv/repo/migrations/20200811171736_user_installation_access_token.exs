defmodule GitNotes.Repo.Migrations.UserInstallationAccessToken do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :installation_access_token, :string
      add :installation_access_token_expiration, :utc_datetime
    end
  end
end
