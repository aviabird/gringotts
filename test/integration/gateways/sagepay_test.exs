defmodule Gringotts.Integration.Gateways.SagePayTest do
  use ExUnit.Case, async: true
  alias Gringotts.Gateways.SagePay
  alias Gringotts.{CreditCard, Response}

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
    address1: "407 St. John Street",
    city: "London",
    postalCode: "EC1V 4AB",
    country: "GB"
  }

  @opts [
    config: %{
      auth_id:
        "aEpZeHN3N0hMYmo0MGNCOHVkRVM4Q0RSRkxodUo4RzU0TzZyRHBVWHZFNmhZRHJyaWE6bzJpSFNyRnliWU1acG1XT1FNdWhzWFA1MlY0ZkJ0cHVTRHNocktEU1dzQlkxT2lONmh3ZDlLYjEyejRqNVVzNXU=",
      vendor: "sandbox"
    },
    transactionType: "Deferred",
    description: "Demo Payment",
    customerFirstName: "Sam",
    customerLastName: "Jones",
    billingAddress: @address
  ]

  @bad_opts [
    config: %{
      auth_id:
        "aEpZeHN3N0hMYmo0MGNCOHVkRVM4Q0RSRkxodUo4RzU0TzZyRHBVWHZFNmhZRHJyaWE6bzJpSFNyRnliWU1acG1XT1FNdWhzWFA1MlY0ZkJ0cHVTRHNocktEU1dzQlkxT2lONmh3ZDlLYjEyejRqNVVzNXU=",
      vendor: "sandbox"
    },
    transactionType: "Deferred",
    vendorTxCode: "demotransaction-20",
    description: "Demo Payment",
    customerFirstName: "Sam",
    customerLastName: "Jones",
    billingAddress: @address
  ]

  @payment_id "T6569400-1516-0A3F-E3FA-7F222CC79221"

  @moduletag :integration

  setup_all do
    Application.put_env(:gringotts, Gringotts.Gateways.Sagepay, [])
  end

  setup do
    random_code = Enum.random(1_000_000..10_000_000000000000) |> Integer.to_string()
    {:ok, opts: [vendorTxCode: "demotransaction-" <> random_code] ++ @opts}
  end

  describe "purchase" do
  end

  describe "authorize" do
    test "successful response with valid params", %{opts: opts} do
      assert {:ok, response} = SagePay.authorize(@amount, @card, opts)
    end

    test "successful response with right params", %{opts: opts} do
      assert {:ok, response} = SagePay.authorize(@amount, @card, opts)
    end

    test "successful response message from authorize function", %{opts: opts} do
      {:ok, response} = SagePay.authorize(@amount, @card, opts)
      assert response.message == "The Authorisation was Successful."
    end

    test "unsuccessful response with invalid params" do
      {:error, response} = SagePay.authorize(@amount, @card, @bad_opts)
      refute response.message == "The Authorisation was Successful."
    end

    test "merchant_session_key", %{opts: opts} do
      {:ok, response} = SagePay.authorize(@amount, @card, opts)
      assert is_binary(response.id)
    end
  end

  describe "capture" do
  end

  describe "void" do
  end

  describe "refund" do
  end

  describe "environment setup" do
  end
end
