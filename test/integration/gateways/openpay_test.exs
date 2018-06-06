defmodule Gringotts.Integration.Gateways.OpenpayTest do
  # Integration tests for the Openpay

  use ExUnit.Case, async: true
  use ExVCR.Mock, adapter: ExVCR.Adapter.Hackney
  alias Gringotts.Gateways.Openpay, as: Gateway
   alias Gringotts.{
    CreditCard
  }

  @moduletag integration: false

  @amount Money.new(4, :MXN)

  @goodcard %CreditCard{
    first_name: "Aashish",
    last_name: "singh",
    number: "4111111111111111",
    year: 20,
    month: 7,
    verification_code: "123",
    brand: "VISA"
  }

  @badcard %Gringotts.CreditCard{
    first_name: "Aashish",
    last_name: "singh",
    number: "4111111111111111",
    year: 17,
    month: 7,
    verification_code: "123",
    brand: "VISA"
  }
  address = %{
      city: "Gryfindor",
      country_code: "MX",
      postal_code: "76900",
      line1: "Hall",
      line2: "Room",
      line3: "Bed 11",
      state: "Dark Arts"
   }

  @opts [
    address: address,
    method: "card",
    email: "aashish01@singh.com",
    device_session_id: "kR1MiQhz2otdIuUlQkbEyitIqVMiI16f",
    phone_number: "1111111111",
    config: [
        merchant_id: "mrqxvkwxdxncftvrwjix",
        public_key: "pk_be3cc6965b0746978da91975e72fe194"
      ]
  ]

  # Group the test cases by public api
  describe "authorize" do
    test "good card authorize" do
      use_cassette "xx" do
        assert {:ok, response} = Gateway.authorize(@amount, @goodcard, @opts)
         assert response.success == true
         assert response.status_code == 200
      end
    end
     test "bad card authorize" do
       use_cassette "openpay/authorize bad_card" do
         assert {:error, response} = Gateway.authorize(@amount, @bad_card, @opts)
         assert response.success == false
         assert response.status_code == 400
       end
     end
   end

   describe "capture" do
     test "capture" do
       use_cassette "openpay/authorize good_card" do
         assert {:ok, response} = Gateway.authorize(@amount, @good_card, @opts)
         assert response.success == true
         assert response.status_code == 200
         assert {:ok, response} = Gateway.capture(response.id, @amount, @opts)
         assert response.success == true
         assert response.status_code == 200
       end
     end
   end

   describe "purchase" do
     test "good card purchase" do
       use_cassette "openpay/purchase good_card" do
         assert {:ok, response} = Gateway.purchase(@amount, @good_card, @opts)
         assert response.success == true
         assert response.status_code == 200
       end
     end
     test "bad card purchase" do
       use_cassette "openpay/purchase bad_card" do
         assert {:error, response} = Gateway.purchase(@amount, @bad_card, @opts)
         assert response.success == false
         assert response.status_code == 400
       end
     end
   end

   describe "void" do
     test "Void" do
       use_cassette "openpay/void" do
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

   describe "refund" do
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
