defprotocol Gringotts.Money do
  @moduledoc """
  Money protocol used by the Gringotts API.

  The `amount` argument required for some of Gringotts' API methods must
  implement this protocol.

  If your application is already using a supported Money library, just pass in
  the Money struct and things will work out of the box.

  Otherwise, just wrap your `amount` with the `currency` together in a `Map` like so,
      money = %{amount: Decimal.new(2017.18), currency: "USD"}

  and the API will accept it (as long as the currency is valid [ISO 4217 currency
  code](https://www.iso.org/iso-4217-currency-codes.html)).
  """
  @fallback_to_any true
  @type t :: Gringotts.Money.t
  
  @spec currency(t) :: String.t
  @doc """
  Returns the ISO 4217 compliant currency code associated with this sum of money.

  This must be an UPCASE `string`
  """
  def currency(money)

  @spec value(t) :: Decimal.t
  @doc """
  Returns a Decimal representing the "worth" of this sum of money in the
  associated `currency`.
  """
  def value(money)
end

# this implementation is used for dispatch on ex_money (and will also fire for
# money)
if Code.ensure_compiled?(Money) do
  defimpl Gringotts.Money, for: Money do
    def currency(money), do: money.currency |> Atom.to_string
    def value(money), do: money.amount
  end  
end

if Code.ensure_compiled?(Monetized.Money) do
  defimpl Gringotts.Money, for: Monetized.Money do
    def currency(money), do: money.currency
    def value(money), do: money.amount
  end
end

defimpl Gringotts.Money, for: Any do
  def currency(money), do: Map.get(money, :currency)
  def value(money), do: Map.get(money, :amount) || Map.get(money, :value)
end
