defmodule Kuber.Hex.Gateway.AuthorizeNet do
  import Poison

  @test_url "https://apitest.authorize.net/xml/v1/request.api"
  @production_url "https://api.authorize.net/xml/v1/request.api"
  @transaction_type %{
    purchase: "authCaptureTransaction"
  }

  alias Kuber.Hex.{
    CreditCard,
    Address,
    Response
  }

  def authenticate(opts) do
    {:ok, config} = Keyword.fetch(opts, :config)
    merchantAuth = Map.put_new(%{}, :merchantAuthentication, config)
    {:ok, auth} = Map.put_new(%{}, :authenticateTestRequest, merchantAuth) |> Poison.encode
    IO.inspect auth
    commit(:post, auth)
  end
  
  def purchase(amount, payment, opts) do
    data = add_auth_purchase(amount,opts) |> Poison.encode()
    commit(:post,data)
  end

  # creates a map to include all the fields for charging the credit card
  defp add_auth_purchase(amount,opts) do
  end

  defp commit(method, payload) do
    path = @test_url
    headers = [{"Content-Type", "application/json"}]
    HTTPoison.request(method, path, payload, headers)
  end

end