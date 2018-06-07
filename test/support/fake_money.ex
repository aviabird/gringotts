defmodule Gringotts.FakeMoney do
  @moduledoc """
  Defines a Gringotts.Money compliant money struct.

  Implements the gringotts protocol and does nothing else.
  """

  defstruct [:amount_field, :currency_field]

  def new(amount, currency) when is_atom(currency) do
    struct(__MODULE__, amount_field: Decimal.new(amount), currency_field: currency)
  end
end

defimpl Gringotts.Money, for: Gringotts.FakeMoney do
  def currency(money_struct), do: money_struct.currency_field
  def value(money_struct), do: money_struct.amount_field

  def to_integer(money_struct) do
    {
      money_struct.currency_field,
      money_struct.amount_field
      |> Decimal.mult(100)
      |> Decimal.to_integer(),
      -2
    }
  end

  def to_string(money_struct) do
    {
      Atom.to_string(money_struct.currency_field),
      money_struct.amount_field
      |> Decimal.round(2)
      |> Decimal.to_string()
    }
  end
end
