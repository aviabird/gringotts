defprotocol Gringotts.Money do
  @moduledoc """
  Money protocol used by the Gringotts API.

  The `amount` argument required for some of Gringotts' API methods must
  implement this protocol.

  If your application is already using a supported Money library, just pass in
  the Money struct and things will work out of the box.

  Otherwise, just wrap your `amount` with the `currency` together in a `Map`
  like so,

      price = %{value: Decimal.new("20.18"), currency: "USD"}

  and the API will accept it (as long as the currency is valid [ISO 4217
  currency code](https://www.iso.org/iso-4217-currency-codes.html)).

  ## Note on the `Any` implementation

  Both `to_string/1` and `to_integer/1` assume that the precision for the `currency`
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
  Returns a `Decimal.t` representing the "worth" of this sum of money in the
  associated `currency`.
  """
  @spec value(t) :: Decimal.t()
  def value(money)

  @doc """
  Returns the ISO4217 `currency` code as string and `value` as an integer.

  Useful for gateways that require amount as integer (like cents instead of
  dollars).

  ## Note

  Conversion from `Decimal.t` to `integer` is potentially lossy and the rounding
  (if required) is performed (automatically) by the Money library defining the
  type, or in the implementation of this protocol method.

  If you want to implement this method for your custom type, please ensure that
  the rounding strategy (if any rounding is applied) must be
  [`half_even`][wiki-half-even].

  **To keep things predictable and transparent, merchants should round the
  `amount` themselves**, perhaps by explicitly calling the relevant method of
  the Money library in their application _before_ passing it to `Gringotts`'s
  public API.

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

  [wiki-half-even]: https://en.wikipedia.org/wiki/Rounding#Round_half_to_even
  """
  @spec to_integer(Money.t()) ::
          {currency :: String.t(), value :: integer, exponent :: neg_integer}
  def to_integer(money)

  @doc """
  Returns a tuple of ISO4217 `currency` code and the `value` as strings.

  The stringified `value` must match this regex: `~r/-?\\d+\\.\\d\\d{n}/` where
  `n+1` should match the required precision for the `currency`. There should be
  no place value separators except the decimal point (like commas).

  > Gringotts will not (and cannot) validate this of course.

  ## Note

  Conversion from `Decimal.t` to `string` is potentially lossy and the rounding
  (if required) is performed (automatically) by the Money library defining the
  type, or in the implementation of this protocol method.

  If you want to implement this method for your custom type, please ensure that
  the rounding strategy (if any rounding is applied) must be
  [`half_even`][wiki-half-even].

  **To keep things predictable and transparent, merchants should round the
  `amount` themselves**, perhaps by explicitly calling the relevant method of
  the Money library in their application _before_ passing it to `Gringotts`'s
  public API.

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

  [wiki-half-even]: https://en.wikipedia.org/wiki/Rounding#Round_half_to_even
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
