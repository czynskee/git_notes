defmodule GitNotesWeb.NotesView do
  use GitNotesWeb, :view


  defp decode_file(file) do
    file.topic_entries
    |> Enum.sort(&(&1.file_location <= &2.file_location))
    |> Enum.map(& &1.topic.heading <> (&1.content |> Base.decode64!(ignore: :whitespace)))
    |> Enum.reduce(fn entry, file_content ->
      file_content <> entry
    end)
  end

  def display_date(date) do
    diff = Date.diff(date, Date.utc_today())
    cond do
      diff == 0 ->
        "Today"
      diff == -1 ->
        "Yesterday"
      diff <= -2 && diff > -7 ->
        "Last #{Date.day_of_week(date) |> day_name()}"
      diff >= 2 && diff < 7 ->
        "#{Date.day_of_week(date) |> day_name()}"
      diff <= -7 ->
        "Last Week #{Date.day_of_week(date) |> day_name()}"
      diff >= 7 ->
        "Next Week #{Date.day_of_week(date) |> day_name()}"
      diff == 1 ->
        "Tomorrow"
      true ->
        date
    end
  end

  defp day_name(day_number) do
    cond do
      day_number == 1 -> "Monday"
      day_number == 2 -> "Tuesday"
      day_number == 3 -> "Wednesday"
      day_number == 4 -> "Thursday"
      day_number == 5 -> "Friday"
      day_number == 6 -> "Saturday"
      day_number == 7 -> "Sunday"
    end
  end
end
