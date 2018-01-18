defprotocol Gringotts.Money do
  @moduledoc """
  Money protocol used by the Gringotts API.

  The `amount` argument required for some of Gringotts' API methods must
  implement this protocol.

  If your application is already using a supported Money library, just pass in
  the Money struct and things will work out of the box.

  Otherwise, just wrap your `amount` with the `currency` together in a `Map`
  like so,

      price = %{value: Decimal.new(20.18), currency: "USD"}

  and the API will accept it (as long as the currency is valid [ISO 4217
  currency code](https://www.iso.org/iso-4217-currency-codes.html)).

  ## Note on the `Any` implementation

  Both `to_string` and `to_integer` assume that the precision for the `currency`
  is 2 digits after decimal.
  """
  @fallback_to_any true
  @type t :: Gringotts.Money.t()

  @doc """
  Returns the ISO 4217 compliant currency code associated with this sum of money.

  This must be an UPCASE `string`
  """
  @spec currency(t) :: String.t()
  def currency(money)

  @doc """
  Returns a Decimal representing the "worth" of this sum of money in the
  associated `currency`.
  """
  @spec value(t) :: Decimal.t()
  def value(money)

  @doc """
  Returns the ISO4217 `currency` code as string and `value` as an integer.

  Useful for gateways that require amount as integer (like cents instead of dollars)

  ## Examples

      # the money lib is aliased as "MoneyLib"

      iex> usd_price = MoneyLib.new("4.1234", :USD)
      #MoneyLib<4.1234, "USD">
      iex> Gringotts.Money.to_integer(usd_price)
      {"USD", 412, -2}
      
      iex> bhd_price = MoneyLib.new("4.1234", :BHD)
      #MoneyLib<4.1234, "BHD">
      iex> Gringotts.Money.to_integer(bhd_price)
      {"BHD", 4123, -3}
      # the Bahraini dinar is divided into 1000 fils unlike the dollar which is
      # divided in 100 cents
  """
  @spec to_integer(Money.t()) ::
          {currency :: String.t(), value :: integer, exponent :: neg_integer}
  def to_integer(money)

  @doc """
  Returns a tuple of ISO4217 `currency` code and the `value` as strings.

  The `value` must match this regex: `~r[\\d+\\.\\d\\d{n}]` where `n+1` should
  match the required precision for the `currency`.

  > Gringotts will not (and cannot) validate this of course.

  ## Examples

      # the money lib is aliased as "MoneyLib"
      
      iex> usd_price = MoneyLib.new("4.1234", :USD)
      #MoneyLib<4.1234, "USD">
      iex> Gringotts.Money.to_string(usd_price)
      {"USD", "4.12"}
      
      iex> bhd_price = MoneyLib.new("4.1234", :BHD)
      #MoneyLib<4.1234, "BHD">
      iex> Gringotts.Money.to_string(bhd_price)
      {"BHD", "4.123"} 
  """
  @spec to_string(t) :: {currency :: String.t(), value :: String.t()}
  def to_string(money)
end

# this implementation is used for dispatch on ex_money (and will also fire for
# money)
if Code.ensure_compiled?(Money) do
  defimpl Gringotts.Money, for: Money do
    def currency(money), do: money.currency |> Atom.to_string()
    def value(money), do: money.amount

    def to_integer(money) do
      {_, int_value, exponent, _} = Money.to_integer_exp(money)
      {currency(money), int_value, exponent}
    end

    def to_string(money) do
      {:ok, currency_data} = Cldr.Currency.currency_for_code(currency(money))
      reduced = Money.reduce(money)

      {
        currency(reduced),
        value(reduced)
        |> Decimal.round(currency_data.digits)
        |> Decimal.to_string()
      }
    end
  end
end

if Code.ensure_compiled?(Monetized.Money) do
  defimpl Gringotts.Money, for: Monetized.Money do
    def currency(money), do: money.currency
    def value(money), do: money.amount
  end
end

# Assumes that the currency is subdivided into 100 units
defimpl Gringotts.Money, for: Any do
  def currency(%{currency: currency}), do: currency
  def value(%{value: %Decimal{} = value}), do: value

  def to_integer(%{value: %Decimal{} = value, currency: currency}) do
    {
      currency,
      value
      |> Decimal.mult(Decimal.new(100))
      |> Decimal.round(0)
      |> Decimal.to_integer(),
      -2
    }
  end

  def to_string(%{value: %Decimal{} = value, currency: currency}) do
    {
      currency,
      value |> Decimal.round(2) |> Decimal.to_string()
    }
  end
end
