defmodule Gringotts.Integration.Gateways.PaymillTest do
  use ExUnit.Case, async: true
  use ExVCR.Mock, adapter: ExVCR.Adapter.Hackney

  alias Gringotts.{CreditCard, Response}
  alias Gringotts.Gateways.Paymill, as: Gateway

  @amount_4200 Money.new(100, :EUR)
  @amount_100 Money.new(100, :EUR)
  @valid_token "tok_d26e611c47d64693a281e8411934"

  @option [
    config: %{
      private_key: "a1bf5c1751ded07471ef246a29709c72",
      public_key: "61296669594ebbcc7794acafa9811c4d",
      mode: :test
    }
  ]

  describe "paymill authorize" do
    test "with valid token and currency" do
      use_cassette "paymill authorize with valid token and currency" do
        {:ok, response} = Gringotts.authorize(Gateway, @amount_100, @valid_token, @option)
        assert response.gateway_code == 20000
        assert response.status_code == 200
      end
    end
  end

  describe "paymill capture" do
    test "with valid token currency" do
      use_cassette "paymill capture with valid token currency" do
        {:ok, response} = Gringotts.authorize(Gateway, @amount_100, @valid_token, @option)
        payment_id = response.id
        {:ok, response_cap} = Gringotts.capture(Gateway, payment_id, @amount_100, @option)
        assert response_cap.gateway_code == 20000
        assert response_cap.status_code == 200
      end
    end
  end

  describe "paymill purchase" do
    test "with valid token currency" do
      use_cassette "paymill purchase with valid token currency" do
        {:ok, response} = Gringotts.purchase(Gateway, @amount_100, @valid_token, @option)
        assert response.gateway_code == 20000
        assert response.status_code == 200
      end
    end
  end

  describe "paymill refund" do
    test "with valid token currency" do
      use_cassette "paymill refund with valid token currency" do
        {:ok, response} = Gringotts.purchase(Gateway, @amount_100, @valid_token, @option)
        trans_id = response.id
        {:ok, response_ref} = Gringotts.refund(Gateway, @amount_100, trans_id, @option)
        assert response_ref.gateway_code == 20000
        assert response_ref.status_code == 200
      end
    end
  end

  describe "paymill void" do
    test "with valid token currency" do
      use_cassette "paymill void with valid token currency" do
        {:ok, response} = Gringotts.authorize(Gateway, @amount_100, @valid_token, @option)
        auth_id = response.id
        {:ok, response_void} = Gringotts.void(Gateway, auth_id, @option)
        assert response_void.gateway_code == 50810
        assert response_void.status_code == 200
      end
    end
  end
end
