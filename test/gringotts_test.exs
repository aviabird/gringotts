defmodule GringottsTest do
  use ExUnit.Case

  alias Gringotts.Worker
  import Gringotts

  defmodule FakeGateway do
    use Gringotts.Adapter, required_config: [:some_auth_info]

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

    def unstore(123, _) do
      :unstore_response
    end
  end

  setup_all do
    Application.put_env(:gringotts, GringottsTest.FakeGateway, [
          adapter: GringottsTest.FakeGateway,
          some_auth_info: :merchant_secret_key])
    :ok
  end

  test "authorization" do
    assert authorize(:payment_worker, GringottsTest.FakeGateway, 100, :card, []) == :authorization_response
  end

  test "purchase" do
    assert purchase(:payment_worker, GringottsTest.FakeGateway, 100, :card, []) == :purchase_response
  end

  test "capture" do
    assert capture(:payment_worker, GringottsTest.FakeGateway, 1234, 100,[]) == :capture_response
  end

  test "void" do
    assert void(:payment_worker, GringottsTest.FakeGateway, 1234, []) == :void_response
  end

  test "refund" do
    assert refund(:payment_worker, GringottsTest.FakeGateway, 100, 1234, []) == :refund_response
  end

  test "store" do
    assert store(:payment_worker, GringottsTest.FakeGateway, :card, []) == :store_response
  end

  test "unstore" do
    assert unstore(:payment_worker, GringottsTest.FakeGateway, 123, []) == :unstore_response
  end
end
