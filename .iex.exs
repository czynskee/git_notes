alias GitNotes.Accounts.User
alias GitNotes.GitRepos.GitRepo
alias GitNotes.{Accounts, GitRepos, Notes, TestHelpers, Github}

import Ecto.Query


user = Accounts.list_users() |> Enum.at(0)
notes_repo = GitRepos.get_repo(user.notes_repo_id)
