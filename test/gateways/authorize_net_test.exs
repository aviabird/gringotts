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
    lineItem: %{itemId: "1", name: "vase", description: "Cannes logo", quantity: "18", unitPrice: "45.00"}
  ]
  @opts_refund [
    config: %{name: "64jKa6NA", transaction_key: "4vmE338dQmAN6m7B"}, 
    ref_id: "123456", 
    payment: %{card: %{number: "5424000000000015", year: 2020, month: 12}}
  ]
  @opts_store [
    config: %{name: "64jKa6NA", transaction_key: "4vmE338dQmAN6m7B"}, 
    profile: %{merchant_customer_id: "123456", description: "Profile description here", email: "customer-profile-email@here.com"}
  ]
  @opts_store_no_profile [
    config: %{name: "64jKa6NA", transaction_key: "4vmE338dQmAN6m7B"}, 
  ]

  @refund_id "60036752756"
  @void_id "60036855217"
  @unstore_id "1813991490"

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
      with_mock HTTPoison,
      [request: fn(_method, _url, _body, _headers) -> MockResponse.successful_authorize_response end] do
        {:ok, response} = ANet.authorize(@amount, @card, @opts)
        assert response.raw["createTransactionResponse"]["messages"]["resultCode"] == "Ok"
    end
    end

    test "with bad amount" do
      with_mock HTTPoison,
      [request: fn(_method, _url, _body, _headers) -> MockResponse.bad_amount_purchase_response end] do
        {:error, response} = ANet.authorize(@bad_amount, @card, @opts)
        assert response.raw["createTransactionResponse"]["messages"]["resultCode"] == "Error"
      end
    end

    test "with bad card" do
      with_mock HTTPoison,
        [request: fn(_method, _url, _body, _headers) -> MockResponse.bad_card_purchase_response end] do
          {:error, response} = ANet.authorize(@amount, @bad_card, @opts)
          assert response.raw["ErrorResponse"]["messages"]["resultCode"] == "Error"
      end
    end
  end

  describe "capture" do
    test "successful response" do
      with_mock HTTPoison,
      [request: fn(_method, _url, _body, _headers) -> MockResponse.successful_capture_response end] do
        {:ok, response} = ANet.capture(@amount, @bad_card, @opts)
        assert response.raw["createTransactionResponse"]["messages"]["resultCode"] == "Ok"
      end
    end
    
    test "with bad transaction id" do
      with_mock HTTPoison,
      [request: fn(_method, _url, _body, _headers) -> MockResponse.bad_id_capture end] do
        {:error, response} = ANet.capture(@bad_amount, @card, @opts)
        assert response.raw["createTransactionResponse"]["messages"]["resultCode"] == "Error"
      end
    end
  end

  describe "refund" do
    test "successul response" do
      with_mock HTTPoison,
      [request: fn(_method, _url, _body, _headers) -> MockResponse.successful_refund_response end] do
        {:ok, response} = ANet.refund(@amount, @refund_id, @opts_refund)
        assert response.raw["createTransactionResponse"]["messages"]["resultCode"] == "Ok"
      end
    end

    test "bad payment params" do
      with_mock HTTPoison,
        [request: fn(_method, _url, _body, _headers) -> MockResponse.bad_card_refund end] do
          {:error, response} = ANet.refund(@amount, @refund_id, @opts_refund)
          assert response.raw["ErrorResponse"]["messages"]["resultCode"] == "Error"
      end
    end

    test "debit less than refund amount" do
      with_mock HTTPoison,
        [request: fn(_method, _url, _body, _headers) -> MockResponse.debit_less_than_refund end] do
          {:error, response} = ANet.refund(@amount, @refund_id, @opts_refund)
          assert response.raw["createTransactionResponse"]["messages"]["resultCode"] == "Error"
      end
    end
  end

  describe "void" do
    test "successful response" do
      with_mock HTTPoison,
        [request: fn(_method, _url, _body, _headers) -> MockResponse.successful_void end] do
          {:ok, response} = ANet.void(@void_id, @opts)
          assert response.raw["createTransactionResponse"]["messages"]["resultCode"] == "Ok"
      end
    end
    
    test "with bad transaction id" do
      with_mock HTTPoison,
        [request: fn(_method, _url, _body, _headers) -> MockResponse.void_non_existent_id end] do
          {:error, response} = ANet.void(@void_id, @opts)
          assert response.raw["createTransactionResponse"]["messages"]["resultCode"] == "Error"
      end
    end
  end

  describe "store" do
    test "successful response" do
      with_mock HTTPoison,
        [request: fn(_method, _url, _body, _headers) -> MockResponse.successful_store_response end] do
          {:ok, response} = ANet.store(@card, @opts_store)
          assert response.raw["createCustomerProfileResponse"]["messages"]["resultCode"] == "Ok"
      end
    end

    test "without any profile" do
      with_mock HTTPoison,
        [request: fn(_method, _url, _body, _headers) -> MockResponse.store_without_profile_fields end] do
          {:error, response} = ANet.store(@card, @opts_store_no_profile)
          assert response.raw["createCustomerProfileResponse"]["messages"]["resultCode"] == "Error"
     end
    end
  end

  describe "unstore" do
    test "successful response" do
      with_mock HTTPoison,
        [request: fn(_method, _url, _body, _headers) -> MockResponse.successful_unstore_response end] do
          {:ok, response} = ANet.unstore(@unstore_id, @opts)
          assert response.raw["deleteCustomerProfileResponse"]["messages"]["resultCode"] == "Ok"
      end
    end
  end

end
