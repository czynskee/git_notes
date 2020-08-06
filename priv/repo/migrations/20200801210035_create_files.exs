defmodule GitNotes.Repo.Migrations.CreateFiles do
  use Ecto.Migration

  def change do
    create table(:files) do
      add :name, :string
      add :content, :text
      add :file_name_date, :date
      add :git_repo_id, references(:repos, on_delete: :delete_all)

      timestamps()
    end

    create index(:files, [:git_repo_id])
    create unique_index(:files, [:git_repo_id, :name])
  end
end
