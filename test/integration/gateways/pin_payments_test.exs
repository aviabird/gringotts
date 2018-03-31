defmodule Gringotts.Integration.Gateways.PinPaymentsTest do
  # Integration tests for the PinPayments 

  use ExUnit.Case, async: false
  use ExVCR.Mock, adapter: ExVCR.Adapter.Hackney

  alias Gringotts.{
    CreditCard,
    Address
  }

  alias Gringotts.Gateways.PinPayments, as: Gateway

  #@moduletag :integration

  @amount Money.new(420, :AUD)

  @bad_card1 %CreditCard{
    first_name: "Harry",
    last_name: "Potter",
    number: "4100000000000001",
    year: 2019,
    month: 12,
    verification_code: "123",
    brand: "VISA"
  }

  @bad_card2 %CreditCard{
    first_name: "Harry",
    last_name: "Potter",
    number: "4600000000000006",
    year: 2019,
    month: 12,
    verification_code: "123",
    brand: "VISA"
  }

  @bad_card3 %CreditCard{
    first_name: "Harry",
    last_name: "Potter",
    number: "4600000000000006",
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
    region: "Maharashtra",
    country: "IN",
    postal_code: "411015",
    phone: "8007810916"
  }

  @opts [
          description: "hello",
          email: "hi@hello.com",
          ip_address: "1.1.1.1",
          config: %{apiKey: "c4nxgznanW4XZUaEQhxS6g", pass: ""}
        ] ++ [address: @add]

  
  describe "capture" do
    test "[Capture]" do
      use_cassette "pin_pay/capture" do
        assert {:ok, response} = Gateway.authorize(@amount, @good_card, @opts)
        assert response.success == true
        assert response.status_code == 201
        payment_id = response.token
        assert {:ok, response} = Gateway.capture(payment_id, @amount, @opts)
        assert response.success == true
        assert response.status_code == 201
      end
    end
  end
end
