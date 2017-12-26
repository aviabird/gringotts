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

    test "test_sucessful_purchase" do
      with_mock HTTPoison,
      [ post: fn( _url, _body, _headers ) ->
        MockResponse.successful_purchase_response end ] do
          { :ok, %Response{ success: result } } = Gateway
          .purchase( @money, @payment, @options )
        assert result
      end
    end

    test "test_bad_card_failed_purchase" do
      with_mock HTTPoison,
      [ post: fn( _url, _body, _headers ) ->
        MockResponse.failed_purchase_with_bad_credit_card end ] do
          { :ok, %Response{ message: result } } = Gateway.
          purchase( @money, @bad_payment, @options )
          assert String.contains?( result, "Invalid Credit Card Number" )
      end
    end

    test "test_bad_money_failed_purchase" do
      with_mock HTTPoison,
      [ post: fn( _url, _body, _headers ) ->
        MockResponse.failed_purchase_with_bad_money end ] do
        { :ok, %Response{ message: result } } = Gateway
        .purchase( @bad_money, @payment, @options )
        assert String.contains?( result, "Invalid amount" )
      end
    end
  end
end
