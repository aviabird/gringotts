defmodule Gringotts.Gateways.StripeTest do
  use ExUnit.Case

  alias Gringotts.{Address, CreditCard, Response}
  alias Gringotts.Gateways.Stripe

  # @moduletag integration: true

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

  @card_token "tok_visa"
  @card_payent_method_3d "pm_card_authenticationRequiredOnSetup"

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
  @present_opts [
    description: "best purchase ever",
    receipt_email: "something@example.com",
    # return_url: "http://localhost:5000/api/3ds2"
  ]

  describe "authorize/3" do
    test "with correct params" do
      opts = @required_opts ++ @optional_opts
      {:ok, %Response{} = response} = Stripe.authorize(@amount, @card_token, opts)
      assert not is_nil(response.id)
      assert String.starts_with?(response.id, "ch_")
      assert String.contains?(response.raw, "\"amount\": 500")
      assert String.contains?(response.raw, "\"amount_captured\": 0")
      assert String.contains?(response.raw, "\"captured\": false")
      assert String.contains?(response.raw, "\"currency\": \"usd\"")
    end
  end

  describe "3D Secure purchase/3" do
    test "it creates a payment intent and waits for card auth" do
      opts = @required_opts ++ @optional_opts ++ @present_opts
      {:ok, %Response{} = response} = Stripe.purchase(@amount, @card_payent_method_3d, opts)
      assert not is_nil(response.id)
      assert String.starts_with?(response.id, "pi_")
      assert response.message == nil
      assert response.reason == "requires_source_action"
      assert response.fraud_review == nil
      assert String.contains?(response.raw, "\"amount\": 500")
      assert String.contains?(response.raw, "\"amount_capturable\": 0")
      assert String.contains?(response.raw, "\"confirmation_method\": \"manual\"")
      assert String.contains?(response.raw, "\"currency\": \"usd\"")
    end

    test "without card auth does not confirm the payment intent" do
      opts = @required_opts ++ @optional_opts ++ @present_opts
      {:ok, %Response{} = response} = Stripe.purchase(@amount, @card_payent_method_3d, opts)
      assert not is_nil(response.id)
      assert String.starts_with?(response.id, "pi_")
      {:ok, %Response{} = confirm_response} = Stripe.purchase(@amount, response.id, opts)
      assert confirm_response.reason == "requires_source_action"
      assert confirm_response.message == nil
    end
  end

  describe "purchase/3" do
    test "with correct params" do
      opts = @required_opts ++ @optional_opts
      {:ok, %Response{} = response} = Stripe.purchase(@amount, @card_token, opts)
      assert not is_nil(response.id)
      assert String.starts_with?(response.id, "ch_")
      assert response.message == nil
      assert response.fraud_review == "normal"
      assert String.contains?(response.raw, "\"amount\": 500")
      assert String.contains?(response.raw, "\"amount_captured\": 500")
      assert String.contains?(response.raw, "\"captured\": true")
      assert String.contains?(response.raw, "\"currency\": \"usd\"")
    end

    test "with additional options" do
      opts = @required_opts ++ @optional_opts ++ @present_opts
      {:ok, %Response{} = response} = Stripe.purchase(@amount, @card_token, opts)
      assert not is_nil(response.id)
      assert String.starts_with?(response.id, "ch_")
      assert response.message == "best purchase ever"
      assert response.fraud_review == "normal"
      assert String.contains?(response.raw, "\"amount\": 500")
      assert String.contains?(response.raw, "\"amount_captured\": 500")
      assert String.contains?(response.raw, "\"captured\": true")
      assert String.contains?(response.raw, "\"currency\": \"usd\"")
      assert String.contains?(response.raw, "\"receipt_email\": \"something@example.com\"")
    end
  end

  describe "refund/3" do
    test "with correct params" do
      opts = @required_opts ++ @optional_opts
      {:ok, %Response{} = response} = Stripe.purchase(@amount, @card_token, opts)
      assert not is_nil(response.id)
      assert String.starts_with?(response.id, "ch_")
      {:ok, %Response{} = refund_response} = Stripe.refund(@amount, response.id, @required_opts)
      assert not is_nil(refund_response.id)
      assert String.starts_with?(refund_response.id, "re_")
      assert String.contains?(refund_response.raw, "\"amount\": 500")
      assert String.contains?(refund_response.raw, "\"charge\": \"#{response.id}\"")
    end
  end
end
