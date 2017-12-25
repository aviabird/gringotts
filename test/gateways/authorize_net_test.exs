defmodule Gringotts.Gateways.AuthorizeNetTest do
  
  Code.require_file "../mocks/authorize_net_mock.exs", __DIR__
  use ExUnit.Case, async: false
  alias Gringotts.Gateways.AuthorizeNetMock, as: MockResponse
  alias Gringotts.CreditCard
  alias Gringotts.Gateways.AuthorizeNet, as: ANet
  
  import Mock

  @card %CreditCard {
    number: "5424000000000015",
    month: 12,
    year: 2020,
    verification_code: 999
  }

  @bad_card %CreditCard {
    number: "123",
    month: 10,
    year: 2010,
    verification_code: 123
  }

  @amount 20
  @bad_amount "a"

  @opts [
    config: %{name: "64jKa6NA", transactionKey: "4vmE338dQmAN6m7B"},
    refId: "123456",
    order: %{invoiceNumber: "INV-12345", description: "Product Description"}, 
    lineItem: %{itemId: "1", name: "vase", description: "Cannes logo", quantity: "18", unitPrice: "45.00" }
  ]

  describe "purchase" do
    test "successful response" do
      with_mock HTTPoison,
        [request: fn(_method, _url, _body, _headers) -> MockResponse.successful_purchase_response end] do
          {:ok, response} = ANet.purchase(@amount, @card, @opts)
          assert response.raw["createTransactionResponse"]["messages"]["resultCode"] == "Ok"
      end
    end

    test "with bad amount" do
      with_mock HTTPoison,
      [request: fn(_method, _url, _body, _headers) -> MockResponse.bad_amount_purchase_response end] do
        {:error, response} = ANet.purchase(@bad_amount, @card, @opts)
        assert response.raw["createTransactionResponse"]["messages"]["resultCode"] == "Error"
      end
    end

    test "with bad card" do
      with_mock HTTPoison, 
        [request: fn(_method, _url, _body, _headers) -> MockResponse.bad_card_purchase_response end] do
          {:error, response} = ANet.purchase(@amount, @bad_card, @opts)
          assert response.raw["ErrorResponse"]["messages"]["resultCode"] == "Error"
      end
    end

    test "test network error" do
      with_mock HTTPoison, [request: fn(_method, _url, _body, _headers) -> MockResponse.network_error_response end] do
        assert {:error, response} = ANet.purchase(@amount, @card, @opts)
      end
    end
  end

  describe "authorize" do
    test "successful response" do
      with_mock
    end 
  end

end
