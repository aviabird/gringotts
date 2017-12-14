defmodule Kuber.Hex.Gateways.StripeTest do

  use ExUnit.Case

  alias Kuber.Hex.Gateways.Stripe

  @required_payment_attrs %{
    expiration: {2018, 12},
    number: "4242424242424242",
    cvc:  "123"
  }

  @optional_payment_attrs %{
    name: "John Doe",
    street1: "123 Main",
    street2: "Suite 100",
    city: "New York",
    region: "NY",
    country: "US",
    postal_code: "11111"
  }

  @required_opts [currency: "usd"]


  describe "authorize/3" do
    test "should authorize wth required payment and required opts attrs" do
      amount = 5
      response = Stripe.authorize(amount, @required_payment_attrs, @required_opts)

      assert Map.has_key?(response, "id")
      assert response["amount"] == 500
      assert response["captured"] == false
      assert response["currency"] == "usd"
    end

    test "should not authorize if required payment attrs not present" do
      amount = 5
      response = Stripe.authorize(amount, @optional_payment_attrs, @required_opts)

      assert Map.has_key?(response, "error")
    end

    test "should not authorize if required opts not present" do
      amount = 5
      response = Stripe.authorize(amount, @required_payment_attrs)

      assert Map.has_key?(response, "error")
    end

  end
end
