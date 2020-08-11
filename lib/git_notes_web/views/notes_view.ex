defmodule GitNotesWeb.NotesView do
  use GitNotesWeb, :view


  def decode_file(file) do
    file.content |> Base.decode64(ignore: :whitespace) |> elem(1)
  end
end
