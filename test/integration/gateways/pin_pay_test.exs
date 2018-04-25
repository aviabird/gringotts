defmodule Gringotts.Integration.Gateways.PinPaymentsTest do
  # Integration tests for the Pinpayments 

  use ExUnit.Case, async: true

  alias Gringotts.{
    CreditCard,
    Address
  }

  alias Gringotts.Gateways.PinPayments, as: Gateway

  @moduletag :integration

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

  @good_card %CreditCard{
    first_name: "Harry",
    last_name: "Potter",
    number: "4200000000000000",
    year: 2029,
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
          config: %{apiKey: "c4nxgznanW4XZUaEQhxS6g"}
        ] ++ [address: @add]

  test "[authorize] with CreditCard" do
    assert {:ok, response} = Gateway.authorize(@amount, @good_card, @opts)
    assert response.success == true
    assert response.status_code == 201
  end

  test "[authorize] with bad CreditCard 1" do
    assert {:error, response} = Gateway.authorize(@amount, @bad_card1, @opts)
    assert response.success == false
    assert response.status_code == 400
  end
end
