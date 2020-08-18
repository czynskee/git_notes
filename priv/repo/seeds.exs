# Script for populating the database. You can run it as:
#
#     mix run priv/repo/seeds.exs
#
# Inside the script, you can read and write to any of your
# repositories directly:
#
#     GitNotes.Repo.insert!(%GitNotes.SomeSchema{})
#
# We recommend using the bang functions (`insert!`, `update!`
# and so on) as they will fail if something goes wrong.


%GitNotes.Accounts.User{
  __meta__: #Ecto.Schema.Metadata<:loaded, "users">,
  access_token: "5d632d83dffc05f33a90b07314b67413350e48eb",
  access_token_expiration: ~U[2020-08-15 06:06:43Z],
  id: 8753265,
  inserted_at: ~N[2020-08-14 22:04:39],
  installation_access_token: "v1.dfbbe00681fa321a1e35d640ed5051507335cbd1",
  installation_access_token_expiration: ~U[2020-08-14 23:04:39Z],
  installation_id: 11255150,
  login: "czynskee",
  notes_repo: #Ecto.Association.NotLoaded<association :notes_repo is not loaded>,
  notes_repo_id: 278936393,
  refresh_token: "r1.9c7003462e70c24c5fab875b5a1e1923a67d9d2374ff5ff08f8efdfb35397075c060873cb3e2208d",
  refresh_token_expiration: ~U[2021-02-14 22:06:42Z],
  repos: #Ecto.Association.NotLoaded<association :repos is not loaded>,
  topics: #Ecto.Association.NotLoaded<association :topics is not loaded>,
  updated_at: ~N[2020-08-14 22:07:10]
} |> GitNotes.Repo.insert!()
