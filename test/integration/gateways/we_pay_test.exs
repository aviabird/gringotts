defmodule Gringotts.Integration.Gateways.WePayTest do
  # Integration tests for the WePay 

  use ExUnit.Case, async: true
  use ExVCR.Mock, adapter: ExVCR.Adapter.Hackney
  alias Gringotts.Gateways.WePay

  alias Gringotts.{
    Address,
    CreditCard,
    FakeMoney
  }

  alias Gringotts.Gateways.WePay, as: Gateway

  # @moduletag :integration

  @amount FakeMoney.new(5, :USD)

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
    first_name: "Harry",
    last_name: "Potter",
    number: "4200000000000000",
    year: 2019,
    month: 12,
    verification_code: "123",
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
    email: "hi@hello.com",
    original_ip: "1.1.1.1",
    short_description: "test payment",
    type: "service",
    refund_reason: "the product was defective",
    cancel_reason: "the product was defective, i don't want",
    config: [
      client_id: 134_871,
      client_secret: "81dbb22c9b",
      account_id: 1_155_820_743,
      access_token: "STAGE_3286b628c1cb7630e75402e95ecebd53e0c4fc86c71685c1a3a05ac5c5cb5aae"
    ],
    address: @add
  ]

  describe "store" do
    test "[Store] with CreditCard" do
      use_cassette "WePay/store_with_valid_card" do
        assert {:ok, response} = Gateway.store(@good_card, @opts)
        refute response.token == nil
        assert response.status_code == 200
      end
    end

    test "[Store] with bad CreditCard" do
      use_cassette "WePay/store_with_invalid_card" do
        assert {:error, response} = Gateway.store(@bad_card1, @opts)
        assert response.token == nil
        assert response.status_code == 400
      end
    end
  end

  describe "authorize" do
    test "[authorize] with good parameters" do
      use_cassette "WePay/authorize_with_valid_card" do
        assert {:ok, response} = Gateway.authorize(@amount, @good_card, @opts)
        assert response.status_code == 200
      end
    end

    test "[authorize] with bad CreditCard" do
      use_cassette "WePay/authorize_with_invalid_card" do
        assert {:error, response} = Gateway.authorize(@amount, @bad_card1, @opts)
        assert response.status_code == 400
      end
    end
  end

  describe "purchase" do
    test "[purchase] with good parameters" do
      use_cassette "WePay/purchase_with_valid_card" do
        assert {:ok, response} = Gateway.purchase(@amount, @good_card, @opts)
        assert response.status_code == 200
      end
    end

    test "[purchase] with bad CreditCard" do
      use_cassette "WePay/purchase_with_invalid_card" do
        assert {:error, response} = Gateway.purchase(@amount, @bad_card1, @opts)
        assert response.status_code == 400
      end
    end
  end

  describe "capture" do
    test "[Capture]" do
      use_cassette "WePay/capture" do
        assert {:ok, response} = Gateway.authorize(@amount, @good_card, @opts)
        assert response.status_code == 200
        payment_id = response.id
        assert {:ok, response} = Gateway.capture(payment_id, @amount, @opts)
        assert response.status_code == 200
      end
    end
  end

  describe "Void" do
    test "[Void] after authorize" do
      use_cassette "WePay/void_after_authorize" do
        assert {:ok, response} = Gateway.authorize(@amount, @good_card, @opts)
        assert response.status_code == 200
        payment_id = response.id
        assert {:ok, response} = Gateway.void(payment_id, @opts)
        assert response.status_code == 200
      end
    end

    test "[Void] after capture" do
      use_cassette "WePay/void_after_capture" do
        assert {:ok, response} = Gateway.authorize(@amount, @good_card, @opts)
        assert response.status_code == 200
        payment_id = response.id
        assert {:ok, response} = Gateway.capture(payment_id, @amount, @opts)
        assert response.status_code == 200
        payment_id = response.id
        assert {:ok, response} = Gateway.void(payment_id, @opts)
        assert response.status_code == 200
      end
    end
  end

  describe "Unstore" do
    test "[Unstore]" do
      use_cassette "WePay/unstore" do
        assert {:ok, response} = Gateway.store(@good_card, @opts)
        assert response.status_code == 200
        payment_id = response.token
        assert {:ok, response} = Gateway.unstore(payment_id, @opts)
        assert response.status_code == 200
      end
    end
  end
end
