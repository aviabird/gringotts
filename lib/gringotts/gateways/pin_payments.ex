defmodule Gringotts.Gateways.PinPayments do
  @moduledoc """
  [PinPayments][home] gateway implementation.

  The following features of PinPayments are implemented:

  | Action                       | Method        |
  | ------                       | ------        |
  | Authorize                    | `authorize/3` |
  | Capture                      | `capture/3`   |
  | Purchase                     | `purchase/3`  |
  | Store                        | `store/2`     |
  | Refund                       | `refund/3`    |

  ## The `opts` argument

  Most `Gringotts` API calls accept an optional `keyword` list `opts` to supply
  optional arguments for transactions with the PinPayments gateway. The following keys
  are supported:

  | Key               | Type       | Remark                                                                   |
  | ----              | ----       | ---                                                                      |
  | `address`         | `Address.t`| The address of the customer                                              |
  | `email_id`        | `String.t` | The email address of the purchaser.                                      |
  | `description`     | `String.t` | A description of the item purchased (e.g. 500g of single origin beans)   |
  | `ip_address`      | `String.t` | The IP address of the person submitting the payment(optional)            |

  > PinPayments supports more optional keys and you can raise [issues] if
    this is important to you.

  [issues]: https://github.com/aviabird/gringotts/issues/new

  ## Registering your PinPayments account at `Gringotts`

  | Config parameter | PinPayments secret    |
  | -------          | ----                  |
  | `:api_key`       | `**API_SECRET_KEY**`  |

  > Your Application config **must include the `:api_key`
  > fields** and would look something like this:

      config :gringotts, Gringotts.Gateways.Pinpay,
          api_key: "your_secret_key",
          

  * PinPayments **does** process money in cents.
  * Although PinPayments supports payments various cards. This module only
  accepts payments via `VISA`, `MASTER`, and `AMERICAN EXPRESS`.

  ## Supported countries
  PinPayments supports the countries listed 
  * Australia
  * New Zealand

  ## Supported currencies
  PinPayments supports the currencies listed [here](https://pinPayments.com/developers/api-reference/currency-support)

  ## Following the examples

  1. First, set up a sample application and configure it to work with PinPayments.
  - You could do that from scratch by following our [Getting Started][gs] guide.
  - To save you time, we recommend [cloning our example
  repo][example] that gives you a pre-configured sample app ready-to-go.
  + You could use the same config or update it the with your "secrets"
          as described [above](#module-registering-your-pinpayments-account-at-gringotts).

  2. Run an `iex` session with `iex -S mix` and add some variable bindings and
  aliases to it (to save some time):
  ```
  iex> alias Gringotts.{Response, CreditCard, Gateways.Pinpay}
  iex> card = %CreditCard{first_name: "Jo",
                          last_name: "Doe",
                          number: "4200000000000000",
                          year: 2099, month: 12,
                          verification_code: "123", brand: "VISA"}
  ```

  We'll be using these in the examples below.

  [gs]: https://github.com/aviabird/gringotts/wiki/
  [home]: https://pinPayments.com
  [docs]: https://pinPayments.com/developers/api-reference
  [example]: https://github.com/aviabird/gringotts_example
  """

  # The Base module has the (abstract) public API, and some utility
  # implementations.
  use Gringotts.Gateways.Base

  # The Adapter module provides the `validate_config/1`
  # Add the keys that must be present in the Application config in the
  # `required_config` list
  use Gringotts.Adapter, required_config: [:api_key]

  import Poison, only: [decode: 1]

  alias Gringotts.{Money, CreditCard, Response}

  @test_url "https://test-api.pinPayments.com/1/"

  @doc """
  Creates a new charge and returns its details.

  The authorization validates the `card` details with the banking network,
  places a hold on the transaction `amount` in the customer’s issuing bank.

  PinPayments returns a **Token Id** which can be used later to:
  * `capture/3` an amount.

  ## Example

  The following example shows how one would (pre) authorize a payment of $20 on
  a sample `card`.
  ```
  iex> card = %CreditCard{first_name: "Jo",
                          last_name: "Doe",
                          number: "4200000000000000",
                          year: 2099, month: 12,
                          verification_code: "123", brand: "VISA"}
  iex> money = Money.new(20, :USD)
  iex> {:ok, auth_result} = Gringotts.authorize(Gringotts.Gateways.PinPayments, amount, card, opts)
  ```
  """

 @spec authorize(Money.t(), CreditCard.t() | String.t(), keyword) :: {:ok | :error, Response}
  def authorize(amount, %CreditCard{} = card, opts) do
    {currency, value, _} = Money.to_integer(amount)

    with {:ok, card_token_response} <-
           commit(:post, "cards", card_for_token(card, opts) ++ Keyword.delete(opts, :address)),
         {:ok, card_token} <- extract_card_token(card_token_response) do
      params =
        [
          amount: value,
          capture: false,
          card_token: card_token,
          currency: currency
        ] ++ Keyword.delete(opts, :address)

      commit(:post, "charges", params)
    end
  end

  def authorize(amount, card_token, opts) when is_binary(card_token) do
    {currency, value, _} = Money.to_integer(amount)

    params =
      [
        amount: value,
        capture: false,
        currency: currency,
        card_token: card_token
      ] ++ Keyword.delete(opts, :address)

    commit(:post, "charges", params)
  end

  @doc """
  Transfers `amount` from the customer to the merchant.

  PinPayments attempts to process a purchase on behalf of the customer, by
  debiting `amount` from the customer's account by charging the customer's
  `card`.

  PinPayments returns a **Payment Id** which can be used later to:
  * `refund/3` the amount.

  ## Examples

  The following example shows how one would process a payment worth $20 in
  one-shot, without (pre) authorization.
  ```
  iex> card = %CreditCard{first_name: "Harry",
                          last_name: "Potter",
                          number: "4200000000000000",
                          year: 2099,
                          month: 12,
                          verification_code: "999",
                          brand: "VISA"}
  iex> money = Money.new(20, :USD)
  iex> {:ok, purchase_result} = Gringotts.purchase(Gringotts.Gateways.PinPayments, amount, card, opts)
  ```
  """

  @spec purchase(Money.t(), CreditCard.t() | String.t(), keyword) :: {:ok | :error, Response}
  def purchase(amount, %CreditCard{} = card, opts) do
    {currency, value, _} = Money.to_integer(amount)

    with {:ok, card_token_response} <-
           commit(:post, "cards", card_for_token(card, opts) ++ Keyword.delete(opts, :address)),
         {:ok, card_token} <- extract_card_token(card_token_response) do
      params =
        [
          amount: value,
          card_token: card_token,
          currency: currency
        ] ++ Keyword.delete(opts, :address)

      commit(:post, "charges", params)
    end
  end

  def purchase(amount, card_token, opts) when is_binary(card_token) do
    {currency, value, _} = Money.to_integer(amount)

    params =
      [
        amount: value,
        card_token: card_token,
        currency: currency
      ] ++ Keyword.delete(opts, :address)

    commit(:post, "charges", params)
  end

   @doc """
  Refunds the `amount` to the customer's account with reference to a prior transfer.

  PinPayments processes a full refund worth `amount`, referencing a
  previous `purchase/3` or `capture/3`.

  The end customer will usually see two bookings/records on his statement.

  ## Example
  ```
  iex> money = Money.new(20, :USD)
  iex> {:ok, refund_result} = Gringotts.refund(Gringotts.Gateways.PinPayments, payment_id, opts)
  ```
  """
  @spec refund( String.t(), keyword) :: {:ok | :error, Response}
  def refund(payment_id, opts) do
    url = @test_url <> "charges/#{payment_id}/refunds"

    commit_short(:post, url, opts)
  end

  @doc """
  Stores the payment-source data for later use.

  PinPayments can store the payment-source details, for example card or bank details
  which can be used to effectively process _One-Click_ and _Recurring_ payments,
  and return a card token for reference.

  ## Note

  * _One-Click_ and _Recurring_ payments are currently not implemented.
  * Payment details can be saved during a `purchase/3` or `capture/3`.

  ## Example

  The following example shows how one would store a card (a payment-source) for
  future use.
  ```
  iex> card = %CreditCard{first_name: "Harry",
                          last_name: "Potter",
                          number: "4200000000000000",
                          year: 2099,
                          month: 12,
                          verification_code: "999",
                          brand: "VISA"}
  iex> {:ok, store_result} = Gringotts.store(Gringotts.Gateways.PinPayments, card, opts)
  ```
  """

  @spec store(CreditCard.t(), keyword) :: {:ok | :error, Response}
  def store(%CreditCard{} = card, opts) do
    commit(:post, "cards", card_for_token(card, opts) ++ Keyword.delete(opts, :address))
  end

  ###############################################################################
  #                                PRIVATE METHODS                              #
  ###############################################################################

  # Makes the request to PinPay's network.
  # For consistency with other gateway implementations, make your (final)
  # network request in here, and parse it using another private method called
  # `respond`.

  defp card_for_token(card, opts) do
    [
      number: card.number,
      name: CreditCard.full_name(card),
      expiry_month: card.month |> Integer.to_string() |> String.pad_leading(2, "0"),
      expiry_year: card.year |> Integer.to_string(),
      cvc: card.verification_code,
      address_line1: opts[:address].street1,
      address_city: opts[:address].city,
      address_country: opts[:address].country,
      address_line2: opts[:address].street2,
      address_postcode: opts[:address].postal_code,
      address_state: opts[:address].region
    ]
  end

  @spec commit(atom, String.t(), keyword) :: {:ok | :error, Response}
  defp commit(:post, endpoint, param) do
    auth_token = encoded_credentials(param[:config].apiKey)

    headers = [
      {"Content-Type", "application/x-www-form-urlencoded"},
      {"Authorization", auth_token}
    ]

    url = @test_url <> "#{endpoint}"
    param = Keyword.delete(param, :config)

    url
    |> HTTPoison.post({:form, param}, headers)
    #|> respond
  end

  defp commit_short(method, url, opts) do
    auth_token = encoded_credentials(opts[:config].apiKey)

    headers = [
      {"Content-Type", "application/x-www-form-urlencoded"},
      {"Authorization", auth_token}
    ]

    HTTPoison.request(method, url, [], headers)
    |> respond
  end

  defp encoded_credentials(login) do
    hash = Base.encode64("#{login}:")
    "Basic #{hash}"
  end

  defp extract_card_token(%{id: token}) do
    {:ok, token}
  end

  defp extract_card_token({:error, error_response}) do
    {:error, error_response}
  end

  # Parses PinPay's response and returns a `Gringotts.Response` struct
  # in a `:ok`, `:error` tuple.
  @spec respond(term) :: {:ok | :error, Response}

  defp respond({:ok, %{status_code: code, body: body}}) when code in 200..299 do
    {:ok, parsed} = decode(body)

    token = parsed["response"]["card"]["token"]
    id = parsed["response"]["token"]
    message = parsed["response"]["status_message"]

    {
      :ok,
      Response.success(
        id: id,
        token: token,
        message: message,
        raw: parsed,
        status_code: code
      )
    }
  end

  defp respond({:ok, %{status_code: status_code, body: body}}) do
    {:ok, parsed} = decode(body)
    detail = parsed["detail"]
    {:error, Response.error(status_code: status_code, message: detail, raw: parsed)}
  end

  defp respond({:error, %HTTPoison.Error{} = error}) do
    {:error, Response.error(code: error.id, message: "HTTPoison says '#{error.reason}'")}
  end
end
