# GitNotes

This is a Github App that can be used to take notes that will be synced to a git repo of your choosing. All notes saved in the app are pushed to the git repo and all notes that are pushed to the git repo will be available in the app. The app will ask for access to your git repos but it will only push to the repo that you select as your notes repo. For all other repos, it will pull your commit history. The app will display all of your commits by day alongside your notes for that day.

Each file in the git repo must be named by date in this format: `YYYY-MM-DD.md`.

To run this app you'll need to create a Git app [here](https://github.com/settings/apps). These fields will need to be set in the github app config:

- User authorization callback URL: `<your-url>/sessions/new`
- Webhook:
- [x] Active
- Webhook URL: a public facing url that github can access. While in development I recommend using [ngrok](). The url should be appended with the path `/webhooks` (e.g.: `https://3lk24u89fj234df.ngrok.io/webhooks`).

It is recommended to setup a webhook secret and to enable SSL verification. 

Also, in the github app you will need to set up a public facing url that github can access. While in development, I recommend using [ngrok](https://ngrok.com/).

Under Permissions & events you'll need to set these repository permissions:
- Administration: Read-only
- Contents: Read & Write

You'll also need to subscribe to these events:
- [x] Member
- [x] Meta
- [x] Push
- [x] Repository

You will also need to set up some environmental variables. I do this by saving the following (with the appropriate values filled in) to a `.env` file and making sure that your build system has access to them. **Ensure that you add the .env file to your .gitignore file to prevent it from being pushed to github!**In a local development environment on Linux you can simply key in `source .env` in the terminal that you start the server from. The process may vary depending on how and where you build the app from.

- export GITHUB_APP_ID=*your github app id*
- export GITHUB_CLIENT_ID=*your github client id*
- export GITHUB_CLIENT_SECRET=*your github client secret*
- export GITHUB_WEBHOOK_SECRET=*your github webhook secret*
- export LIVE_VIEW_SIGNING_SALT=*your Phoenix LiveView signing salt, can be generated with* `mix phx.gen.secret 32`
- export PRIVATE_KEY="-----BEGIN RSA PRIVATE KEY-----
*your private SSH key with a corresponding public key held by github - used for JWTs*
-----END RSA PRIVATE KEY-----"

To start your Phoenix server:

  * Install dependencies with `mix deps.get`
  * Create and migrate your database with `mix ecto.setup`
  * Install Node.js dependencies with `npm install` inside the `assets` directory
  * Start Phoenix endpoint with `mix phx.server`

Now you can visit [`localhost:4000`](http://localhost:4000) from your browser.

Ready to run in production? Please [check our deployment guides](https://hexdocs.pm/phoenix/deployment.html).
