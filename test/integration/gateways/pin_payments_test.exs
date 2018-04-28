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
          config: [api_key: "c4nxgznanW4XZUaEQhxS6g"]
        ] ++ [address: @add]

  # Group the test cases by public api
  describe "purchase" do
    test "[purchase] with CreditCard" do
      use_cassette "pin_pay/purchase_with_credit_card" do
        assert {:ok, response} = Gateway.purchase(@amount, @good_card, @opts)
        assert response.success == true
        assert response.status_code == 201
      end
    end

    test "[purchase] with bad CreditCard 1" do
      use_cassette "pin_pay/purchase_with_bad_credit_card1" do
        assert {:error, response} = Gateway.purchase(@amount, @bad_card1, @opts)
        assert response.success == false
        assert response.status_code == 400
      end
    end

    test "[purchase] with bad CreditCard 2" do
      use_cassette "pin_pay/purchase_with_bad_credit_card2" do
        assert {:error, response} = Gateway.purchase(@amount, @bad_card2, @opts)
        assert response.success == false
        assert response.status_code == 400
      end
    end

    test "[purchase] with bad CreditCard 3" do
      use_cassette "pin_pay/purchase_with_bad_credit_card3" do
        assert {:error, response} = Gateway.purchase(@amount, @bad_card3, @opts)
        assert response.success == false
        assert response.status_code == 422
      end
    end

    test "[purchase] with card_token" do
      use_cassette "pin_pay/purchase_with_card_token" do
        assert {:ok, response} = Gateway.store(@good_card, @opts)
        assert response.success == true
        assert response.status_code == 201
        card_token = response.token
        assert {:ok, response} = Gateway.purchase(@amount, card_token, @opts)
      end
    end
  end

  describe "Refunds" do
    test "[Refunds]" do
       use_cassette "pin_pay/refunds" do
      assert {:ok, response} = Gateway.purchase(@amount, @good_card, @opts)
      assert response.success == true
      assert response.status_code == 201
      payment_id = response.id
      assert {:ok, response} = Gateway.refund(payment_id, @opts)
      assert response.success == true
      assert response.status_code == 201
       end
    end
  end
end
