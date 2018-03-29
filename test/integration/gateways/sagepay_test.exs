defmodule Gringotts.Integration.Gateways.SagePayTest do
  use ExUnit.Case, async: true

  alias Gringotts.Gateways.SagePay
  alias Gringotts.{CreditCard, Response}

  use ExVCR.Mock, adapter: ExVCR.Adapter.Hackney
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

  @amount Money.new(100, :GBP)

  @bad_card %CreditCard{
    number: "4929000005559",
    month: 3,
    year: 20,
    first_name: "SAM",
    last_name: "JONES",
    verification_code: "123",
    brand: "VISA"
  }

  @address %{
    street1: "407 St.",
    street2: "John Street",
    city: "London",
    postal_code: "EC1V 4AB",
    country: "GB"
  }

  @opts [
    config: %{
      auth_id:
        "aEpZeHN3N0hMYmo0MGNCOHVkRVM4Q0RSRkxodUo4RzU0TzZyRHBVWHZFNmhZRHJyaWE6bzJpSFNyRnliWU1acG1XT1FNdWhzWFA1MlY0ZkJ0cHVTRHNocktEU1dzQlkxT2lONmh3ZDlLYjEyejRqNVVzNXU=",
      merchant_name: "sandbox"
    },
    transaction_type: "Deferred",
    description: "Demo Payment",
    customer_first_name: "Sam",
    customer_last_name: "Jones",
    billing_address: @address
  ]

  @bad_opts [
    config: %{
      auth_id:
        "aEpZeHN3N0hMYmo0MGNCOHVkRVM4Q0RSRkxodUo4RzU0TzZyRHBVWHZFNmhZRHJyaWE6bzJpSFNyRnliWU1acG1XT1FNdWhzWFA1MlY0ZkJ0cHVTRHNocktEU1dzQlkxT2lONmh3ZDlLYjEyejRqNVVzNXU=",
      merchant_name: "sandbox"
    },
    transaction_type: "Deferred",
    vendor_tx_code: "demotransaction-20",
    description: "Demo Payment",
    customer_first_name: "Sam",
    customer_last_name: "Jones",
    billing_address: @address
  ]

  @payment_id "T6569400-1516-0A3F-E3FA-7F222CC79221"

  setup do
    random_code = Enum.random(1_000_000..10_000_000000000000) |> Integer.to_string()
    {:ok, opts: [vendor_tx_code: "demotransaction-" <> random_code] ++ @opts}
  end

  describe "authorize" do
    test "successful response with valid params", %{opts: opts} do
      use_cassette "SagePay/authorize_with_valid_params" do
        assert {:ok, response} = SagePay.authorize(@amount, @card, opts)
      end
    end

    test "successful response with right params", %{opts: opts} do
      use_cassette "SagePay/authorize_with_right_params" do
        assert {:ok, response} = SagePay.authorize(@amount, @card, opts)
      end
    end

    test "successful response message from authorize function", %{opts: opts} do
      use_cassette "SagePay/authorize_with_successful_response" do
        {:ok, response} = SagePay.authorize(@amount, @card, opts)
        assert response.message == "The Authorisation was Successful."
      end
    end

    test "unsuccessful response with invalid params" do
      use_cassette "SagePay/authorize_with_unsuccessful_response" do
        {:error, response} = SagePay.authorize(@amount, @card, @bad_opts)
        refute response.message == "The Authorisation was Successful."
      end
    end

    test "merchant_session_key", %{opts: opts} do
      use_cassette "SagePay/authorize_with_merchant_session_key" do
        {:ok, response} = SagePay.authorize(@amount, @card, opts)
        assert is_binary(response.id)
      end
    end
  end
end
