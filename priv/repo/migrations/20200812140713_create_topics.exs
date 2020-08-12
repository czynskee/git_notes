defmodule GitNotes.Repo.Migrations.CreateTopics do
  use Ecto.Migration

  def change do
    create table(:topics) do
      add :name, :string
      add :file_id, references(:files, on_delete: :delete_all)

      timestamps()
    end

    create index(:topics, [:name])
    create unique_index(:topics, [:name, :file_id])

  end
end
