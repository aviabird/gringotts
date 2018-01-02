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

  @spec amount(t) :: Decimal.t
  @doc """
  Returns a Decimal representing the "worth" of this sum of money in the
  associated `currency`.
  """
  def amount(money)
end

defimpl Gringotts.Money, for: Any do
  def currency(money), do: Map.get(money, :currency)
  def amount(money), do: Map.get(money, :amount)
end
