defmodule Gringotts.Integration.Gateways.MercadopagoTest do
  # Integration tests for the Mercadopago 

  use ExUnit.Case, async: false
  use ExVCR.Mock, adapter: ExVCR.Adapter.Hackney
  alias Gringotts.Gateways.Mercadopago, as: Gateway

  @moduletag :integration

  @amount Money.new(45, :BRL)
  @sub_amount Money.new(30, :BRL)
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

  @good_opts [email: "hermoine@granger.com",
         order_id: 123126,
         customer_id: "311211654-YrXF6J0QikpIWX",
         config: [access_token: "TEST-2774702803649645-031303-1b9d3d63acb57cdad3458d386eee62bd-307592510",
                 public_key: "TEST-911f45a1-0560-4c16-915e-a8833830b29a"],
         installments: 1
        ]
  @new_cutomer_good_opts [order_id: 123126,
         config: [access_token: "TEST-2774702803649645-031303-1b9d3d63acb57cdad3458d386eee62bd-307592510",
                 public_key: "TEST-911f45a1-0560-4c16-915e-a8833830b29a"],
         installments: 1
        ]
  @new_cutomer_bad_opts [order_id: 123126,
         config: [public_key: "TEST-911f45a1-0560-4c16-915e-a8833830b29a"],
         installments: 1
        ]
  @bad_opts [email: "hermoine@granger.com",
         order_id: 123126,
         customer_id: "311211654-YrXF6J0QikpIWX",
         config: [public_key: "TEST-911f45a1-0560-4c16-915e-a8833830b29a"],
         installments: 1
       ]

  
  # Group the test cases by public api

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

  describe "[authorize]" do
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

    test "old customer with bad_opts and good_card" do
      use_cassette "mercadopago/authorize_old customer with bad_opts and good_card" do
        assert {:error, response} = Gateway.authorize(@amount, @good_card, @bad_opts)
        assert response.success == false
        assert response.status_code == 401
      end
    end
    test "old customer with bad_opts and bad_opts" do
      use_cassette "mercadopago/authorize_old customer with bad_opts and bad_opts" do
        assert {:error, response} = Gateway.authorize(@amount, @bad_card, @bad_opts)
        assert response.success == false
        assert response.status_code == 400
      end
    end

    test "new cutomer with good_opts and good_card" do
      use_cassette "mercadopago/authorize_new cutomer with good_opts and good_card" do
        opts = new_email_opts(true)
        assert {:ok, response} = Gateway.authorize(@amount, @good_card, opts)
        assert response.success == true
        assert response.status_code == 201
      end
    end

    test "new customer with good_opts and bad_card" do
      use_cassette "mercadopago/authorize_new customer with good_opts and bad_card" do
        opts = new_email_opts(true)
        assert {:error, response} = Gateway.authorize(@amount, @bad_card, opts)
        assert response.success == false
        assert response.status_code == 400
      end
    end

    test "new customer with bad_opts and good_card" do
      use_cassette "mercadopago/authorize_new customer with bad_opts and good_card" do
        opts = new_email_opts(false)
        assert {:error, response} = Gateway.authorize(@amount, @good_card, opts)
        assert response.success == false
        assert response.status_code == 401
      end
    end
    test "new customer with bad_opts and bad_card" do
      use_cassette "mercadopago/authorize_new customer with bad_opts and bad_card" do
        opts = new_email_opts(false)
        assert {:error, response} = Gateway.authorize(@amount, @bad_card, opts)
        assert response.success == false
        assert response.status_code == 401
      end
    end
  end
end
