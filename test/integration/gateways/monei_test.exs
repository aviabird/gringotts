defmodule Kuber.Hex.Integration.Gateways.MoneiTest do
  use ExUnit.Case, async: false

  alias Kuber.Hex.{
    CreditCard,
    Worker
  }
  alias Kuber.Hex.Gateways.Monei, as: Gateway

  @moduletag :integration
  
  @card %CreditCard{
    name: "Jo Doe",
    number: "4200000000000000",
    expiration: {2099, 12},
    cvc:  "123",
    brand: "VISA"
  }

  setup_all do
    auth = %{userId: "8a8294186003c900016010a285582e0a", password: "hMkqf2qbWf", entityId: "8a82941760036820016010a28a8337f6"}
    Application.put_env(:kuber_hex, Kuber.Hex, [adapter: Kuber.Hex.Gateways.Monei,
                                                worker_process_name: :monei_gateway,
                                                userId: "8a8294186003c900016010a285582e0a",
                                                password: "hMkqf2qbWf",
                                                entityId: "8a82941760036820016010a28a8337f6"])
    {:ok, worker} = Worker.start_link(Gateway, auth, name: :monei_gateway)
    {:ok, worker: worker} # note that `worker` is just a PID
    # optionally enable tracing this Gateway:
    # :sys.statistics(worker, true)
    # :sys.trace(worker, true)
  end

  test "authorize." do
    case Kuber.Hex.authorize(:monei_gateway, 3.1, @card, currency: "USD") do
      {:ok, response} ->
        assert response.code == "000.100.110"
        assert response.description == "Request successfully processed in 'Merchant in Integrator Test Mode'"
        assert String.length(response.id) == 32
      {:error, _err} -> flunk()
    end
  end

  @tag :skip
  test "capture." do
    case Kuber.Hex.capture(:monei_gateway, 32.00, "s") do
      {:ok, response} ->
        assert response.code == "000.100.110"
        assert response.description == "Request successfully processed in 'Merchant in Integrator Test Mode'"
        assert String.length(response.id) == 32
        
      {:error, _err} -> flunk()
    end
  end

  test "purchase." do
    case Kuber.Hex.purchase(:monei_gateway, 32, @card) do
      {:ok, response} ->
        assert response.code == "000.100.110"
        assert response.description == "Request successfully processed in 'Merchant in Integrator Test Mode'"
        assert String.length(response.id) == 32
      {:error, _err} -> flunk()
    end
  end

  test "Environment setup" do
    config = Application.get_env(:kuber_hex, Kuber.Hex)
    assert config[:adapter] == Kuber.Hex.Gateways.Monei
  end

end
