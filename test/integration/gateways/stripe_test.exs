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
  @present_opts [description: "best purchase ever", receipt_email: "something@example.com"]

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
