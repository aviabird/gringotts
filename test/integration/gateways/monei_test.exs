defmodule Kuber.Hex.Integration.Gateways.MoneiTest do
  use ExUnit.Case, async: true

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
    auth = %{userId: "8a829417539edb400153c1eae83932ac", password: "6XqRtMGS2N", entityId: "8a829417539edb400153c1eae6de325e"}
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

  # test "capture." do
  #   case Kuber.Hex.capture(:monei_gateway, 32.00, :ets.lookup(table, :auth_id) do
  #     {:ok, response} ->
  #       assert response.code == "000.100.110"
  #       assert response.description == "Request successfully processed in 'Merchant in Integrator Test Mode'"
  #       assert String.length(response.id) == 32
        
  #     {:error, _err} -> flunk()
  #   end
  # end

  
  test "purchase." do
    case Kuber.Hex.authorize(:monei_gateway, 32, @card) do
      {:ok, response} ->
        assert response.code == "000.100.110"
        assert response.description == "Request successfully processed in 'Merchant in Integrator Test Mode'"
        assert String.length(response.id) == 32
      {:error, _err} -> flunk()
    end
  end

end
