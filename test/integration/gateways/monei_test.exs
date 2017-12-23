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

  setup_all do
    Application.put_env(:gringotts, Gringotts.Gateways.Monei, [adapter: Gringotts.Gateways.Monei,
                                                               userId: "8a8294186003c900016010a285582e0a",
                                                               password: "hMkqf2qbWf",
                                                               entityId: "8a82941760036820016010a28a8337f6"])
  end

  test "authorize." do
    case Gringotts.authorize(:payment_worker, Gateway, 3.1, @card) do
      {:ok, response} ->
        assert response.code == "000.100.110"
        assert response.description == "Request successfully processed in 'Merchant in Integrator Test Mode'"
        assert String.length(response.id) == 32
      {:error, _err} -> flunk()
    end
  end

  @tag :skip
  test "capture." do
    case Gringotts.capture(:payment_worker, Gateway, 32.00, "s") do
      {:ok, response} ->
        assert response.code == "000.100.110"
        assert response.description == "Request successfully processed in 'Merchant in Integrator Test Mode'"
        assert String.length(response.id) == 32
        
      {:error, _err} -> flunk()
    end
  end

  test "purchase." do
    case Gringotts.purchase(:payment_worker, Gateway, 32, @card) do
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
