defmodule GitNotes.Notes.Topic do
  use Ecto.Schema
  import Ecto.Changeset

  schema "topics" do
    field :name, :string
    field :heading, :string
    belongs_to :user, GitNotes.Accounts.User, foreign_key: :user_id
    has_many :topic_entries, GitNotes.Notes.TopicEntry

    timestamps()
  end

  @doc false
  def changeset(topic, attrs) do
    topic
    |> cast(attrs, [:name, :heading, :user_id])
    |> unique_constraint([:name, :heading, :user_id])
    |> validate_required([:name, :heading, :user_id])
  end
end
