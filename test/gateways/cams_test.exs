defmodule Gringotts.Gateways.CamsTest do
  use ExUnit.Case
	alias Gringotts.{
    CreditCard, Response
  }
	alias Gringotts.Gateways.Cams, as: Gateway
  
  @payment %{
    number: "4111111111111111",
    month: 9,
    year: 2018,
    first_name: "Gopal",
    last_name: "Shimpi",
    verification_code: "123",
    brand: "visa"
  }

  @bad_payment %{
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
    order_id: :rand.uniform(99999),
    billing_address: @address,
    description: "Store Purchase",
  ]
  @money :rand.uniform(9999)

  describe "purchase" do
    test "test_sucessful_purchase" do
      {:ok, response} = Gateway.purchase(@money + 1, @payment, @options)
      result = URI.decode_query(response)
      assert result["responsetext"] == "SUCCESS" 
    end

    test "test_duplicate_purchase" do
      {:ok, response} = Gateway.purchase(@money + 1, @payment, @options)
      result = URI.decode_query(response)
      assert String.contains?(result["responsetext"], "Duplicate order")
    end
  
    test "test_failed_purchase" do
      {:ok, response} = Gateway.purchase(@money, @bad_payment, @options)
      result = URI.decode_query(response)
      assert String.contains?(result["responsetext"], "Invalid Credit Card Number") 
    end
  end
  describe "authorize" do
    test "test_successful_authorize_and_capture" do
      {:ok, response} = Gateway.authorize(@money, @payment, @options)
      result = URI.decode_query(response)
      assert result["responsetext"] == "SUCCESS" 

      {:ok, capture_resp} = Gateway.capture(@money, response, @options)
      result = URI.decode_query(response)
      assert result["responsetext"] == "SUCCESS" 
    end

    test "test_failed_authorize" do
      {:ok, response} = Gateway.authorize(@money, @bad_payment, @options)
      result = URI.decode_query(response)
      assert String.contains?(result["responsetext"], "Invalid Credit Card Number") 
    end

    test "test_partial_capture" do
      {:ok, response} = Gateway.authorize(@money + 5, @payment, @options)
      result = URI.decode_query(response)
      assert result["responsetext"] == "SUCCESS" 

      {:ok, capture_resp} = Gateway.capture(@money - 1, response, @options)
      result = URI.decode_query(response)
      assert result["responsetext"] == "SUCCESS" 
    end
  end
end