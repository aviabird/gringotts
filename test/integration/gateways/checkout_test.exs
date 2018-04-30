defmodule Gringotts.Integration.Gateways.CheckoutTest do
  # Integration tests for the Checkout
  use ExUnit.Case, async: false
  use ExVCR.Mock, adapter: ExVCR.Adapter.Hackney
  alias Gringotts.Gateways.Checkout

  alias Gringotts.{
    CreditCard,
    Address
  }

  alias Gringotts.Gateways.Checkout, as: Gateway

  # @moduletag :integration

  @amount Money.new(420, :USD)

  @bad_card1 %CreditCard{
    first_name: "Harry",
    last_name: "Potter",
    number: "4100000000000001",
    year: 2009,
    month: 12,
    verification_code: "123",
    brand: "VISA"
  }

  @good_card %CreditCard{
    number: "4543474002249996",
    month: 06,
    year: 2025,
    first_name: "Harry",
    last_name: " Potter",
    verification_code: "956",
    brand: "VISA"
  }

  @add %Address{
    street1: "OBH",
    street2: "AIT",
    city: "PUNE",
    region: "MH",
    country: "IN",
    postal_code: "411015",
    phone: "8007810916"
  }

  @opts [
    description: "hello",
    email: "hi@hello.com",
    ip_address: "1.1.1.1",
    chargeMode: 1,
    config: [
      secret_key: "sk_test_f3695cf1-4f36-485b-bba9-caa5b5acb028"
    ],
    address: @add
  ]

  describe "authorize" do
    test "[authorize] with good parameters" do
      use_cassette "Checkout/authorize_with_valid_card" do
        assert {:ok, response} = Gateway.authorize(@amount, @good_card, @opts)
        assert response.success == true
        assert response.status_code == 200
      end
    end

    test "[authorize] with bad CreditCard" do
      use_cassette "Checkout/authorize_with_invalid_card" do
        assert {:error, response} = Gateway.authorize(@amount, @bad_card1, @opts)
        assert response.success == false
        assert response.status_code == 400
      end
    end
  end

  describe "purchase" do
    test "[purchase] with good parameters" do
      use_cassette "Checkout/purchase_with_valid_card" do
        assert {:ok, response} = Gateway.purchase(@amount, @good_card, @opts)
        assert response.success == true
        assert response.status_code == 200
      end
    end

    test "[purchase] with bad CreditCard" do
      use_cassette "Checkout/purchase_with_invalid_card" do
        assert {:error, response} = Gateway.purchase(@amount, @bad_card1, @opts)
        assert response.success == false
        assert response.status_code == 400
      end
    end
  end

  describe "capture" do
    test "[Capture]" do
      use_cassette "Checkout/capture" do
        assert {:ok, response} = Gateway.authorize(@amount, @good_card, @opts)
        assert response.success == true
        assert response.status_code == 200
        payment_id = response.id
        assert {:ok, response} = Gateway.capture(payment_id, @amount, @opts)
        assert response.success == true
        assert response.status_code == 200
      end
    end
  end

  describe "Void" do
    test "[Void]" do
      use_cassette "Checkout/void" do
        assert {:ok, response} = Gateway.authorize(@amount, @good_card, @opts)
        assert response.success == true
        assert response.status_code == 200
        payment_id = response.id
        assert {:ok, response} = Gateway.void(payment_id, @opts)
        assert response.success == true
        assert response.status_code == 200
      end
    end
  end

  describe "Refund" do
    test "[Refund]" do
      use_cassette "Checkout/Refund" do
        assert {:ok, response} = Gateway.authorize(@amount, @good_card, @opts)
        assert response.success == true
        assert response.status_code == 200
        payment_id = response.id
        assert {:ok, response} = Gateway.capture(payment_id, @amount, @opts)
        assert response.success == true
        assert response.status_code == 200
        payment_id = response.id
        assert {:ok, response} = Gateway.refund(@amount, payment_id, @opts)
        assert response.success == true
        assert response.status_code == 200
      end
    end
  end
end
