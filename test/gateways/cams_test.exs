defmodule Gringotts.Gateways.CamsTest do
  Code.require_file("../mocks/cams_mock.exs", __DIR__)
  use ExUnit.Case, async: false

  alias Gringotts.{
    CreditCard,
    Response
  }

  alias Gringotts.Gateways.CamsMock, as: MockResponse
  alias Gringotts.Gateways.Cams, as: Gateway

  import Mock

  @card %CreditCard{
    number: "4111111111111111",
    month: 11,
    year: 2099,
    first_name: "Harry",
    last_name: "Potter",
    verification_code: "999",
    brand: "VISA"
  }
  @bad_card %CreditCard{
    number: "42",
    month: 11,
    year: 2099,
    first_name: "Harry",
    last_name: "Potter",
    verification_code: "999",
    brand: "VISA"
  }
  @address %{
    street1: "301, Gryffindor",
    street2: "Hogwarts School of Witchcraft and Wizardry, Hogwarts Castle",
    city: "Highlands",
    state: "Scotland",
    country: "GB",
    company: "Ollivanders",
    zip: "K1C2N6",
    phone: "(555)555-5555",
    fax: "(555)555-6666"
  }
  @auth %{username: "some_secret_user_name", password: "some_secret_password"}
  @options [
    order_id: 1,
    billing_address: @address,
    description: "Store Purchase"
  ]

  @money Money.new(:USD, 100)
  @money_more Money.new(:USD, 101)
  @money_less Money.new(:USD, 99)
  @bad_currency Money.new(:INR, 100)

  @id "some_transaction_id"
  @bad_id "some_fake_transaction_id"

  setup_all do
    Application.put_env(:gringotts, Gateway,
      username: "some_secret_user_name",
      password: "some_secret_password"
    )
  end

  describe "purchase" do
    test "with correct params" do
      with_mock HTTPoison,
        post: fn _url, _body, _headers -> MockResponse.successful_purchase() end do
        assert {:ok, %Response{}} = Gringotts.purchase(Gateway, @money, @card, @options)
      end
    end

    test "with bad card" do
      with_mock HTTPoison,
        post: fn _url, _body, _headers -> MockResponse.failed_purchase_with_bad_credit_card() end do
        {:error, %Response{reason: reason}} =
          Gringotts.purchase(Gateway, @money, @bad_card, @options)

        assert String.contains?(reason, "Invalid Credit Card Number")
      end
    end

    test "with invalid currency" do
      with_mock HTTPoison,
        post: fn _url, _body, _headers -> MockResponse.with_invalid_currency() end do
        {:error, %Response{reason: reason}} = Gringotts.purchase(Gateway, @bad_currency, @card, @options)
        assert String.contains?(reason, "The cc payment type")
      end
    end
  end

  describe "authorize" do
    test "with correct params" do
      with_mock HTTPoison,
        post: fn _url, _body, _headers -> MockResponse.successful_authorize() end do
        assert {:ok, %Response{}} = Gringotts.authorize(Gateway, @money, @card, @options)
      end
    end

    test "with bad card" do
      with_mock HTTPoison,
        post: fn _url, _body, _headers -> MockResponse.failed_authorized_with_bad_card() end do
        {:error, %Response{reason: reason}} =
          Gringotts.authorize(Gateway, @money, @bad_card, @options)

        assert String.contains?(reason, "Invalid Credit Card Number")
      end
    end
  end

  describe "capture" do
    test "with full amount" do
      with_mock HTTPoison, post: fn _url, _body, _headers -> MockResponse.successful_capture() end do
        assert {:ok, %Response{}} =
          Gringotts.capture(Gateway, @money, @id , @options)
      end
    end

    test "with partial amount" do
      with_mock HTTPoison, post: fn _url, _body, _headers -> MockResponse.successful_capture() end do
        assert {:ok, %Response{}} =
          Gringotts.capture(Gateway, @money_less, @id , @options)
      end
    end

    test "with invalid transaction_id" do
      with_mock HTTPoison,
        post: fn _url, _body, _headers -> MockResponse.invalid_transaction_id() end do
        {:error, %Response{reason: reason}} =
          Gringotts.capture(Gateway, @money, @bad_id, @options)

        assert String.contains?(reason, "Transaction not found")
      end
    end

    test "with more than authorized amount" do
      with_mock HTTPoison,
        post: fn _url, _body, _headers -> MockResponse.more_than_authorization_amount() end do
        {:error, %Response{reason: reason}} =
          Gringotts.capture(Gateway, @money_more, @id , @options)

        assert String.contains?(reason, "exceeds the authorization amount")
      end
    end

    test "on already captured transaction" do
      with_mock HTTPoison,
        post: fn _url, _body, _headers -> MockResponse.multiple_capture_on_same_transaction() end do
        {:error, %Response{reason: reason}} =
          Gringotts.capture(Gateway, @money, @id , @options)

        assert String.contains?(reason, "A capture requires that")
      end
    end
  end

  describe "refund" do
    test "with correct params" do
      with_mock HTTPoison, post: fn _url, _body, _headers -> MockResponse.successful_refund() end do
        assert {:ok, %Response{}} =
          Gringotts.refund(Gateway, @money, @id , @options)
      end
    end

    test "with more than purchased amount" do
      with_mock HTTPoison,
        post: fn _url, _body, _headers -> MockResponse.more_than_purchase_amount() end do
        {:error, %Response{reason: reason}} =
          Gringotts.refund(Gateway, @money_more, @id , @options)

        assert String.contains?(reason, "Refund amount may not exceed")
      end
    end
  end

  describe "void" do
    test "with correct params" do
      with_mock HTTPoison, post: fn _url, _body, _headers -> MockResponse.successful_void() end do
        {:ok, %Response{message: message}} = Gringotts.void(Gateway, @id , @options)
        assert String.contains?(message, "Void Successful")
      end
    end

    test "with invalid transaction_id" do
      with_mock HTTPoison,
        post: fn _url, _body, _headers -> MockResponse.invalid_transaction_id() end do
        {:error, %Response{reason: reason}} = Gringotts.void(Gateway, @bad_id, @options)
        assert String.contains?(reason, "Transaction not found")
      end
    end
  end

  describe "validate" do
    test "with correct params" do
      with_mock HTTPoison,
        post: fn _url, _body, _headers -> MockResponse.validate_creditcard() end do
        assert {:ok, %Response{}} = Gateway.validate(@card, @options ++ [config: @auth])
      end
    end
  end
end
