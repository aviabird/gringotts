defmodule Gringotts.Integration.Gateways.SecurionPayTest do
  use ExUnit.Case, async: true
  use ExVCR.Mock, adapter: ExVCR.Adapter.Hackney

  alias Gringotts.{
    CreditCard
  }

  alias Gringotts.Gateways.SecurionPay, as: Gateway

  @moduletag integration: false

  @amount Money.new(42, :EUR)

  @bad_card %CreditCard{
    first_name: "Harry",
    last_name: "Potter",
    number: "4200000000000000",
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

  @opts [
    config: [secret_key: "pr_test_tXHm9qV9qV9bjIRHcQr9PLPa"],
    customer_id: "cust_NxPh6PUq9KWUW8tZKkUnV2Nt"
  ]

  @email_opts [
    config: [secret_key: "pr_test_tXHm9qV9qV9bjIRHcQr9PLPa"],
    email: "customer@example.com"
  ]

  @bad_opts [config: [secret_key: "pr_test_tXHm9qV9qV9bjIRHcQr9PLPa"]]

  @card_id "card_wVuO1a5BGM12UV10FwpkK9YW"
  @bad_charge_id "char_wVuO1a5BGM12UV10FwpkK9YW"

  describe "[authorize]" do
    test "with CreditCard" do
      use_cassette "securion_pay/authorize_with_credit_card" do
        assert {:ok, response} = Gateway.authorize(@amount, @good_card, @opts)
        assert response.success == true
        assert response.status_code == 200
      end
    end

    test "with card_id and customer_id" do
      use_cassette "securion_pay/authorize_with_card_id" do
        assert {:ok, response} = Gateway.authorize(@amount, @card_id, @opts)
        assert response.success == true
        assert response.status_code == 200
      end
    end

    test "with expired CreditCard" do
      use_cassette "securion_pay/authorize_with_expired_card" do
        assert {:error, response} = Gateway.authorize(@amount, @bad_card, @opts)
        assert response.success == false
        refute response.status_code == 200
        assert response.message == "card_error"
        assert response.reason == "The card has expired."
      end
    end

    test "with card_id but no customer_id" do
      use_cassette "securion_pay/authorize_without_customer_id" do
        assert {:error, response} = Gateway.authorize(@amount, @card_id, @bad_opts)
        assert response.success == false
        refute response.status_code == 200
        assert response.message == "invalid_request"
      end
    end
  end

  describe "[capture]" do
    test "with_authorized_payment_id" do
      use_cassette "securion_pay/capture_after_authorization" do
        {:ok, auth_response} = Gateway.authorize(@amount, @good_card, @opts)
        assert {:ok, capt_response} = Gateway.capture(auth_response.id, @amount, @opts)
        assert capt_response.success == true
        assert capt_response.status_code == 200
      end
    end

    test "with_invalid_payment_id" do
      use_cassette "securion_pay/capture_with_invalid_payment_id" do
        assert {:error, response} = Gateway.capture(@bad_charge_id, @amount, @opts)
        assert response.success == false
        refute response.status_code == 200
        assert response.message == "invalid_request"
        assert response.reason == "Charge '#{@bad_charge_id}' does not exist"
      end
    end
  end

  describe "[store]" do
    test "with_customer_id" do
      use_cassette "securion_pay/with_customer_id" do
        {:ok, response} = Gateway.store(@good_card, @opts)
        assert response.success == true
        assert response.status_code == 200
      end
    end

    test "with expired CreditCard" do
      use_cassette "securion_pay/store_with_expired_card" do
        assert {:error, response} = Gateway.store(@bad_card, @opts)
        assert response.success == false
        refute response.status_code == 200
        assert response.message == "card_error"
        assert response.reason == "The card has expired."
      end
    end

    test "without_customer_id" do
      use_cassette "securion_pay/without_customer_id" do
        {:ok, response} = Gateway.store(@good_card, @email_opts)
        assert response.success == true
        assert response.status_code == 200
      end
    end
  end
end
