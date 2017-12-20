defmodule Gringotts.Gateways.StripeTest do

  use ExUnit.Case

  alias Gringotts.Gateways.Stripe

  @required_payment_attrs %{
    month: 12,
    year: 2018,
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

  @config [config: [api_key: "sk_test_vIX41hayC0BKrPWQerLuOMld"]]
  @required_opts [currency: "usd"]

  describe "authorize/3" do
    test "should authorize wth required payment and required opts attrs" do
      amount = 5
      response = Stripe.authorize(amount, @required_payment_attrs, @config ++ @required_opts)

      assert Map.has_key?(response, "id")
      assert response["amount"] == 500
      assert response["captured"] == false
      assert response["currency"] == "usd"
    end

    test "should not authorize if required payment attrs not present" do
      amount = 5
      response = Stripe.authorize(amount, @optional_payment_attrs, @config ++ @required_opts)

      assert Map.has_key?(response, "error")
    end

    test "should not authorize if required opts not present" do
      amount = 5
      response = Stripe.authorize(amount, @required_payment_attrs, @config)

      assert Map.has_key?(response, "error")
    end

  end
end
