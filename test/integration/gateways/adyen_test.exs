defmodule Gringotts.Integration.Gateways.AdyenTest do
  use ExUnit.Case, async: true
  use ExVCR.Mock, adapter: ExVCR.Adapter.Hackney

  alias Gringotts.Gateways.Adyen, as: Gateway
  alias Gringotts.{CreditCard}

  @moduletag integration: true

  @amount Money.new(4200, :EUR)

  @reference "payment-#{
               DateTime.utc_now() |> DateTime.to_string() |> String.replace([" ", ":", "."], "-")
             }"

  @card %CreditCard{
    brand: "VISA",
    first_name: "John",
    last_name: "Smith",
    number: "4988438843884305",
    month: "08",
    year: "2018",
    verification_code: "737"
  }

  setup_all do
    Application.put_env(
      :gringotts,
      Gateway,
      username: "ws@Company.Aviabird",
      password: "R+F#@D38SI2+DEy5vTDs?IFwN",
      account: "AviabirdCOM",
      mode: :test,
      url: "your live url",
      reference: @reference
    )

    on_exit(fn ->
      Application.delete_env(:gringotts, Gateway)
    end)
  end

  setup do
    [opts: [reference: @reference]]
  end

  describe "authorize" do
    test "with valid card and currency", context do
      use_cassette "adyen/authorize with valid card and currency" do
        {:ok, response} = Gringotts.authorize(Gateway, @amount, @card, context.opts)
        assert response.message == "Authorised"
        assert response.status_code == 200
      end
    end
  end

  describe "capture" do
    test "with valid card currency", context do
      use_cassette "adyen/capture with valid card currency" do
        {:ok, response} = Gringotts.authorize(Gateway, @amount, @card, context.opts)
        payment_id = response.id
        {:ok, response_cap} = Gringotts.capture(Gateway, payment_id, @amount)
        assert response_cap.message == "[capture-received]"
        assert response_cap.status_code == 200
      end
    end
  end

  describe "purchase" do
    test "with valid card currency", context do
      use_cassette "adyen purchase with valid card currency" do
        {:ok, response} = Gringotts.purchase(Gateway, @amount, @card, context.opts)
        assert response.message == "[capture-received]"
        assert response.status_code == 200
      end
    end
  end

  describe "refund" do
    test "with valid card currency", context do
      use_cassette "adyen/refund with valid card currency" do
        {:ok, response} = Gringotts.purchase(Gateway, @amount, @card, context.opts)
        trans_id = response.id
        {:ok, response_ref} = Gringotts.refund(Gateway, @amount, trans_id)
        assert response_ref.message == "[refund-received]"
        assert response_ref.status_code == 200
      end
    end
  end

  describe "void" do
    test "with valid card currency", context do
      use_cassette "adyen/void with valid card currency" do
        {:ok, response} = Gringotts.authorize(Gateway, @amount, @card, context.opts)
        auth_id = response.id
        {:ok, response_void} = Gringotts.void(Gateway, auth_id)
        assert response_void.message == "[cancel-received]"
        assert response_void.status_code == 200
      end
    end
  end
end
