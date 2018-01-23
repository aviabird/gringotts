defmodule Gringotts.Gateways.CamsTest do

  Code.require_file "../mocks/cams_mock.exs", __DIR__
  use ExUnit.Case, async: false
  alias Gringotts.{
  CreditCard, Response
  }
  alias Gringotts.Gateways.CamsMock, as: MockResponse
  alias Gringotts.Gateways.Cams, as: Gateway

  import Mock

  @card %CreditCard{
    number: "4111111111111111",
    month: 11,
    year: 2099,
    first_name: "Harry",
    last_name: "Potter",
    verification_code: "999",
    brand: "VISA"
  }
  @bad_card %CreditCard{
    number: "42",
    month: 11,
    year: 2099,
    first_name: "Harry",
    last_name: "Potter",
    verification_code: "999",
    brand: "VISA"
  }
  @address %{
    street1: "301, Gryffindor",
    street2: "Hogwarts School of Witchcraft and Wizardry, Hogwarts Castle",
    city: "Highlands",
    state: "Scotland",
    country: "GB",
    company:  "Ollivanders",
    zip:      "K1C2N6",
    phone:    "(555)555-5555",
    fax:      "(555)555-6666"
  }
  @auth %{username: "some_secret_user_name",
          password: "some_secret_password"}
  @options [
    order_id: 0001,
    billing_address: @address,
    description: "Store Purchase"
  ]

  @money Money.new(:USD, 100)
  @money_more Money.new(:USD, 101)
  @money_less Money.new(:USD, 99)

  @authorization "some_transaction_id"
  @bad_authorization "some_fake_transaction_id"

  setup_all do
    Application.put_env(:gringotts, Gateway, [adapter: Gateway,
                                              username: "some_secret_user_name",
                                              password: "some_secret_password"])
  end
  
  describe "purchase" do
    test "with correct params" do
      with_mock HTTPoison,
      [post: fn(_url, _body, _headers) -> MockResponse.successful_purchase end] do
        {:ok, %Response{success: result}} = Gringotts.purchase(Gateway, @money, @card, @options)
        assert result
      end
    end

    test "with bad card" do
      with_mock HTTPoison,
      [post: fn(_url, _body, _headers) -> MockResponse.failed_purchase_with_bad_credit_card end] do
        {:ok, %Response{message: result}} = Gringotts.purchase(Gateway, @money, @bad_card, @options)
        assert String.contains?(result, "Invalid Credit Card Number")
      end
    end

    test "with invalid currency" do
      with_mock HTTPoison,
      [post: fn(_url, _body, _headers) -> MockResponse.with_invalid_currency end] do
        {:ok, %Response{message: result}} = Gringotts.purchase(Gateway, @money, @card, @options)
        assert String.contains?(result, "The cc payment type")
      end
    end
  end

  describe "authorize" do
    test "with correct params" do
      with_mock HTTPoison,
      [post: fn(_url, _body, _headers) -> MockResponse.successful_authorize end] do
        {:ok, %Response{success: result}} = Gringotts.authorize(Gateway, @money, @card, @options)
        assert result
      end
    end

    test "with bad card" do
      with_mock HTTPoison,
      [post: fn(_url, _body, _headers) -> MockResponse.failed_authorized_with_bad_card end] do
        {:ok, %Response{message: result}} = Gringotts.authorize(Gateway, @money, @bad_card, @options)
        assert String.contains?(result, "Invalid Credit Card Number")
      end
    end
  end

  describe "capture" do
    test "with full amount" do
      with_mock HTTPoison,
      [post: fn(_url, _body, _headers) -> MockResponse.successful_capture end] do
        {:ok, %Response{success: result}} = Gringotts.capture(Gateway, @money, @authorization, @options)
        assert result
      end
    end

    test "with partial amount" do
      with_mock HTTPoison,
      [post: fn(_url, _body, _headers) -> MockResponse.successful_capture end] do
        {:ok, %Response{success: result}} = Gringotts.capture(Gateway, @money_less, @authorization, @options)
        assert result
      end
    end

    test "with invalid transaction_id" do
      with_mock HTTPoison,
      [post: fn(_url, _body, _headers) -> MockResponse.invalid_transaction_id end] do
        {:ok, %Response{message: result}} = Gringotts.capture(Gateway, @money, @bad_authorization, @options)
        assert String.contains?(result, "Transaction not found")
      end
    end

    test "with more than authorization amount" do
      with_mock HTTPoison,
      [post: fn(_url, _body, _headers) -> MockResponse.more_than_authorization_amount end] do
        {:ok, %Response{message: result}} = Gringotts.capture(Gateway, @money_more, @authorization, @options)
        assert String.contains?(result, "exceeds the authorization amount")
      end
    end

    test "on already captured transaction" do
      with_mock HTTPoison,
      [post: fn(_url, _body, _headers) -> MockResponse.multiple_capture_on_same_transaction end] do
        {:ok, %Response{message: result}} = Gringotts.capture(Gateway, @money, @authorization, @options)
        assert String.contains?(result, "A capture requires that")
      end
    end
  end

  describe "refund" do
    test "with correct params" do
      with_mock HTTPoison,
      [post: fn(_url, _body, _headers) -> MockResponse.successful_refund end] do
        {:ok, %Response{success: result}} = Gringotts.refund(Gateway, @money, @authorization, @options)
        assert result
      end
    end

    test "with more than purchased amount" do
      with_mock HTTPoison,
      [post: fn(_url, _body, _headers) -> MockResponse.more_than_purchase_amount end] do
        {:ok, %Response{message: result}} = Gringotts.refund(Gateway, @money_more, @authorization, @options)
        assert String.contains?(result, "Refund amount may not exceed")
      end
    end
  end
  
  describe "void" do  
    test "with correct params" do
      with_mock HTTPoison,
      [post: fn(_url, _body, _headers) -> MockResponse.successful_void end] do
        {:ok, %Response{message: result}} = Gringotts.void(Gateway, @authorization, @options)
        assert String.contains?(result, "Void Successful")
      end
    end

    test "with invalid transaction_id" do
      with_mock HTTPoison,
      [post: fn(_url, _body, _headers) -> MockResponse.invalid_transaction_id end] do
        {:ok, %Response{message: result}} = Gringotts.void(Gateway, @bad_authorization, @options)
        assert String.contains?(result, "Transaction not found")
      end
    end
  end

  describe "validate" do
    test "with correct params" do
      with_mock HTTPoison,
      [post: fn(_url, _body, _headers) -> MockResponse.validate_creditcard end] do
        {:ok, %Response{success: result}} = Gateway.validate(@card, @options ++ [config: @auth])
        assert result
      end
    end
  end
end
