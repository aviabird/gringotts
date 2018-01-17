defmodule Gringotts.Integration.Gateways.MoneyTest do
  use ExUnit.Case, async: true

  alias Gringotts.Money, as: MoneyProtocol

  @moduletag :integration
  
  @ex_money Money.new(42, :EUR)
  @ex_money_long Money.new("42.126456", :EUR)
  @ex_money_bhd Money.new(42, :BHD)
  
  describe "ex_money" do
    test "value is a Decimal.t" do
      assert match? %Decimal{}, MoneyProtocol.value(@ex_money) 
    end

    test "currency is an upcase String.t" do
      the_currency = MoneyProtocol.currency(@ex_money)
      assert match? currency when is_binary(currency), the_currency
      assert the_currency == String.upcase(the_currency)
    end

    test "to_integer" do
      assert match? {"EUR", 4200, -2}, MoneyProtocol.to_integer(@ex_money)
      assert match? {"BHD", 42000, -3}, MoneyProtocol.to_integer(@ex_money_bhd)
    end

    test "to_string" do
      assert match? {"EUR", "42.00"}, MoneyProtocol.to_string(@ex_money)
      assert match? {"EUR", "42.13"}, MoneyProtocol.to_string(@ex_money_long)
      assert match? {"BHD", "42.000"}, MoneyProtocol.to_string(@ex_money_bhd)
    end
  end
end
