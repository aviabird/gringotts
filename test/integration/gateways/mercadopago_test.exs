defmodule Gringotts.Integration.Gateways.MercadopagoTest do
  # Integration tests for the Mercadopago 

  use ExUnit.Case, async: true
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

  @bad_card %Gringotts.CreditCard{
    first_name: "Hermoine",
    last_name: "Granger",
    number: "4509953566233704",
    year: 2000,
    month: 07,
    verification_code: "123",
    brand: "VISA"
  }

  @good_opts [
    email: "hermoine@granger.com",
    order_id: 123_126,
    customer_id: "311211654-YrXF6J0QikpIWX",
    config: @config,
    installments: 1,
    order_type: "mercadopago"
  ]
  @new_cutomer_good_opts [
    order_id: 123_126,
    config: @config,
    installments: 1,
    order_type: "mercadopago"
  ]

  def new_email_opts(good) do
    no1 = :rand.uniform(1_000_00) |> to_string
    no2 = :rand.uniform(1_000_00) |> to_string
    no3 = :rand.uniform(1_000_00) |> to_string
    email = "hp" <> no1 <> no2 <> no3 <> "@potter.com"

    case good do
      true -> @new_cutomer_good_opts ++ [email: email]
      _ -> @new_cutomer_bad_opts ++ [email: email]
    end
  end

  describe "[authorize] old customer" do
    test "old customer with good_opts and good_card" do
      use_cassette "mercadopago/authorize_old customer with good_opts and good_card" do
        assert {:ok, response} = Gateway.authorize(@amount, @good_card, @good_opts)
        assert response.success == true
        assert response.status_code == 201
      end
    end

    test "old customer with good_opts and bad_card" do
      use_cassette "mercadopago/authorize_old customer with good_opts and bad_card" do
        assert {:error, response} = Gateway.authorize(@amount, @bad_card, @good_opts)
        assert response.success == false
        assert response.status_code == 400
      end
    end
  end

  setup do
    [opts: new_email_opts(true)]
  end

  describe "[authorize] new customer" do
    test "new cutomer with good_opts and good_card", %{opts: opts} do
      use_cassette "mercadopago/authorize_new cutomer with good_opts and good_card" do
        assert {:ok, response} = Gateway.authorize(@amount, @good_card, opts)
        assert response.success == true
        assert response.status_code == 201
      end
    end

    test "new customer with good_opts and bad_card", %{opts: opts} do
      use_cassette "mercadopago/authorize_new customer with good_opts and bad_card" do
        assert {:error, response} = Gateway.authorize(@amount, @bad_card, opts)
        assert response.success == false
        assert response.status_code == 400
      end
    end
  end
end
