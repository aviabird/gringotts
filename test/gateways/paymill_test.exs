defmodule Gringotts.Gateways.PaymillTest do
  use ExUnit.Case, async: false

  Code.require_file "../mocks/paymill_mock.exs", __DIR__
  alias Gringotts.{CreditCard, Response}
  alias Gringotts.Gateways.Paymill
  alias Gringotts.Gateways.PaymillMock, as: MockResponse

  import Mock

  @valid_card %CreditCard{
    first_name: "Sagar",
    last_name: "Karwande",
    number: "4111111111111111",
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

    test "with valid card token" do
      with_mock HTTPoison,
      [request: fn(_method, _url, _body, _headers, _opts) ->
      MockResponse.successful_authorize end] do

        {:ok, response} = Paymill.authorize(100, "tok_6864ab6cce1444833ede76077ed0", @options)

        assert response.success
        assert response.status_code == 200
        assert response.error_code == 20000
      end
    end

    test "with invalid cvv" do
      with_mock HTTPoison,
      [request: fn(_method, _url, _body, _headers, _opts) ->
      MockResponse.authorize_invalid_cvv end] do

        {:error, response} = Paymill.authorize(100, "tok_40101_23f20b1cebf9f4eb50d5e0", @options)

        refute response.success
        assert response.status_code == 200
        assert response.error_code == 50800
        assert response.message == "Preauthorisation failed"
      end
    end

    test "with invalid card token" do
      with_mock HTTPoison,
      [request: fn(_method, _url, _body, _headers, _opts) ->
      MockResponse.authorize_invalid_card_token end] do

        {:error, response} = Paymill.authorize(100, "tok_123", @options)

        refute response.success
        assert response.status_code == 400
        assert response.message == "'tok_123' does not match against pattern '/^[a-zA-Z0-9_]{32}$/'"
      end
    end

    test "with currency or amount mismatch" do
      with_mock HTTPoison,
      [request: fn(_method, _url, _body, _headers, _opts) ->
      MockResponse.authorize_invalid_currency end] do

        invalid_opts = @options ++ [currency: "ABC"]
        {:error, response} = Paymill.authorize(100, "tok_123", invalid_opts)

        refute response.success
        assert response.status_code == 400
        assert response.message == "'ABC' was not found in the haystack"
      end
    end

  end

  describe "capture/3" do

    test "with valid preauth token" do
      with_mock HTTPoison,
      [request: fn(_method, _url, _body, _headers, _opts) ->
      MockResponse.successful_capture end] do

        {:ok, response} = Paymill.capture("preauth_7dc9457660b33759b70b", 100, @options)

        assert response.success
        assert response.status_code == 200
        assert response.error_code == 20000
      end
    end

    test "with already used preauth token" do
      with_mock HTTPoison,
      [request: fn(_method, _url, _body, _headers, _opts) ->
      MockResponse.capture_with_used_auth end] do

        {:error, response} = Paymill.capture("preauth_7dc9457660b33759b70b", 100, @options)

        refute response.success
        assert response.status_code == 409
        assert response.message == "Preauthorization has already been used"
      end
    end

    test "with invalid preauth token" do
      with_mock HTTPoison,
      [request: fn(_method, _url, _body, _headers, _opts) ->
      MockResponse.capture_with_invalid_auth_token end] do

        {:error, response} = Paymill.capture("preauth_123", 100, @options)

        refute response.success
        assert response.status_code == 404
        assert response.message == "Preauthorize not found"
      end
    end

  end

  describe "purchase/2" do

    test "with valid token" do
      with_mock HTTPoison,
      [request: fn(_method, _url, _body, _headers, _opts) ->
      MockResponse.successful_purchase end] do

        {:ok, response} = Paymill.purchase(100, "tok_59f35a89e96dee1ceb6b437317be", @options)

        assert response.success
        assert response.status_code == 200
        assert response.error_code == 20000
        assert response.message == "Operation successful"
      end
    end

    test "with invalid token" do
      with_mock HTTPoison,
      [request: fn(_method, _url, _body, _headers, _opts) ->
      MockResponse.purchase_with_invalid_card_token end] do

        {:error, response} = Paymill.purchase(100, "tok_59f35a89e96dee1ceb6b437317be", @options)

        refute response.success
        assert response.status_code == 403
        assert response.error_code == 40102
        assert response.message == "Card expired or not yet valid"
      end
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
