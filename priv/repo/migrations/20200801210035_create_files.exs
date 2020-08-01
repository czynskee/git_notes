defmodule GitNotes.Repo.Migrations.CreateFiles do
  use Ecto.Migration

  def change do
    create table(:files) do
      add :file_name, :string
      add :content, :text
      add :notes_repo_id, references(:notes_repos, on_delete: :delete_all)

      timestamps()
    end

    create index(:files, [:notes_repo_id])
  end
end
