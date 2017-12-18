defmodule Kuber.Hex.Gateways.AuthorizeNetTest do
  use ExUnit.Case, async: false
  alias Kuber.Hex.Gateways.AuthorizeNet, as: Gateway
  alias Kuber.Hex.Gateways.AuthorizeNetMock, as: MockServer
  alias Kuber.Hex.CreditCard
  alias Kuber.Hex.Gateways.AuthorizeNet, as: ANet

  @card %CreditCard {
    number: "5424000000000015",
    month: 12,
    year: 2020,
    verification_code: 999
  }
  @amount 20

  @opts [
    config: %{name: "64jKa6NA", transactionKey: "4vmE338dQmAN6m7B"}, 
    refId: "123456", 
    order: %{invoiceNumber: "INV-12345", description: "Product Description"}, 
    lineItem: %{itemId: "1", name: "vase", description: "Cannes logo", quantity: "18", unitPrice: "45.00" }
  ]

  describe "purchase" do
    test "test_successful_purchase" do
      {:ok, response} = ANet.purchase(@amount, @card, @opts)
    end
  end
end
