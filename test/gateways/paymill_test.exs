defmodule Gringotts.Gateways.PaymillTest do
  use ExUnit.Case, async: false

  Code.require_file("../mocks/paymill_mock.exs", __DIR__)
  alias Gringotts.{CreditCard, Response}
  alias Gringotts.Gateways.Paymill
  alias Gringotts.Gateways.PaymillMock, as: MockResponse

  import Mock

  @amount Money.new(10, :USD)
  @big_amount Money.new(100, :USD)
  @valid_card %CreditCard{
    first_name: "Sagar",
    last_name: "Karwande",
    number: "4111111111111111",
    month: 12,
    year: 2018,
    verification_code: 123
  }

  @options [
    config: %{
      private_key: "8f16b021d4fb1f8d9263cbe346f32688",
      public_key: "72294854039fcf7fd55eaeeb594577e7"
    }
  ]

  describe "authorize/3" do
    test "with valid card token" do
      with_mock HTTPoison,
        request: fn _method, _url, _body, _headers ->
          MockResponse.successful_authorize()
        end do
        {:ok, response} = Paymill.authorize(@amount, "tok_6864ab6cce1444833ede76077ed0", @options)

        assert response.success
        assert response.status_code == 200
        assert response.error_code == 20_000
      end
    end

    test "with invalid cvv" do
      with_mock HTTPoison,
        request: fn _method, _url, _body, _headers ->
          MockResponse.authorize_invalid_cvv()
        end do
        {:error, response} =
          Paymill.authorize(@amount, "tok_40101_23f20b1cebf9f4eb50d5e0", @options)

        refute response.success
        assert response.status_code == 200
        assert response.error_code == 50_800
        assert response.message == "Preauthorisation failed"
      end
    end

    test "with invalid card token" do
      with_mock HTTPoison,
        request: fn _method, _url, _body, _headers ->
          MockResponse.authorize_invalid_card_token()
        end do
        {:error, response} = Paymill.authorize(@amount, "tok_123", @options)

        refute response.success
        assert response.status_code == 400

        assert response.message ==
                 "'tok_123' does not match against pattern '/^[a-zA-Z0-9_]{32}$/'"
      end
    end

    test "with currency or amount mismatch" do
      with_mock HTTPoison,
        request: fn _method, _url, _body, _headers ->
          MockResponse.authorize_invalid_currency()
        end do
        invalid_opts = @options ++ [currency: "ABC"]
        {:error, response} = Paymill.authorize(@amount, "tok_123", invalid_opts)

        refute response.success
        assert response.status_code == 400
        assert response.message == "'ABC' was not found in the haystack"
      end
    end
  end

  describe "capture/3" do
    test "with valid preauth token" do
      with_mock HTTPoison,
        request: fn _method, _url, _body, _headers ->
          MockResponse.successful_capture()
        end do
        {:ok, response} = Paymill.capture("preauth_7dc9457660b33759b70b", @amount, @options)

        assert response.success
        assert response.status_code == 200
        assert response.error_code == 20_000
      end
    end

    test "with already used preauth token" do
      with_mock HTTPoison,
        request: fn _method, _url, _body, _headers ->
          MockResponse.capture_with_used_auth()
        end do
        {:error, response} = Paymill.capture("preauth_7dc9457660b33759b70b", @amount, @options)

        refute response.success
        assert response.status_code == 409
        assert response.message == "Preauthorization has already been used"
      end
    end

    test "with invalid preauth token" do
      with_mock HTTPoison,
        request: fn _method, _url, _body, _headers ->
          MockResponse.capture_with_invalid_auth_token()
        end do
        {:error, response} = Paymill.capture("preauth_123", @amount, @options)

        refute response.success
        assert response.status_code == 404
        assert response.message == "Preauthorize not found"
      end
    end
  end

  describe "purchase/2" do
    test "with valid token" do
      with_mock HTTPoison,
        request: fn _method, _url, _body, _headers ->
          MockResponse.successful_purchase()
        end do
        {:ok, response} = Paymill.purchase(@amount, "tok_59f35a89e96dee1ceb6b437317be", @options)

        assert response.success
        assert response.status_code == 200
        assert response.error_code == 20_000
        assert response.message == "Operation successful"
      end
    end

    test "with invalid token" do
      with_mock HTTPoison,
        request: fn _method, _url, _body, _headers ->
          MockResponse.purchase_with_invalid_card_token()
        end do
        {:error, response} =
          Paymill.purchase(@amount, "tok_59f35a89e96dee1ceb6b437317be", @options)

        refute response.success
        assert response.status_code == 403
        assert response.error_code == 40_102
        assert response.message == "Card expired or not yet valid"
      end
    end
  end

  describe "void/2" do
    test "with valid preauth token" do
      with_mock HTTPoison,
        request: fn _method, _url, _body, _headers ->
          MockResponse.successful_void()
        end do
        {:ok, response} = Paymill.void("preauth_028b0d40a6465099a774", @options)

        assert response.success
        assert response.status_code == 200
        assert response.error_code == 50_810
        assert response.message == "Authorisation has been voided"
      end
    end

    test "with invalid preauth token" do
      with_mock HTTPoison,
        request: fn _method, _url, _body, _headers ->
          MockResponse.void_with_invalid_auth_token()
        end do
        {:error, response} = Paymill.void("preauth_028b0d40a6465099a123", @options)

        refute response.success
        assert response.status_code == 404
        assert response.message == "Preauthorization was not found"
      end
    end
  end

  describe "refund/3" do
    test "with valid transaction token" do
      with_mock HTTPoison,
        request: fn _method, _url, _body, _headers ->
          MockResponse.successful_refund()
        end do
        {:ok, response} = Paymill.refund(@amount, "tran_8e3c8746b274c89930cd2a38ed43", @options)

        assert response.success
        assert response.status_code == 200
        assert response.error_code == 20_000
        assert response.message == "Operation successful"
      end
    end

    test "with invalid transaction token" do
      with_mock HTTPoison,
        request: fn _method, _url, _body, _headers ->
          MockResponse.refund_with_invalid_trans_token()
        end do
        {:error, response} =
          Paymill.refund(@amount, "tran_8e3c8746b274c89930cd2a38e123", @options)

        refute response.success
        assert response.status_code == 404
        assert response.message == "Transaction not found"
      end
    end

    test "with high amount than the transaction amount" do
      with_mock HTTPoison,
        request: fn _method, _url, _body, _headers ->
          MockResponse.refund_with_high_amount()
        end do
        {:error, response} =
          Paymill.refund(@big_amount, "tran_d9df8ae460354befe6aee6916fbf", @options)

        refute response.success
        assert response.status_code == 400
        assert response.message == "Amount to high"
      end
    end
  end
end
