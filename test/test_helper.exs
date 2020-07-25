ExUnit.start()
Ecto.Adapters.SQL.Sandbox.mode(GitNotes.Repo, :manual)

Mox.defmock(GitNotes.GithubAPI.Mock, for: GitNotes.GithubAPI)
