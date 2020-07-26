defmodule GitNotes.TestHelpers do
  alias GitNotes.Accounts

  def user_fixture(attrs \\ %{}) do
    attrs
    |> Enum.into(%{
      installation_id: 123,
      id: 123456,
      refresh_token: "456",
      username: "czynskee",
      refresh_token_expiration: DateTime.now("Etc/UTC") |> elem(1) |> DateTime.add(60 * 60 * 24 * 30 * 3, :second)
    })
    |> Accounts.register_user()
    |> elem(1)
  end

end
