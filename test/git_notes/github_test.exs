defmodule GitNotes.GithubTest do
  use GitNotes.DataCase, async: true
  alias GitNotes.Github
  @http_adapter Application.fetch_env!(:git_notes, :http_adapter)
  @api_url Application.fetch_env!(:git_notes, :github_api_url)

  test "add param adds param to url with correct format" do
    url = Github.add_param(@api_url, "paramKey", "paramVal")

    assert url == @api_url <> "&paramKey=paramVal"
  end

  test "add params adds multiple params to url with correct format" do
    url = Github.add_params(@api_url, [{"key1", "val1"}, {"key2", "val2"}])

    assert url == @api_url <> "?&key1=val1&key2=val2"
  end

  test "add params does nothing when there are no params passed" do
    url = Github.add_params(@api_url, nil)

    assert url == @api_url
  end

  test "add params works when just one param is passed" do
    url = Github.add_params(@api_url, "key", "val")

    assert url == @api_url <> "?&key=val"
  end

  describe "tests around making requests" do
    setup do
      hostname =
        Application.fetch_env(:git_notes, GitNotes.Repo)
        |> elem(1)
        |> Enum.find(&(elem(&1, 0) == :hostname))
        |> elem(1)

      port =
        Application.fetch_env(:git_notes, GitNotesWeb.Endpoint)
        |> elem(1)
        |> Enum.find(&(elem(&1, 0) == :http))
        |> elem(1)
        |> Enum.find(&(elem(&1, 0) == :port))
        |> elem(1)

      base_url = "http://#{hostname}:#{port}"

      request_struct = Module.concat(@http_adapter, Request) |> Kernel.struct(%{})

      %{
        request: request_struct,
        url: base_url
      }
    end

    @doc """
    We want to be able to add a bunch of requests to a connection and then make them all at once
    in parallel, for more speed
    we also want to be able to define, for each request, a set of requests that should be made after
    that request returns. These requests could be standalone requests or they might take something that
    is returned in the first request and make the request based on that
    So here's the rough structure:

    [request_chain: {
      request: List of Request structs (1 to many)
      after_request_fn?: fn (list of responses) ->
        if we return {:request, request_chain} ->
          execute the requests in that chain and any subsequent request chains defined by further functions
        else if we return :done -> don't make any more requests
    }]

    Each request that fires should add its response to a response list which will be what is returned
    """
    test "a single request hits the http_adapter and we get a success msg back", %{request: request, url: url} do
      request_props = %{
        url: "/tests",
        method: :get
        params: %{result: "success"}
      }

      request = Map.merge(request, request_props)


      IO.inspect request
      IO.inspect url
    end

  end


end
