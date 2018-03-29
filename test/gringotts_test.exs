defmodule GringottsTest do
  use ExUnit.Case

  import Gringotts

  @test_config [
    some_auth_info: :merchant_secret_key,
    other_secret: :sun_rises_in_the_east
  ]

  @bad_config [some_auth_info: :merchant_secret_key]

  defmodule FakeGateway do
    use Gringotts.Adapter, required_config: [:some_auth_info, :other_secret]

    def authorize(100, :card, _) do
      :authorization_response
    end

    def purchase(100, :card, _) do
      :purchase_response
    end

    def capture(1234, 100, _) do
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

  setup do
    Application.put_env(:gringotts, GringottsTest.FakeGateway, @test_config)
    :ok
  end

  test "authorization" do
    assert authorize(GringottsTest.FakeGateway, 100, :card, []) == :authorization_response
  end

  test "purchase" do
    assert purchase(GringottsTest.FakeGateway, 100, :card, []) == :purchase_response
  end

  test "capture" do
    assert capture(GringottsTest.FakeGateway, 1234, 100, []) == :capture_response
  end

  test "void" do
    assert void(GringottsTest.FakeGateway, 1234, []) == :void_response
  end

  test "refund" do
    assert refund(GringottsTest.FakeGateway, 100, 1234, []) == :refund_response
  end

  test "store" do
    assert store(GringottsTest.FakeGateway, :card, []) == :store_response
  end

  test "unstore" do
    assert unstore(GringottsTest.FakeGateway, 123, []) == :unstore_response
  end

  test "validate_config when some required config is missing" do
    Application.put_env(:gringotts, GringottsTest.FakeGateway, @bad_config)

    assert_raise(
      ArgumentError,
      "expected [:other_secret] to be set, got: [some_auth_info: :merchant_secret_key]\n",
      fn -> authorize(GringottsTest.FakeGateway, 100, :card, []) end
    )
  end
end
