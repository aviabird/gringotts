defmodule Kuber.Hex.Gateways.BogusTest do
  use ExUnit.Case

  alias Kuber.Hex.Response
  alias Kuber.Hex.Gateways.Bogus, as: Gateway

  test "authorize" do
    {:ok, %Response{authorization: authorization, success: success}} =
        Gateway.authorize(10.95, :card, [])

    assert success
    assert authorization != nil
  end

  test "purchase" do
    {:ok, %Response{authorization: authorization, success: success}} =
        Gateway.purchase(10.95, :card, [])

    assert success
    assert authorization != nil
  end

  test "capture" do
    {:ok, %Response{authorization: authorization, success: success}} =
        Gateway.capture(1234, [])

    assert success
    assert authorization != nil
  end

  test "void" do
    {:ok, %Response{authorization: authorization, success: success}} =
        Gateway.void(1234, [])

    assert success
    assert authorization != nil
  end

  test "store" do
    {:ok, %Response{success: success}} =
        Gateway.store(%Kuber.Hex.CreditCard{}, [])

    assert success
  end

  test "unstore with customer" do
    {:ok, %Response{success: success}} =
        Gateway.unstore(1234, nil, [])

    assert success
  end

  test "unstore with card" do
    {:ok, %Response{success: success}} =
        Gateway.unstore(nil, 456, [])

    assert success
  end
end
