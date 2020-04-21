defmodule Gringotts.Integration.Gateways.MercadopagoTest do
  # Integration tests for the Mercadopago

  use ExUnit.Case, async: true
  alias Gringotts.Gateways.Mercadopago, as: Gateway

  alias Gringotts.{
    CreditCard,
    FakeMoney
  }

  @moduletag integration: true

  @amount FakeMoney.new(45, :BRL)
  @sub_amount FakeMoney.new(30, :BRL)
  @config [
    access_token: "TEST-4543588471539213-040810-f4f850f89480ee1bd56e05a9aa0d6210-543713181",
    public_key: "TEST-4508ea76-c56b-436a-9213-57934dfb2d86"
  ]
  @bad_config [
    access_token: "TEST-4543588471539213-111111-f4f850f89480ee1bd56e05a9aa0d6210-543713181",
    public_key: "TEST-4508ea76-c56b-436a-9999-57934dfb2d86"
  ]
  @good_card %CreditCard{
    first_name: "Hermoine",
    last_name: "Grangerr",
    number: "4509953566233704",
    year: 2030,
    month: 07,
    verification_code: "123",
    brand: "VISA"
  }

  @bad_card %CreditCard{
    first_name: "Hermoine",
    last_name: "Grangerr",
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
  @bad_opts [
    email: "hermoine@granger.com",
    config: @bad_config
  ]

  @new_cutomer_good_opts [
    order_id: 123_126,
    config: @config,
    installments: 1,
    order_type: "mercadopago"
  ]
  @new_cutomer_bad_opts [
    config: @bad_config,
    order_id: 123_127
  ]

  def new_email_opts(good) do
    no1 = 100_000 |> :rand.uniform() |> to_string
    no2 = 100_000 |> :rand.uniform() |> to_string
    no3 = 100_000 |> :rand.uniform() |> to_string
    email = "hp" <> no1 <> no2 <> no3 <> "@potter.com"

    case good do
      true -> @new_cutomer_good_opts ++ [email: email]
      _ -> @new_cutomer_bad_opts ++ [email: email]
    end
  end

  describe "[authorize] old customer" do
    test "old customer with good_opts and good_card" do
      assert {:ok, response} = Gateway.authorize(@amount, @good_card, @good_opts)
      assert response.success == true
      assert response.status_code == 201
    end

    test "old customer with good_opts and bad_card" do
      assert {:error, response} = Gateway.authorize(@amount, @bad_card, @good_opts)
      assert response.success == false
      assert response.status_code == 400
    end
  end

  setup do
    [opts: new_email_opts(true)]
  end

  describe "[authorize] new customer" do
    test "new cutomer with good_opts and good_card", %{opts: opts} do
      assert {:ok, response} = Gateway.authorize(@amount, @good_card, opts)
      assert response.success == true
      assert response.status_code == 201
    end

    test "new customer with good_opts and bad_card", %{opts: opts} do
      assert {:error, response} = Gateway.authorize(@amount, @bad_card, opts)
      assert response.success == false
      assert response.status_code == 400
    end
  end

  describe "[capture]" do
    test "capture success" do
      {:ok, response} = Gateway.authorize(@sub_amount, @good_card, @good_opts)
      {:ok, response} = Gateway.capture(response.id, @sub_amount, @good_opts)
      assert response.success == true
      assert response.status_code == 200
    end

    test "capture invalid payment_id" do
      {:ok, response} = Gateway.authorize(@sub_amount, @good_card, @good_opts)
      id = response.id + 1
      {:error, response} = Gateway.capture(id, @sub_amount, @good_opts)
      assert response.success == false
      assert response.status_code == 404
    end

    test "extra amount capture" do
      {:ok, response} = Gateway.authorize(@sub_amount, @good_card, @good_opts)
      {:error, response} = Gateway.capture(response.id, @amount, @good_opts)
      assert response.success == false
      assert response.status_code == 400
    end
  end

  describe "[void]" do
    test "void success" do
      {:ok, response} = Gateway.authorize(@sub_amount, @good_card, @good_opts)
      {:ok, response} = Gateway.void(response.id, @good_opts)
      assert response.success == true
      assert response.status_code == 200
    end

    test "invalid payment_id" do
      {:ok, response} = Gateway.authorize(@sub_amount, @good_card, @good_opts)
      id = response.id + 1
      {:error, response} = Gateway.void(id, @good_opts)
      assert response.success == false
      assert response.status_code == 404
    end
  end

  describe "[purchase]" do
    test "old customer with good_opts and good_card" do
      assert {:ok, response} = Gateway.purchase(@amount, @good_card, @good_opts)
      assert response.success == true
      assert response.status_code == 201
    end

    test "old customer with good_opts and bad_card" do
      assert {:error, response} = Gateway.purchase(@amount, @bad_card, @good_opts)
      assert response.success == false
      assert response.status_code == 400
    end

    test "old customer with bad_opts and good_card" do
      assert {:error, response} = Gateway.purchase(@amount, @good_card, @bad_opts)
      assert response.success == false
      # We expect 401-Unauthorized when bad access_token is provided.
      # But mergadopago API returns 404 with message "invalid token" instead.
      # So that is what we check
      assert response.status_code == 404
      assert response.message == "invalid_token"
    end

    test "old customer with bad_opts and bad_card" do
      assert {:error, response} = Gateway.purchase(@amount, @bad_card, @bad_opts)
      assert response.success == false
      assert response.status_code == 400
      assert response.message == "invalid expiration_year"
    end

    test "new cutomer with good_opts and good_card" do
      opts = new_email_opts(true)
      assert {:ok, response} = Gateway.purchase(@amount, @good_card, opts)
      assert response.success == true
      assert response.status_code == 201
    end

    test "new customer with good_opts and bad_card" do
      opts = new_email_opts(true)
      assert {:error, response} = Gateway.purchase(@amount, @bad_card, opts)
      assert response.success == false
      assert response.status_code == 400
      assert response.message == "invalid expiration_year"
    end

    test "new customer with bad_opts and good_card" do
      opts = new_email_opts(false)
      assert {:error, response} = Gateway.purchase(@amount, @good_card, opts)
      assert response.success == false
      # We expect 401-Unauthorized when bad access_token is provided.
      # But mergadopago API returns 404 with message "invalid token" instead.
      # So that is what we check
      assert response.status_code == 404
      assert response.message == "invalid_token"
    end

    test "new customer with bad_opts and bad_card" do
      opts = new_email_opts(false)
      assert {:error, response} = Gateway.purchase(@amount, @bad_card, opts)
      assert response.success == false
      assert response.status_code == 400
      assert response.message == "invalid expiration_year"
    end
  end

  describe "[refund]" do
    test "refund success" do
      {:ok, response} = Gateway.purchase(@sub_amount, @good_card, @good_opts)
      {:ok, response} = Gateway.refund(@sub_amount, response.id, @good_opts)
      assert response.success == true
      assert response.status_code == 201
    end

    test "invalid payment_id" do
      {:ok, response} = Gateway.purchase(@sub_amount, @good_card, @good_opts)
      id = response.id + 1
      {:error, response} = Gateway.refund(@sub_amount, id, @good_opts)
      assert response.success == false
      assert response.status_code == 404
    end

    test "extra amount refund" do
      {:ok, response} = Gateway.purchase(@sub_amount, @good_card, @good_opts)
      {:error, response} = Gateway.refund(@amount, response.id, @good_opts)
      assert response.success == false
      assert response.status_code == 400
    end
  end
end
