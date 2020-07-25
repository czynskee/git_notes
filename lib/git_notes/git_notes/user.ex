defmodule GitNotes.GitNotes.User do
  use Ecto.Schema
  import Ecto.Changeset

  schema "users" do
    field :login, :string

    timestamps()
  end

  @doc false
  def changeset(user, attrs) do
    user
    |> cast(attrs, [:login])
    |> validate_required([:login])
  end
end
