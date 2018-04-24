defmodule Gringotts.Integration.Gateways.SagePayTest do
  use ExUnit.Case, async: true

  alias Gringotts.Gateways.SagePay
  alias Gringotts.{CreditCard, Response, Address}

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

  @address %Address{
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
    description: "Demo Payment",
    customer_first_name: "Sam",
    customer_last_name: "Jones",
    billing_address: @address
  ]

  @opts1 [
    config: %{
      auth_id:
        "aEpZeHN3N0hMYmo0MGNCOHVkRVM4Q0RSRkxodUo4RzU0TzZyRHBVWHZFNmhZRHJyaWE6bzJpSFNyRnliWU1acG1XT1FNdWhzWFA1MlY0ZkJ0cHVTRHNocktEU1dzQlkxT2lONmh3ZDlLYjEyejRqNVVzNXU=",
      merchant_name: "sandbox"
    },
    transaction_type: "release"
  ]

  @opts2 [
    config: %{
      auth_id:
        "aEpZeHN3N0hMYmo0MGNCOHVkRVM4Q0RSRkxodUo4RzU0TzZyRHBVWHZFNmhZRHJyaWE6bzJpSFNyRnliWU1acG1XT1FNdWhzWFA1MlY0ZkJ0cHVTRHNocktEU1dzQlkxT2lONmh3ZDlLYjEyejRqNVVzNXU=",
      merchant_name: "sandbox"
    },
    transaction_type: "Refund",
    description: "Demo Payment"
  ]

  @bad_opts [
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

  @payment_id "T6569400-1516-0A3F-E3FA-7F222CC79221"

  setup do
    random_number1 = Enum.random(1_000_000..10_000_000000000000)

    random_code1 =
      random_number1
      |> Integer.to_string()

    opts_authoriize = [vendor_tx_code: "demoo-" <> random_code1] ++ @opts

    random_number2 = Enum.random(1_000_000..10_000_000000000000)

    random_code2 =
      random_number2
      |> Integer.to_string()

    opts_refund = [vendor_tx_code: "demoo-" <> random_code2] ++ @opts2

    {:ok, opts: [opts_authoriize: opts_authoriize, opts_refund: opts_refund]}
  end

  describe "authorize" do
    test "successful response with valid params", %{opts: opts} do
      use_cassette "sagepay/successful response with valid params" do
        opts_authoriize = opts[:opts_authoriize] ++ [transaction_type: "Deferred"]
        assert {:ok, _} = SagePay.authorize(@amount, @card, opts_authoriize)
      end
    end

    test "successful response message from authorize function", %{opts: opts} do
      use_cassette "sagepay/successful response message from authorize function" do
        opts_authoriize = opts[:opts_authoriize] ++ [transaction_type: "Payment"]
        {:ok, response} = SagePay.authorize(@amount, @card, opts_authoriize)

        assert response.message == "The Authorisation was Successful."
      end
    end

    test "unsuccessful response with invalid params" do
      use_cassette "sagepay/unsuccessful response with invalid params" do
        {:error, response} = SagePay.authorize(@amount, @card, @bad_opts)

        refute response.message == "The Authorisation was Successful."
      end
    end

    test "merchant_session_key", %{opts: opts} do
      use_cassette "sagepay/merchant_session_key" do
        opts_authoriize = opts[:opts_authoriize] ++ [transaction_type: "Payment"]
        {:ok, response} = SagePay.authorize(@amount, @card, opts_authoriize)

        assert is_binary(response.id)
      end
    end
  end
end
