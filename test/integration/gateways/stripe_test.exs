defmodule Gringotts.Gateways.StripeTest do
  use ExUnit.Case

  alias Gringotts.{Address, CreditCard}
  alias Gringotts.Gateways.Stripe

  @moduletag integration: true

  @amount Gringotts.FakeMoney.new(5, :USD)
  @card %CreditCard{
    first_name: "John",
    last_name: "Smith",
    number: "4242424242424242",
    # Can't be more than 50 years in the future, Haha.
    year: "2068",
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

  @required_opts [config: [secret_key: "sk_test_vIX41hayC0BKrPWQerLuOMld"]]
  @optional_opts [address: @address]

  describe "authorize/3" do
    test "with correct params" do
      response = Stripe.authorize(@amount, @card, @required_opts ++ @optional_opts)
      assert Map.has_key?(response, "id")
      assert response["amount"] == 500
      assert response["captured"] == false
      assert response["currency"] == "usd"
    end
  end
end
