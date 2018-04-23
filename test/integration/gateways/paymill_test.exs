defmodule Gringotts.Integration.Gateways.PaymillTest do
  use ExUnit.Case, async: true
  use ExVCR.Mock, adapter: ExVCR.Adapter.Hackney

  alias Gringotts.Gateways.Paymill, as: Gateway

  @moduletag integration: true

  @amount Money.new(4200, :EUR)
  @valid_token1 "tok_784c33eeb9a6adfc2bd3c21f95e6"
  @valid_token2 "tok_9e429fb2dc44bcf94bcd4e6e6ec5"
  @valid_token3 "tok_55b80f87f44f9328bee99360c4cc"
  @valid_token4 "tok_7fb13046921783327aaf3f69668c"
  @valid_token5 "tok_182291df812e8de23ee7cd849768"

  setup_all do
    Application.put_env(
      :gringotts,
      Gateway,
      private_key: "a1bf5c1751ded07471ef246a29709c72",
      public_key: "61296669594ebbcc7794acafa9811c4d",
      mode: :test
    )

    on_exit(fn ->
      Application.delete_env(:gringotts, Gateway)
    end)
  end

  describe "authorize" do
    test "with valid token and currency" do
      use_cassette "paymill/authorize with valid token and currency" do
        {:ok, response} = Gringotts.authorize(Gateway, @amount, @valid_token1)
        assert response.gateway_code == 20000
        assert response.status_code == 200
      end
    end
  end

  describe "capture" do
    test "with valid token currency" do
      use_cassette "paymill/capture with valid token currency" do
        {:ok, response} = Gringotts.authorize(Gateway, @amount, @valid_token2)
        payment_id = response.id
        {:ok, response_cap} = Gringotts.capture(Gateway, payment_id, @amount)
        assert response_cap.gateway_code == 20000
        assert response_cap.status_code == 200
      end
    end
  end

  describe "purchase" do
    test "with valid token currency" do
      use_cassette "paymill purchase with valid token currency" do
        {:ok, response} = Gringotts.purchase(Gateway, @amount, @valid_token3)
        assert response.gateway_code == 20000
        assert response.status_code == 200
      end
    end
  end

  describe "refund" do
    test "with valid token currency" do
      use_cassette "paymill/refund with valid token currency" do
        {:ok, response} = Gringotts.purchase(Gateway, @amount, @valid_token4)
        trans_id = response.id
        {:ok, response_ref} = Gringotts.refund(Gateway, @amount, trans_id)
        assert response_ref.gateway_code == 20000
        assert response_ref.status_code == 200
      end
    end
  end

  describe "void" do
    test "with valid token currency" do
      use_cassette "paymill/void with valid token currency" do
        {:ok, response} = Gringotts.authorize(Gateway, @amount, @valid_token5)
        auth_id = response.id
        {:ok, response_void} = Gringotts.void(Gateway, auth_id)
        assert response_void.gateway_code == 50810
        assert response_void.status_code == 200
      end
    end
  end
end
