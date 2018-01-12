defmodule Gringotts.Gateways.TrexleTest do

  Code.require_file "../mocks/trexle_mock.exs", __DIR__
  use ExUnit.Case, async: false
  alias Gringotts.Gateways.TrexleMock, as: MockResponse
  alias Gringotts.Gateways.Trexle
  alias Gringotts.{
    CreditCard,
    Address
  }

  import Mock

  @valid_card %CreditCard{
    number: "5200828282828210",
    month: 12,
    year: 2018,
    first_name: "John",
    last_name: "Doe",
    verification_code: "123",
    brand: "visa"
  }

  @invalid_card %CreditCard{
    number: "5200828282828210",
    month: 12,
    year: 2010,
    first_name: "John",
    last_name: "Doe",
    verification_code: "123",
    brand: "visa"
  }

  @address %Address{
    street1: "123 Main",
    street2: "Suite 100",
    city: "New York",
    region: "NY",
    country: "US",
    postal_code: "11111",
    phone: "(555)555-5555"
  }

  @amount %{amount: Decimal.new(50), currency: "USD"}
  @bad_amount %{amount: Decimal.new(20), currency: "USD"}

  @valid_token "J5RGMpDlFlTfv9mEFvNWYoqHufyukPP4"
  @invalid_token "30"

  @opts [
    config: %{api_key: "J5RGMpDlFlTfv9mEFvNWYoqHufyukPP4", default_currency: "USD"},
    email: "john@trexle.com",
    billing_address: @address,
    ip_address: "66.249.79.118",
    description: "Store Purchase 1437598192"
  ]

  @missingip_opts [
    config: %{api_key: "J5RGMpDlFlTfv9mEFvNWYoqHufyukPP4", default_currency: "USD"},
    email: "john@trexle.com",
    billing_address: @address,
    description: "Store Purchase 1437598192"
  ]

  @invalid_opts [
    config: %{api_key: "J5RGMpDlFlTfv9mEFvNWYoqHufyukPP4"},
    email: "john@trexle.com",
    billing_address: @address,
    ip_address: "66.249.79.118",
    description: "Store Purchase 1437598192"
  ]

  describe "validation arguments check" do
    test "with no currency passed in config" do
      assert_raise ArgumentError, fn ->
        Trexle.validate_config(@invalid_opts)
      end
    end
  end

  describe "purchase" do
    test "with valid card" do
      with_mock HTTPoison,
        [request: fn(_method, _url, _body, _headers, _options) -> MockResponse.test_for_purchase_with_valid_card end] do
          {:ok, response} = Trexle.purchase(@amount, @valid_card, @opts)
          assert response.status_code == 201
          assert response.raw["response"]["success"] == true
          assert response.raw["response"]["captured"] == false
      end
    end

    test "with invalid card" do
      with_mock HTTPoison,
      [request: fn(_method, _url, _body, _headers, _options) -> MockResponse.test_for_purchase_with_invalid_card end] do
        {:error, response} = Trexle.purchase(@amount, @invalid_card, @opts)
        assert response.status_code == 400
        assert response.success == false
        assert response.raw == ~s({"error":"Payment failed","detail":"Your card's expiration year is invalid."})
      end
    end

    test "with invalid amount" do
      with_mock HTTPoison,
      [request: fn(_method, _url, _body, _headers, _options) -> MockResponse.test_for_purchase_with_invalid_amount end] do
        {:error, response} = Trexle.purchase(@bad_amount, @valid_card, @opts)
        assert response.status_code == 400
        assert response.success == false
        assert response.raw == ~s({"error":"Payment failed","detail":"Amount must be at least 50 cents"})
      end
    end
  end

  describe "authorize" do
    test "with valid card" do
      with_mock HTTPoison,
      [request: fn(_method, _url, _body, _headers, _options) -> MockResponse.test_for_authorize_with_valid_card end] do
        {:ok, response} = Trexle.authorize(@amount, @valid_card, @opts)
        assert response.status_code == 201
        assert response.raw["response"]["success"] == true
        assert response.raw["response"]["captured"] == false
      end
    end

    test "with invalid card" do
      with_mock HTTPoison,
      [request: fn(_method, _url, _body, _headers, _options) -> MockResponse.test_for_authorize_with_invalid_card end] do
        {:error, response} = Trexle.authorize(@amount, @invalid_card, @opts)
        assert response.status_code == 400
        assert response.success == false
        assert response.raw == ~s({"error":"Payment failed","detail":"Your card's expiration year is invalid."})
      end
    end

    test "with invalid amount" do
      with_mock HTTPoison,
      [request: fn(_method, _url, _body, _headers, _options) -> MockResponse.test_for_authorize_with_invalid_amount end] do
        {:error, response} = Trexle.authorize(@amount, @valid_card, @opts)
        assert response.status_code == 400
        assert response.success == false
        assert response.raw == ~s({"error":"Payment failed","detail":"Amount must be at least 50 cents"})
      end
    end

    test "with missing ip address" do
      with_mock HTTPoison,
      [request: fn(_method, _url, _body, _headers, _options) -> MockResponse.test_for_authorize_with_missing_ip_address end] do
        {:error, response} = Trexle.authorize(@amount, @valid_card, @missingip_opts)
        assert response.status_code == 500
        assert response.success == false
        assert response.raw == ~s({"error":"ip_address is missing"})
      end
    end
  end

  describe "refund" do
    test "with valid token" do
      with_mock HTTPoison,
      [request: fn(_method, _url, _body, _headers, _options) -> MockResponse.test_for_authorize_with_valid_card end] do
        {:ok, response} = Trexle.refund(@amount, @valid_token, @opts)
        assert response.status_code == 201
        assert response.raw["response"]["success"] == true
        assert response.raw["response"]["captured"] == false
      end
    end

    test "with invalid token" do
      with_mock HTTPoison,
      [request: fn(_method, _url, _body, _headers, _options) -> MockResponse.test_for_authorize_with_invalid_amount end] do
        {:error, response} = Trexle.refund(@amount, @invalid_token, @opts)
        assert response.status_code == 400
        assert response.success == false
        assert response.raw == ~s({"error":"Payment failed","detail":"Amount must be at least 50 cents"})
      end
    end
  end

  describe "capture" do
    test "with valid chargetoken" do
      with_mock HTTPoison,
      [request: fn(_method, _url, _body, _headers, _options) -> MockResponse.test_for_capture_with_valid_chargetoken end] do
        {:ok, response} = Trexle.capture(@valid_token, @amount, @opts)
        assert response.status_code == 200
        assert response.raw["response"]["success"] == true
        assert response.raw["response"]["captured"] == true
        assert response.raw["response"]["status_message"] == "Transaction approved"
      end
    end

    test "test_for_capture_with_invalid_chargetoken" do
     with_mock HTTPoison,
     [request: fn(_method, _url, _body, _headers, _options) -> MockResponse.test_for_capture_with_invalid_chargetoken end] do
      {:error, response} = Trexle.capture(@invalid_token, @amount, @opts)
      assert response.status_code == 400
      assert response.success == false
      assert response.raw == ~s({"error":"Capture failed","detail":"invalid token"})
     end
    end
  end

  describe "store" do
    test "with valid card" do
      with_mock HTTPoison,
        [request: fn(_method, _url, _body, _headers, _options) -> MockResponse.test_for_store_with_valid_card end] do
        {:ok, response} = Trexle.store(@valid_card, @opts)
        assert response.status_code == 201
      end
    end
  end

  describe "network failure" do
    test "with authorization" do
      with_mock HTTPoison,
        [request: fn(_method, _url, _body, _headers, _options) -> MockResponse.test_for_network_failure end] do
        {:error, response} = Trexle.authorize(@amount, @valid_card, @opts)
        assert response.success == false
        assert response.reason == :network_fail?
      end
    end
  end
end
