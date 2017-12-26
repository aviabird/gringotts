defmodule Gringotts.Gateways.CamsTest do

  Code.require_file "../mocks/cams_mock.exs", __DIR__
  use ExUnit.Case, async: false
  alias Gringotts.{
  CreditCard, Response
  }
  alias Gringotts.Gateways.CamsMock, as: MockResponse
  alias Gringotts.Gateways.Cams, as: Gateway

  import Mock

  @payment %CreditCard{
    number: "4111111111111111",
    month: 9,
    year: 2018,
    first_name: "Gopal",
    last_name: "Shimpi",
    verification_code: "123",
    brand: "visa"
  }

  @bad_payment %CreditCard {
    number: "411111111111111",
    month: 9,
    year: 2018,
    first_name: "Gopal",
    last_name: "Shimpi",
    verification_code: "123",
    brand: "visa"
  }
  @address %{
    name:     "Jim Smith",
    address1: "456 My Street",
    address2: "Apt 1",
    company:  "Widgets Inc",
    city:     "Ottawa",
    state:    "ON",
    zip:      "K1C2N6",
    country:  "US",
    phone:    "(555)555-5555",
    fax:      "(555)555-6666"
  }
  @options  [
    config: %{
      username: "testintegrationc",
      password: "password9"
    },
    order_id: 0001,
    billing_address: @address,
    description: "Store Purchase",
  ]

  @money 100
  @bad_money "G"

  describe "purchase" do

    test "with all good" do
      with_mock HTTPoison,
      [post: fn(_url, _body, _headers) ->
        MockResponse.successful_purchase end] do
          {:ok, %Response{success: result}} = Gateway
          .purchase(@money, @payment, @options)
        assert result
      end
    end

    test "with bad card" do
      with_mock HTTPoison,
      [post: fn(_url, _body, _headers) ->
        MockResponse.failed_purchase_with_bad_credit_card end] do
          {:ok, %Response{message: result}} = Gateway.
          purchase(@money, @bad_payment, @options)
          assert String.contains?(result, "Invalid Credit Card Number")
      end
    end

    test "with bad money" do
      with_mock HTTPoison,
      [post: fn(_url, _body, _headers) ->
        MockResponse.failed_purchase_with_bad_money end] do
        {:ok, %Response{message: result}} = Gateway
        .purchase(@bad_money, @payment, @options)
        assert String.contains?(result, "Invalid amount")
      end
    end

    test "with invalid currency" do
      with_mock HTTPoison,
      [post: fn(_url, _body, _headers) ->
        MockResponse.with_invalid_currency end] do
          {:ok, %Response{message: result}} = Gateway
          .purchase(@money, @payment, @options)
          assert String.contains?(result, "The cc payment type")
      end
    end
  end

  describe "authorize" do

    test "with successful authorize and capture" do
      with_mock HTTPoison,
      [post: fn(_url, _body, _headers) ->
        MockResponse.successful_authorize end] do
        {:ok, %Response{message: result}} = Gateway.
        authorize(@money, @payment, @options)
        assert result == "SUCCESS"
      end
      with_mock HTTPoison,
      [post: fn(_url, _body, _headers) ->
        MockResponse.successful_capture end] do
        {:ok, %Response{message: result}} = Gateway.
        capture(@money, "3921111362", @options)
        assert result == "SUCCESS"
      end
    end
  end

  describe "capture" do
    test "with partial amount" do
      with_mock HTTPoison,
      [post: fn(_url, _body, _headers) ->
        MockResponse.successful_authorize end] do
        {:ok, %Response{message: result}} = Gateway.
        authorize(@money, @payment, @options)
        assert result == "SUCCESS"
      end
      with_mock HTTPoison,
      [post: fn(_url, _body, _headers) ->
        MockResponse.successful_capture end] do
        {:ok, %Response{message: result}} = Gateway.
        capture(@money - 1, "3921111362", @options)
        assert result == "SUCCESS"
      end
    end

    test "with invalid transaction_id" do
      with_mock HTTPoison,
      [post: fn(_url, _body, _headers) ->
        MockResponse.successful_authorize end] do
        {:ok, %Response{success: result}} = Gateway.
        authorize(@money, @payment, @options)
        assert result
      end
      with_mock HTTPoison,
      [post: fn(_url, _body, _headers) ->
        MockResponse.invalid_transaction_id end] do
        {:ok, %Response{message: result}} = Gateway.
        capture(@money, "3921111369", @options)
        assert String.contains?(result, "Transaction not found")
      end
    end
    test "with more than authorization amount" do
      with_mock HTTPoison,
      [post: fn(_url, _body, _headers) ->
        MockResponse.successful_authorize end] do
        {:ok, %Response{success: result}} = Gateway.
        authorize(@money, @payment, @options)
        assert result
      end
      with_mock HTTPoison,
      [post: fn(_url, _body, _headers) ->
        MockResponse.more_than_authorization_amount end] do
        {:ok, %Response{message: result}} = Gateway
        .capture(@money + 1, "3921111362", @options)
        assert String.contains?(result, "exceeds the authorization amount")
      end
    end
  end

  describe "refund" do
    
    test "with all good" do
      with_mock HTTPoison,
      [post: fn(_url, _body, _headers) ->
        MockResponse.successful_purchase end] do
        {:ok, %Response{success: result}} = Gateway
        .purchase(@money, @payment, @options)
        assert result
      end
      with_mock HTTPoison,
      [post: fn(_url, _body, _headers) ->
        MockResponse.successful_refund end] do
        {:ok, %Response{success: result}} = Gateway
        .refund(@money, "3916017714", @options)
        assert result
      end
    end

    test "with more than purchase amount" do
      with_mock HTTPoison,
      [post: fn(_url, _body, _headers) ->
        MockResponse.successful_purchase end] do
        {:ok, %Response{success: result}} = Gateway
        .purchase(@money, @payment, @options)
        assert result
      end
      with_mock HTTPoison,
      [post: fn(_url, _body, _headers) ->
        MockResponse.more_than_purchase_amount end] do
        {:ok, %Response{message: result}} = Gateway
        .refund(@money + 1, "3916017714", @options)
        assert String.contains?(result, "Refund amount may not exceed")
      end
    end
  end
  
  describe "void" do  

    test "with all good" do
      with_mock HTTPoison,
      [post: fn(_url, _body, _headers) ->
        MockResponse.successful_authorize end] do
        {:ok, %Response{success: result}} = Gateway
        .authorize(@money, @payment, @options)
        assert result
      end
      with_mock HTTPoison,
      [post: fn(_url, _body, _headers) ->
        MockResponse.successful_void end] do
        {:ok, %Response{message: result}} = Gateway
        .void("3921111362", @options)
        assert String.contains?(result, "Void Successful")
      end
    end
  end
  
end
