defmodule Gringotts.Integration.Gateways.MoneyTest do
  use ExUnit.Case, async: true

  alias Gringotts.Money, as: MoneyProtocol

  @moduletag :integration
  
  @ex_money Money.new(42, :EUR)
  
  describe "ex_money" do
    test "amount is a Decimal.t" do
      assert match? %Decimal{}, MoneyProtocol.value(@ex_money) 
    end

    test "currency is a String.t" do
      assert match? currency when is_binary(currency), MoneyProtocol.currency(@ex_money)
    end
  end
end
