defmodule Gringotts.Gateways.OpenpayTest do
  use ExUnit.Case, async: false
  alias Gringotts.Gateways.OpenpayMock, as: MockResponse
  alias Gringotts.{CreditCard, FakeMoney}
  alias Gringotts.Gateways.Openpay, as: Openpay

  import Mock

  @auth %{name: "64jKa6NA", transaction_key: "4vmE338dQmAN6m7B"}
  @card %CreditCard{
    number: "5424000000000015",
    month: 12,
    year: 2099,
    verification_code: "999",
    brand: "visa"
  }

  @bad_card %CreditCard{
    number: "123",
    month: 10,
    year: 2010,
    verification_code: "123",
    brand: "visa"
  }

  @amount FakeMoney.new("2.99", :USD)

  @opts [
    config: @auth,
    ref_id: "123456",
    order: %{invoice_number: "INV-12345", description: "Product Description"},
    lineitems: %{
      item_id: "1",
      name: "vase",
      description: "Cannes logo",
      quantity: 18,
      unit_price: FakeMoney.new("53.82", :USD)
    },
    tax: %{name: "VAT", amount: FakeMoney.new("0.1", :EUR), description: "Value Added Tax"},
    shipping: %{
      name: "SAME-DAY-DELIVERY",
      amount: FakeMoney.new("0.56", :EUR),
      description: "Zen Logistics"
    },
    duty: %{
      name: "import_duty",
      amount: FakeMoney.new("0.25", :EUR),
      description: "Upon import of goods"
    }
  ]
  @opts_refund [
    config: @auth,
    ref_id: "123456",
    payment: %{card: %{number: "5424000000000015", year: 2099, month: 12}}
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
    config: @auth
  ]
  @opts_refund [
    config: @auth,
    ref_id: "123456",
    payment: %{card: %{number: "5424000000000015", year: 2099, month: 12}}
  ]
  @opts_refund_bad_payment [
    config: @auth,
    ref_id: "123456",
    payment: %{card: %{number: "123", year: 2099, month: 12}}
  ]
  @opts_store [
    config: @auth,
    profile: %{
      merchant_customer_id: "123456",
      description: "Profile description here",
      email: "customer-profile-email@here.com"
    }
  ]
  @opts_store_no_profile [
    config: @auth
  ]
  @opts_customer_profile [
    config: @auth,
    customer_profile_id: "1814012002",
    validation_mode: "testMode",
    customer_type: "individual"
  ]
  @opts_customer_profile_args [
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
        request: fn _method, _path, _body, _options ->
          MockResponse.successful_purchase_response()
        end do
        assert {:ok, _response} = Openpay.purchase(@amount, @card, @opts)
      end
    end

    test "with bad card" do
      with_mock HTTPoison,
        request: fn _method, _path, _body, _options ->
          MockResponse.bad_card_purchase_response()
        end do
        assert {:error, _response} = Openpay.purchase(@amount, @bad_card, @opts)
      end
    end
  end

  describe "authorize" do
    test "successful response with right params" do
      with_mock HTTPoison,
        request: fn _method, _path, _body, _options ->
          MockResponse.successful_authorize_response()
        end do
        assert {:ok, _response} = Openpay.authorize(@amount, @card, @opts)
      end
    end

    test "with bad card" do
      with_mock HTTPoison,
        request: fn _method, _path, _body, _options ->
          MockResponse.bad_card_purchase_response()
        end do
        assert {:error, _response} = Openpay.authorize(@amount, @bad_card, @opts)
      end
    end
  end

  describe "capture" do
    test "successful response with right params" do
      with_mock HTTPoison,
        request: fn _method, _path, _body, _options ->
          MockResponse.successful_capture_response()
        end do
        assert {:ok, _response} = Openpay.capture(@capture_id, @amount, @opts)
      end
    end

    test "with bad transaction id" do
      with_mock HTTPoison,
        request: fn _method, _path, _body, _options -> MockResponse.bad_id_capture() end do
        assert {:error, _response} = Openpay.capture(@capture_invalid_id, @amount, @opts)
      end
    end
  end

  describe "refund" do
    test "successful response with right params" do
      with_mock HTTPoison,
        request: fn _method, _path, _body, _options ->
          MockResponse.successful_refund_response()
        end do
        assert {:ok, _response} = Openpay.refund(@amount, @refund_id, @opts_refund)
      end
    end

    test "bad payment params" do
      with_mock HTTPoison,
        request: fn _method, _path, _body, _options -> MockResponse.bad_card_refund() end do
        assert {:error, _response} = Openpay.refund(@amount, @refund_id, @opts_refund_bad_payment)
      end
    end

    test "debit less than refund amount" do
      with_mock HTTPoison,
        request: fn _method, _path, _body, _options ->
          MockResponse.debit_less_than_refund()
        end do
        assert {:error, _response} = Openpay.refund(@amount, @refund_id, @opts_refund)
      end
    end
  end

  describe "void" do
    test "successful response with right params" do
      with_mock HTTPoison,
        request: fn _method, _path, _body, _options -> MockResponse.successful_void() end do
        assert {:ok, _response} = Openpay.void(@void_id, @opts)
      end
    end

    test "with bad transaction id" do
      with_mock HTTPoison,
        request: fn _method, _path, _body, _options ->
          MockResponse.void_non_existent_id()
        end do
        assert {:error, _response} = Openpay.void(@void_invalid_id, @opts)
      end
    end
  end

  test "network error type non existent domain" do
    with_mock HTTPoison,
      request: fn _method, _path, _body, _options ->
        MockResponse.netwok_error_non_existent_domain()
      end do
      assert {:error, response} = Openpay.purchase(@amount, @card, @opts)
      assert response.message == "HTTPoison says 'nxdomain' [ID: nil]"
    end
  end
end
