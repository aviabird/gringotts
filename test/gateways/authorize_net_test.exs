defmodule Gringotts.Gateways.AuthorizeNetTest do
  
  Code.require_file "../mocks/authorize_net_mock.exs", __DIR__
  use ExUnit.Case, async: false
  alias Gringotts.Gateways.AuthorizeNetMock, as: MockResponse
  alias Gringotts.CreditCard
  alias Gringotts.Gateways.AuthorizeNet, as: ANet
  
  import Mock

  @auth %{name: "64jKa6NA", transaction_key: "4vmE338dQmAN6m7B"}
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

  @amount %{amount: Decimal.new(20.0), currency: 'USD'}

  @opts [
    config: @auth,
    ref_id: "123456",
    order: %{invoice_number: "INV-12345", description: "Product Description"}, 
    lineitems: %{
      item_id: "1",
      name: "vase",
      description: "Cannes logo", 
      quantity: "18", 
      unit_price: %{amount: Decimal.new(20.0), currency: 'USD'}
    }
  ]
  @opts_refund [
    config: @auth,
    ref_id: "123456", 
    payment: %{card: %{number: "5424000000000015", year: 2020, month: 12}}
  ]

  @opts_store [
    config: @auth,
    profile: %{
      merchant_customer_id: "123456", 
      description: "Profile description here", 
      email: "customer-profile-email@here.com"
    },
    customer_type: "individual",
    validation_mode: "testMode"
  ]
  @opts_store_without_validation [
    config: @auth,
    profile: %{
      merchant_customer_id: "123456", 
      description: "Profile description here", 
      email: "customer-profile-email@here.com"
    }
  ]

  @opts_store_no_profile [
    config: @auth,
  ]
  @opts_refund [
    config: @auth,
    ref_id: "123456",
    payment: %{card: %{number: "5424000000000015", year: 2020, month: 12}}
  ]
  @opts_refund_bad_payment [
    config: @auth,
    ref_id: "123456",
    payment: %{card: %{number: "123", year: 2020, month: 12}}
  ]
  @opts_store [
    config: @auth,
    profile: %{merchant_customer_id: "123456",
      description: "Profile description here",
      email: "customer-profile-email@here.com"
    }
  ]
  @opts_store_no_profile [
    config: @auth,
  ]
  @opts_customer_profile [
    config: @auth,
    customer_profile_id: "1814012002",
    validation_mode: "testMode",
    customer_type: "individual"
  ]
  @opts_customer_profile_args[
    config: @auth,
    customer_profile_id: "1814012002"  
  ]
  
  @refund_id "60036752756"
  @void_id "60036855217"
  @void_invalid_id "60036855211"
  @unstore_id "1813991490"
  @capture_id "60036752756"
  @capture_invalid_id "60036855211"

  @refund_id "60036752756"
  @void_id "60036855217"
  @unstore_id "1813991490"

  describe "purchase" do
    test "successful response with right params" do
      with_mock HTTPoison,
        [request: fn(_method, _url, _body, _headers) -> MockResponse.successful_purchase_response end] do
          assert {:ok, response} = ANet.purchase(@amount, @card, @opts)
          assert response.params["createTransactionResponse"]["messages"]["resultCode"] == "Ok"
      end
    end

    test "with bad card" do
      with_mock HTTPoison, 
        [request: fn(_method, _url, _body, _headers) -> MockResponse.bad_card_purchase_response end] do
          assert {:error, response} = ANet.purchase(@amount, @bad_card, @opts)
          assert response.params["ErrorResponse"]["messages"]["resultCode"] == "Error"
      end
    end
  end

  describe "authorize" do
    test "successful response with right params" do
      with_mock HTTPoison,
      [request: fn(_method, _url, _body, _headers) -> MockResponse.successful_authorize_response end] do
        assert {:ok, response} = ANet.authorize(@amount, @card, @opts)
        assert response.params["createTransactionResponse"]["messages"]["resultCode"] == "Ok"
    end
    end

    test "with bad card" do
      with_mock HTTPoison,
        [request: fn(_method, _url, _body, _headers) -> MockResponse.bad_card_purchase_response end] do
          assert {:error, response} = ANet.authorize(@amount, @bad_card, @opts)
          assert response.params["ErrorResponse"]["messages"]["resultCode"] == "Error"
      end
    end
  end

  describe "capture" do
    test "successful response with right params" do
      with_mock HTTPoison,
      [request: fn(_method, _url, _body, _headers) -> MockResponse.successful_capture_response end] do
        assert {:ok, response} = ANet.capture(@capture_id, @amount, @opts)
        assert response.params["createTransactionResponse"]["messages"]["resultCode"] == "Ok"
      end
    end
    
    test "with bad transaction id" do
      with_mock HTTPoison,
      [request: fn(_method, _url, _body, _headers) -> MockResponse.bad_id_capture end] do
        assert {:error, response} = ANet.capture(@capture_invalid_id, @amount, @opts)
        assert response.params["createTransactionResponse"]["messages"]["resultCode"] == "Error"
      end
    end
  end

  describe "refund" do
    test "successful response with right params" do
      with_mock HTTPoison,
      [request: fn(_method, _url, _body, _headers) -> MockResponse.successful_refund_response end] do
        assert {:ok, response} = ANet.refund(@amount, @refund_id, @opts_refund)
        assert response.params["createTransactionResponse"]["messages"]["resultCode"] == "Ok"
      end
    end

    test "bad payment params" do
      with_mock HTTPoison,
        [request: fn(_method, _url, _body, _headers) -> MockResponse.bad_card_refund end] do
          assert {:error, response} = ANet.refund(@amount, @refund_id, @opts_refund_bad_payment)
          assert response.params["ErrorResponse"]["messages"]["resultCode"] == "Error"
      end
    end

    test "debit less than refund amount" do
      with_mock HTTPoison,
        [request: fn(_method, _url, _body, _headers) -> MockResponse.debit_less_than_refund end] do
          assert {:error, response} = ANet.refund(@amount, @refund_id, @opts_refund)
          assert response.params["createTransactionResponse"]["messages"]["resultCode"] == "Error"
      end
    end
  end

  describe "void" do
    test "successful response with right params" do
      with_mock HTTPoison,
        [request: fn(_method, _url, _body, _headers) -> MockResponse.successful_void end] do
          assert {:ok, response} = ANet.void(@void_id, @opts)
          assert response.params["createTransactionResponse"]["messages"]["resultCode"] == "Ok"
      end
    end
    
    test "with bad transaction id" do
      with_mock HTTPoison,
        [request: fn(_method, _url, _body, _headers) -> MockResponse.void_non_existent_id end] do
          assert {:error, response} = ANet.void(@void_invalid_id, @opts)
          assert response.params["createTransactionResponse"]["messages"]["resultCode"] == "Error"
      end
    end
  end

  describe "store" do
    test "successful response with right params" do
      with_mock HTTPoison,
        [request: fn(_method, _url, _body, _headers) -> MockResponse.successful_store_response end] do
          assert {:ok, response} = ANet.store(@card, @opts_store)
          assert response.params["createCustomerProfileResponse"]["messages"]["resultCode"] == "Ok"
      end
    end

    test "successful response without validation and customer type" do
      with_mock HTTPoison,
        [request: fn(_method, _url, _body, _headers) -> MockResponse.successful_store_response end] do
          assert {:ok, response} = ANet.store(@card, @opts_store_without_validation)
          assert response.params["createCustomerProfileResponse"]["messages"]["resultCode"] == "Ok"
      end
    end

    test "without any profile" do
      with_mock HTTPoison,
        [request: fn(_method, _url, _body, _headers) -> MockResponse.store_without_profile_fields end] do
          assert {:error, response} = ANet.store(@card, @opts_store_no_profile)
          assert response.params["createCustomerProfileResponse"]["messages"]["resultCode"] == "Error"
     end
    end

    test "with customer profile id" do
      with_mock HTTPoison,
        [request: fn(_method, _url, _body, _headers) -> MockResponse.customer_payment_profile_success_response end] do
          assert {:ok, response} = ANet.store(@card, @opts_customer_profile)
          assert response.params["createCustomerPaymentProfileResponse"]["messages"]["resultCode"] == "Ok"
      end
    end

    test "successful response without valiadtion mode and customer type" do
      with_mock HTTPoison,
        [request: fn(_method, _url, _body, _headers) -> MockResponse.successful_store_response end] do
          assert {:ok, response} = ANet.store(@card, @opts_customer_profile_args)
          assert response.params["createCustomerProfileResponse"]["messages"]["resultCode"] == "Ok"
      end
    end
  end

  describe "unstore" do
    test "successful response with right params" do
      with_mock HTTPoison,
        [request: fn(_method, _url, _body, _headers) -> MockResponse.successful_unstore_response end] do
          assert {:ok, response} = ANet.unstore(@unstore_id, @opts)
          assert response.params["deleteCustomerProfileResponse"]["messages"]["resultCode"] == "Ok"
      end
    end
  end

  test "network error type non existent domain" do
    with_mock HTTPoison,
      [request: fn(_method, _url, _body, _headers) -> MockResponse.netwok_error_non_existent_domain end] do
        assert {:error, response} = ANet.purchase(@amount, @card, @opts)
        assert response.message == "HTTPoison says 'nxdomain'"
    end
  end

end
