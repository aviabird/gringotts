defmodule Gringotts.Gateways.StripeTest do

  use ExUnit.Case

  alias Gringotts.Gateways.Stripe
  alias Gringotts.{
    CreditCard,
    Address
  }

  @card %CreditCard{
    first_name: "John",
    last_name: "Smith",
    number: "4242424242424242",
    year: "2017",
    month: "12",
    verification_code: "123"
  }

  @address %Address{
    street1: "123 Main",
    street2: "Suite 100",
    city: "New York",
    region: "NY",
    country: "US",
    postal_code: "11111"
  }

  @required_opts [config: [api_key: "sk_test_vIX41hayC0BKrPWQerLuOMld"], currency: "usd"]
  @optional_opts [address: @address]

  describe "authorize/3" do
    test "should authorize wth card and required opts attrs" do
      amount = 5
      response = Stripe.authorize(amount, @card, @required_opts ++ @optional_opts)

      assert Map.has_key?(response, "id")
      assert response["amount"] == 500
      assert response["captured"] == false
      assert response["currency"] == "usd"
    end

    test "should not authorize if card is not passed" do
      amount = 5
      response = Stripe.authorize(amount, %{}, @required_opts ++ @optional_opts)

      assert Map.has_key?(response, "error")
    end

    # test "should not authorize if required opts not present" do
    #   amount = 5
    #   response = Stripe.authorize(amount, @card, @optional_opts)

    #   assert Map.has_key?(response, "error")
    # end

  end
end
