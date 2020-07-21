defmodule GitNotes.GithubTest do
  use GitNotes.DataCase, async: true
  alias GitNotes.Github
  @http_adapter Application.fetch_env!(:git_notes, :http_adapter)
  @api_url Application.fetch_env!(:git_notes, :github_api_url)
  @api_version Application.fetch_env!(:git_notes, :github_api_version)
  @request_struct Module.concat(@http_adapter, Request)

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

      %{
        request: %@request_struct{
          url: base_url <> "/tests",
          method: :get
        },
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


    @doc """

    Actually this can work differently. We can fire off async tasks as soon as we have them,
    with functions that say what to do next. Before we respond to client we can await for all
    of our responses in our mailbox.

    We will have to know when we have gotten all of our responses and which ones we got so we should save
    on the conn a map of all the things we're expecting back. Then when we've gotten all of those
    out of the mailbox we can proceed
    """
    test "a single request hits the http_adapter and we get the appropriate msg back from our test controller", %{request: request, url: url} do
      request = Map.put(request, :params, %{
        result: "success"
      })

      { :ok, result } = Github.make_request(request)

      assert result.status_code == 200

      request = Map.put(request, :params, %{
        result: "failure"
      })

      { :ok, result } = Github.make_request(request)

      assert result.status_code == 400
    end

    test "requests include token", %{request: request} do
      {:ok, token, _} = GitNotes.Token.get_token()

      {:ok, response} = Github.make_request(request)

      auth_header = get_header(response, :Authorization)

      assert elem(auth_header, 1) == "Bearer #{token}"
    end

    test "requests include api version", %{request: request} do
      {:ok, response} = Github.make_request(request)

      accept_header = get_header(response, :Accept)

      assert elem(accept_header, 1) == @api_version

    end

    test "makes post request to get access_token for installation" do
        request = Github.get_access_token(123)

        assert request.url == @api_url <> "/installations/123/access_tokens"
        assert request.method == :post
    end

    test "addding request to queue will cause it to be made immediately and will return the response to senders mailbox", %{request: request} do
      request = Map.put(request, :params, %{
        sleep: 10000
      })

      Github.enqueue_request(self(), request)

      response = assert_receive({_pid, HTTPoison.Request}, 1000)
      # response = receive do
      #   {_pid, response } -> response
      # after
      #   1000 -> assert true == false
      # end

      assert response.body == "success"

    end

    # test "one test for real", %{request: request} do
    #    request = Map.put(request, :url, @api_url <> "/installations")

    #    {:ok, response } = Github.make_request(request)

    #    IO.inspect Jason.decode(response.body)
    # end

    defp get_header(response, header) do
      request_headers = response.request.headers

      Enum.find(request_headers, &(elem(&1, 0) == header))
    end

  end


end
