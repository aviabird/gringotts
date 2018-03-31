defmodule Gringotts.Integration.Gateways.SagePayTest do
  use ExUnit.Case, async: true
  use ExVCR.Mock, adapter: ExVCR.Adapter.Hackney

  alias Gringotts.{Address, CreditCard}

  alias Gringotts.Gateways.SagePay

  @moduletag integration: true

  @card %CreditCard{
    number: "4484000000002",
    month: 3,
    year: 20,
    first_name: "SAM",
    last_name: "JONES",
    verification_code: "123",
    brand: "VISA"
  }

  @amount Gringotts.FakeMoney.new(100, :GBP)

  @address %Address{
    street1: "407 St.",
    street2: "John Street",
    city: "London",
    postal_code: "EC1V 4AB",
    country: "GB"
  }

  @config [
    auth_id:
      "aEpZeHN3N0hMYmo0MGNCOHVkRVM4Q0RSRkxodUo4RzU0TzZyRHBVWHZFNmhZRHJyaWE6bzJpSFNyRnliWU1acG1XT1FNdWhzWFA1MlY0ZkJ0cHVTRHNocktEU1dzQlkxT2lONmh3ZDlLYjEyejRqNVVzNXU=",
    merchant_name: "sandbox"
  ]

  @opts [
    config: @config,
    description: "Demo Payment",
    first_name: "Sam",
    last_name: "Jones",
    billing_address: @address
  ]

  setup do
    [opts: [{:vendor_tx_code, "demo#{System.unique_integer()}"} | @opts]]
  end

  describe "authorize" do
    test "with valid params", %{opts: opts, test: name} do
      use_cassette "sagepay/#{name}" do
        {:ok, response} = SagePay.authorize(@amount, @card, opts)

        assert response.message == "The Authorisation was Successful."
        assert {card_id, _expiry_time} = response.tokens[:card_id]
        assert card_id =~ ~r/[A-Z\-0-9]{36}/
        assert response.gateway_code == "0000"
      end
    end

    test "with invalid params returns session-key", %{opts: opts, test: name} do
      use_cassette "sagepay/#{name}" do
        {:error, response} = SagePay.authorize(@amount, %{@card | number: "0"}, opts)
        assert {session_key, _expiry_time} = response.tokens[:session_key]
        assert session_key =~ ~r/[A-Z\-0-9]{36}/
      end
    end
  end

  describe "capture" do
    test "with valid params", %{opts: opts, test: name} do
      use_cassette "sagepay/#{name}" do
        assert {:ok, response} = SagePay.authorize(@amount, @card, opts)
        assert {:ok, _} = SagePay.capture(response.id, @amount, config: @config)
      end
    end
  end
end
