defmodule Kuber.HexTest do
  use ExUnit.Case

  alias Kuber.Hex.Worker
  import Kuber.Hex

  defmodule FakeGateway do
    def authorize(100, :card, _) do
      :authorization_response
    end

    def purchase(100, :card, _) do
      :purchase_response
    end

    def capture(1234, 100,_) do
      :capture_response
    end

    def void(1234, _) do
      :void_response
    end

    def refund(100, 1234, _) do
      :refund_response
    end

    def store(:card, _) do
      :store_response
    end

    def unstore(123, 456, _) do
      :unstore_response
    end
  end

  setup do
    {:ok, worker} = Worker.start_link(FakeGateway, :config)
    # Setup the config for the application this is required as the 
    # application is not setting the config
    Application.put_env(:kuber_hex, Kuber.Hex, [
      adapter: Kuber.Hex.Gateways.Stripe,
      api_key: "sk_test_mnrVg6z2G0HeDzwy5gxJfmfP",
      default_currency: "USD",
      worker_process_name: :stripe_gateway]
    )
    {:ok, worker: worker}
  end

  test "authorization", %{worker: worker} do
    assert authorize(worker, 100, :card, []) == :authorization_response
  end

  test "purchase", %{worker: worker} do
    assert purchase(worker, 100, :card, []) == :purchase_response
  end

  test "capture", %{worker: worker} do
    assert capture(worker, 1234, 100,[]) == :capture_response
  end

  test "void", %{worker: worker} do
    assert void(worker, 1234, []) == :void_response
  end

  test "refund", %{worker: worker} do
    assert refund(worker, 100, 1234, []) == :refund_response
  end

  test "store", %{worker: worker} do
    assert store(worker, :card, []) == :store_response
  end

  test "unstore", %{worker: worker} do
    assert unstore(worker, 123, 456, []) == :unstore_response
  end
end
