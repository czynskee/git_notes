defmodule GitNotesWeb.NotesView do
  use GitNotesWeb, :view


  def decode_file(file) do
    file.topic_entries
    |> Enum.sort(&(&1.file_location <= &2.file_location))
    |> Enum.map(& &1.topic.heading <> (&1.content |> Base.decode64!(ignore: :whitespace)))
    |> Enum.reduce(fn entry, file_content ->
      file_content <> entry
    end)

  end

end
