defmodule Gringotts.Gateways.TrexleTest do
  
  Code.require_file "../mocks/trexle_mock.exs", __DIR__
  use ExUnit.Case, async: false
  alias Gringotts.Gateways.TrexleMock, as: MockResponse
  alias Gringotts.Gateways.Trexle
  
  import Mock

  @valid_card %{
    name: "John Doe",
    number: "5200828282828210",
    expiry_month: 1,
    expiry_year: 2018,
    cvc:  "123",
    address_line1: "456 My Street",
    address_city: "Ottawa",
    address_postcode: "K1C2N6",
    address_state: "ON",
    address_country: "CA"
  }

  @invalid_card %{
    name: "John Doe",
    number: "5200828282828210",
    expiry_month: 1,
    expiry_year: 2010,
    cvc:  "123",
    address_line1: "456 My Street",
    address_city: "Ottawa",
    address_postcode: "K1C2N6",
    address_state: "ON",
    address_country: "CA"
  }

  @amount 100
  @bad_amount 20

  @currency "USD"
  @email "john@trexle.com"
  @ip_address "66.249.79.118"
  @description "Store Purchase 1437598192"

  @opts [
    config: %{api_key: "J5RGMpDlFlTfv9mEFvNWYoqHufyukPP4"}
  ]

  describe "purchase" do
    test "test_for_purchase_with_valid_card" do
      with_mock HTTPoison, 
        [request: fn(_method, _url, _body, _headers,_options) -> MockResponse.valid_card_purchase_response end] do
          {:ok, response} = Trexle.purchase(@amount, @valid_card, @opts)
          assert response.status_code == 201
      end
    end
  

    test "test_for_purchase_with_invalid_card" do
      with_mock HTTPoison,
      [request: fn(_method, _url, _body, _headers, _options) -> MockResponse.invalid_card_purchase_response end] do
        {:ok, response} = Trexle.purchase(@amount, @invalid_card, @opts)  
        assert response.status_code == 400
      end
    end
  end 

end