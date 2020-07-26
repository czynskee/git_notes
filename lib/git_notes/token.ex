defmodule GitNotes.Token do
  use Joken.Config
  use Agent

  def start(_opts \\ []) do
    start_link()
  end

  def start_link(_opts \\ []) do
    Agent.start_link(fn -> %{} end, name: __MODULE__)
  end

  def stop() do
    Agent.stop(__MODULE__)
  end

  def get_key(key) do
    Agent.get(__MODULE__, &(&1[key]))
  end

  def set_key(key, value) do
    Agent.update(__MODULE__, &(Map.put(&1, key, value)))
  end

  @iss Application.fetch_env!(:git_notes, :github_app_id)

  def token_config() do
    %{}
  end

  def get_jwt(claims \\ %{}) do
    iat = claims["iat"] || (
      DateTime.now("Etc/UTC")
      |> elem(1)
      |> DateTime.to_unix())

    exp = claims["exp"] || iat + 600

    current_exp = get_key("exp")
    if current_exp && current_exp > iat do
      get_key("jwt")
    else
      token = generate_and_sign(%{"iss" => @iss, "iat" => iat, "exp" => exp})
      set_key("exp", exp)
      set_key("jwt", token)
      token
    end
  end


end
