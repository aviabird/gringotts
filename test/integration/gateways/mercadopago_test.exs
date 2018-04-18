defmodule Gringotts.Integration.Gateways.MercadopagoTest do
  # Integration tests for the Mercadopago 

  use ExUnit.Case, async: false
  use ExVCR.Mock, adapter: ExVCR.Adapter.Hackney
  alias Gringotts.Gateways.Mercadopago, as: Gateway

  @moduletag integration: true

  @amount Money.new(45, :BRL)
  @sub_amount Money.new(30, :BRL)
  @config [
    access_token: "TEST-2774702803649645-031303-1b9d3d63acb57cdad3458d386eee62bd-307592510",
    public_key: "TEST-911f45a1-0560-4c16-915e-a8833830b29a"
  ]
  @good_card %Gringotts.CreditCard{
    first_name: "Hermoine",
    last_name: "Granger",
    number: "4509953566233704",
    year: 2030,
    month: 07,
    verification_code: "123",
    brand: "VISA"
  }

  @good_opts [
    email: "hermoine@granger.com",
    order_id: 123_126,
    customer_id: "311211654-YrXF6J0QikpIWX",
    config: @config,
    installments: 1
  ]

  describe "[capture]" do
    test "capture success" do
      use_cassette "mercadopago/capture_success" do
        {:ok, response} = Gateway.authorize(@sub_amount, @good_card, @good_opts)
        {:ok, response} = Gateway.capture(response.id, @sub_amount, @good_opts)
        assert response.success == true
        assert response.status_code == 200
      end
    end

    test "invalid payment_id" do
      use_cassette "mercadopago/capture_invalid_payment_id" do
        {:ok, response} = Gateway.authorize(@sub_amount, @good_card, @good_opts)
        id = response.id + 1
        {:error, response} = Gateway.capture(id, @sub_amount, @good_opts)
        assert response.success == false
        assert response.status_code == 404
      end
    end

    test "extra amount capture" do
      use_cassette "mercadopago/access_amount" do
        {:ok, response} = Gateway.authorize(@sub_amount, @good_card, @good_opts)
        {:error, response} = Gateway.capture(response.id, @amount, @good_opts)
        assert response.success == false
        assert response.status_code == 400
      end
    end
  end
end
