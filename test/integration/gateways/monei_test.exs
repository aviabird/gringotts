defmodule Gringotts.Integration.Gateways.MoneiTest do
  use ExUnit.Case, async: false

  alias Gringotts.{
    CreditCard
  }
  alias Gringotts.Gateways.Monei, as: Gateway

  @moduletag :integration
  
  @card %CreditCard{
    first_name: "Jo",
    last_name: "Doe",
    number: "4200000000000000",
    year: 2099,
    month: 12,
    verification_code:  "123",
    brand: "VISA"
  }

  @customer %{"givenName": "Harry",
              "surname": "Potter",
              "merchantCustomerId": "the_boy_who_lived",
              "sex": "M", 
              "birthDate": "1980-07-31", 
              "mobile": "+15252525252", 
              "email": "masterofdeath@ministryofmagic.go v",
              "ip": "1.1.1", 
              "status": "NEW"} 
  @merchant %{"name": "Ollivanders",
              "city": "South Side",
              "street": "Diagon Alley",
              "state": "London",
              "country": "GB",
              "submerchantId": "Makers of Fine Wands since 382 B.C."}
  @billing %{"street1": "301, Gryffindor",
             "street2": "Hogwarts School of Witchcraft and Wizardry, Hogwarts Castle",
             "city": "Highlands",
             "state": "Scotland",
             "country": "GB"}
  @shipping Map.merge(
    %{"method": "SAME_DAY_SERVICE",
      "comment": "For our valued customer, Mr. Potter"},
    @billing)

  @extra_opts [customer: @customer,
               merchant: @merchant,
               billing: @billing,
               shipping: @shipping,
               category: "EC",
               custom: %{"voldemort": "he who must not be named"}]

  setup_all do
    Application.put_env(:gringotts, Gringotts.Gateways.Monei, [adapter: Gringotts.Gateways.Monei,
                                                               userId: "8a8294186003c900016010a285582e0a",
                                                               password: "hMkqf2qbWf",
                                                               entityId: "8a82941760036820016010a28a8337f6"])
  end

  setup do
    randoms = [invoice_id: Base.encode16(:crypto.hash(:md5, :crypto.strong_rand_bytes(32))),
               transaction_id: Base.encode16(:crypto.hash(:md5, :crypto.strong_rand_bytes(32)))]
    {:ok, opts: randoms ++ @extra_opts}
  end

  test "authorize", %{opts: opts} do
    case Gringotts.authorize(Gateway, Money.new(42, :EUR), @card, opts) do
      {:ok, response} ->
        assert response.code == "000.100.110"
        assert response.description == "Request successfully processed in 'Merchant in Integrator Test Mode'"
        assert String.length(response.id) == 32
      {:error, _err} -> flunk()
    end
  end

  @tag :skip
  test "capture", %{opts: _opts} do
    case Gringotts.capture(Gateway, Money.new(42, :EUR), "s") do
      {:ok, response} ->
        assert response.code == "000.100.110"
        assert response.description == "Request successfully processed in 'Merchant in Integrator Test Mode'"
        assert String.length(response.id) == 32
        
      {:error, _err} -> flunk()
    end
  end

  test "purchase", %{opts: opts} do
    case Gringotts.purchase(Gateway, Money.new(42, :EUR), @card, opts) do
      {:ok, response} ->
        assert response.code == "000.100.110"
        assert response.description == "Request successfully processed in 'Merchant in Integrator Test Mode'"
        assert String.length(response.id) == 32
      {:error, _err} -> flunk()
    end
  end

  test "Environment setup" do
    config = Application.get_env(:gringotts, Gringotts.Gateways.Monei)
    assert config[:adapter] == Gringotts.Gateways.Monei
  end
end
