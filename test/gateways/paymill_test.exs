defmodule Gringotts.Gateways.PaymillTest do
  use ExUnit.Case, async: false

  alias Gringotts.{CreditCard, Response}
  alias Gringotts.Gateways.Paymill

  import Mock

  @valid_card %CreditCard{
    first_name: "Sagar",
    last_name: "Karwande",
    number: "4111111111111111",
    month: 12,
    year: 2018,
    verification_code: 123
  }

  @invalid_card %CreditCard{
    first_name: "Sagar",
    last_name: "Karwande",
    number: "5105105105105100",
    month: 12,
    year: 2018,
    verification_code: 123
  }

  @options [
    config: [
      private_key: "8f16b021d4fb1f8d9263cbe346f32688",
      public_key: "72294854039fcf7fd55eaeeb594577e7"
    ]
  ]

  describe "authorize/3" do
    test "with valid card details" do
    end
    test "with invalid cvv details" do
    end
    test "with invalid card token" do
    end
    test "with blacklisted card" do
    end
    test "with blacklisted account" do
    end
    test "with inlid authorization" do
    end
    test "with currency or amount mismatch" do
    end
    test "with card restricted by bank" do
    end
    test "with duplicate transaction" do
    end
    test "with blacklisted ip" do
    end
    test "with missing parameters" do
    end
  end

  describe "capture/3" do
    test "with valid preauth token" do
    end
    test "with already used preauth token" do
    end
    test "with invalid preauth token" do
    end
    test "with missing parameters" do
    end
  end

  describe "purchase/2" do
    test "with valid token" do
    end
    test "with invalid token" do
    end
    test "with already existing payments" do
    end
  end

  describe "void/2" do
    test "with valid preauth token" do
    end
    test "with invalid preauth token" do
    end
  end

  describe "refund/3" do
    test "with valid transaction token" do
    end
    test "with invalid transaction token" do
    end
    test "with hight amount than the transaction amount" do
    end
    test "with partial amount" do
    end
  end
end
