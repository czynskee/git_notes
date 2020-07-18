defmodule GitNotes.Repo do
  use Ecto.Repo,
    otp_app: :git_notes,
    adapter: Ecto.Adapters.Postgres
end
