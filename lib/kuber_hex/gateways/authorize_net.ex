defmodule Kuber.Hex.Gateway.AuthorizeNet do
  import XmlBuilder
  
  @test_url "https://apitest.authorize.net/xml/v1/request.api"
  @production_url "https://api.authorize.net/xml/v1/request.api"
  @transaction_type %{
    purchase: "authCaptureTransaction"
  }
  @aut_net_namespace "AnetApi/xml/v1/schema/AnetApiSchema.xsd"

  alias Kuber.Hex.{
    CreditCard,
    Address,
    Response
  }

  def authenticate(opts) do
    case Keyword.fetch(opts, :config) do
      {:ok, config} -> 
        data = add_auth_request(config)
        commit(:post, data)
      {:error, _} -> {:error, "config not found"}
    end
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
    headers = [{"Content-Type", "text/xml"}]
    HTTPoison.request(method, path, payload, headers)
  end

  defp add_auth_request(opts) do
    element(:authenticateTestRequest, %{xmlns: @aut_net_namespace} , [
      element(:merchantAuthentication, [
        element(:name, opts.name),
        element(:transactionKey, opts.transactionKey)
      ])
     ]) 
     |> generate
  end
end