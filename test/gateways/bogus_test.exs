defmodule Gringotts.Gateways.BogusTest do
  use ExUnit.Case

  alias Gringotts.Response
  alias Gringotts.Gateways.Bogus, as: Gateway

  @some_id "some_arbitrary_id"
  @amount Money.new(5, :USD)

  test "authorize" do
    {:ok, %Response{id: id, success: success}} = Gateway.authorize(@amount, :card, [])

    assert success
    assert id != nil
  end

  test "purchase" do
    {:ok, %Response{id: id, success: success}} = Gateway.purchase(@amount, :card, [])

    assert success
    assert id != nil
  end

  test "capture" do
    {:ok, %Response{id: id, success: success}} = Gateway.capture(@some_id, @amount, [])

    assert success
    assert id != nil
  end

  test "void" do
    {:ok, %Response{id: id, success: success}} = Gateway.void(@some_id, [])

    assert success
    assert id != nil
  end

  test "store" do
    {:ok, %Response{success: success}} = Gateway.store(%Gringotts.CreditCard{}, [])

    assert success
  end

  test "unstore with customer" do
    {:ok, %Response{success: success}} = Gateway.unstore(@some_id, [])

    assert success
  end
end
