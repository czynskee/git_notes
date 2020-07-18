defmodule GitNotes.GithubTest do
  alias GitNots.Github


  # Should pass a conn to request resources which contains all the resources
  # we need to request in it, along with any necessary auth tokens.
  # This way they can all be requested in parallel.

  # You can either authenticate as a github app or as an "installation". I
  # don't understand the material differences between the two.

  # I think the first is the high level authentication for the app at large
  # I think the second is for specific "installations" of the app i.e. per
  # user/org

  # Requirements:
  # must pass in API version in the Accept header

  # Authentication as a Github App
  # Generate private key - done
  # Use the key to sign a JWT and encode it using RS256 algorithm.
  # Github checks that the request is authenticated by verifying the token with the public key

  test "generate a JWT" do

  end
end
