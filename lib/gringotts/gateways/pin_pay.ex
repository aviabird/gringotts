defmodule Gringotts.Gateways.PinPayments do
  @moduledoc """
  [PinPay][home] gateway implementation.

  The login credentials are:

  | Key      | Credentials        |
  | ------   | --------           |
  | username | `api_key`          |
  | password | ``                 |


  The following features of PinPayments are implemented:

  | Action                       | Method        |
  | ------                       | ------        |
  | Authorize                    | `authorize/3` |
  | Capture                      | `capture/3`   |
  | Purchase                     | `purchase/3`  |
  | Store                        | `store/2`     |
  | Refund                       | `refund/3`    |
  | Respond                      | `respond/1`   |


   ## The `opts` argument

  Most `Gringotts` API calls accept an optional `keyword` list `opts` to supply
  optional arguments for transactions with the PINPAY gateway. The following keys
  are supported:

  | Key               | Type       | Remark                                           |
  | ----              | ----       | ---                                              |
  | `address`         | `map`      | The address of the customer                      |
  | `email_id`        | `String.t` | Merchant provided email addres                   |
  | `description`     | `String.t` | Merchant provided description of the transaction |
  | `ip_address`      | `String.t` | Merchant provided ip address (optional)                     |


  > PINPAY supports more optional keys and you can raise an [issue][issues] if
    this is important to you.

  [issues]: https://github.com/aviabird/gringotts/issues/new


  ### Schema

  * `address` is a `map` from `atoms` to `String.t`, and can include any
    of the keys from:
    `[:street1, :street2, :city, :region, :postal_code, :country, :phone, ]`


  ## Registering your PINPAY account at `Gringotts`

  | Config parameter | PINPAY secret       |
  | -------          | ----              |
  | `:username`      | **API_SECRET_KEY**  |
  | `:password`      | Empty string        |

  > Your Application config **must include the `:username`, `:password`
  > fields** and would look something like this:

      config :gringotts, Gringotts.Gateways.Pinpay,
          username: "your_secret_key",
          password: "",

  * PINPAY **does not** process money in cents.
  * Although PINPAY supports payments various cards. This module only
  accepts payments via `VISA`, `MASTER`, and `AMERICAN EXPRESS`.

  ## Supported countries
  PINPAY supports the countries listed [here][all-country-list]
  $ AUD, $ USD, $ NZD, $ SGD, € EUR, £ GBP, $ CAD, ¥ JPY

  ## Supported currencies
  PINPAY supports the currencies listed [here][all-currency-list]
  :AUD, :USD, :NZD, :SGD, :EUR, :GBP, :CAD, :HKD, :JPY, :MYR, :THB, :PHP, :ZAR, :IDR, :TWD


  ## Following the examples

  1. First, set up a sample application and configure it to work with Monei.
  - You could do that from scratch by following our [Getting Started][gs] guide.
      - To save you time, we recommend [cloning our example
      repo][example] that gives you a pre-configured sample app ready-to-go.
          + You could use the same config or update it the with your "secrets"
          as described [above](#module-registering-your-monei-account-at-PinPay).

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

  > Add any other frequently used bindings up here.

  We'll be using these in the examples below.

  [gs]: https://github.com/aviabird/gringotts/wiki/
  [home]: https://pinpayments.com
  [docs]: https://pinpayments.com/developers/api-reference
  [example]: https://github.com/aviabird/gringotts_example
  """

  # The Base module has the (abstract) public API, and some utility
  # implementations.  
  use Gringotts.Gateways.Base

  # The Adapter module provides the `validate_config/1`
  # Add the keys that must be present in the Application config in the
  # `required_config` list
  use Gringotts.Adapter, required_config: []

  import Poison, only: [decode: 1]

  alias Gringotts.{Money, CreditCard, Response}

  @test_url "https://test-api.pinpayments.com/1/"
  @production_url "https://api.pinpayments.com/1/"

  @doc """
  Performs a (pre) Authorize operation.

  The authorization validates the `card` details with the banking network,
  places a hold on the transaction `amount` in the customer’s issuing bank.

  > ** You could perhaps:**
  > 1. describe what are the important fields in the Response struct
  > 2. mention what a merchant can do with these important fields (ex:
  > `capture/3`, etc.)

  PINPAY returns a **Payment Id** (available in the `Response.authorization`
  field) which can be used later to:
  * `capture/3` an amount.
  * `refund/3` the amount.

  ## Optional Fields
      options=[
        email_id: String,
        description: String,
  ip_address: String (optional)     
      ]




  ## Example

  The following example shows how one would (pre) authorize a payment of $20 on
  a sample `card`.
  ```
  iex> card = %CreditCard{first_name: "Jo",
                          last_name: "Doe",
                          number: "4200000000000000",
                          year: 2099, month: 12,
                          verification_code: "123", brand: "VISA"}
  iex> money = %{value: Decimal.new(20), currency: "USD"}
  iex> {:ok, auth_result} = Gringotts.authorize(Gringotts.Gateways.Pinpay, money, card)
  ```
  """

  @spec authorize(Money.t(), CreditCard.t(), keyword) :: {:ok | :error, Response}
  def authorize(amount, %CreditCard{} = card, opts) do
    {currency, value, _} = Money.to_integer(amount)

    card_token = commit(:post, "cards", card_for_token(card, opts) ++ Keyword.delete(opts, :address))
    |> extract_card_token
    params =
      [
        amount: value,
        capture: false,
        card_token: card_token,
        currency: currency
      ] ++ Keyword.delete(opts, :address)

    commit(:post, "charges", params)
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
  Captures a pre-authorized `amount`.

  `amount` is transferred to the merchant account by PinPay used in the
  pre-authorization referenced by `payment_id`.

  ## Note

  > If there's anything noteworthy about this operation, it comes here.
  > For example, does the gateway support partial, multiple captures?

  ## Example

  > A barebones example using the bindings you've suggested in the `moduledoc`.
  """
  @spec capture(String.t(), Money.t(), keyword) :: {:ok | :error, Response}
  def capture(payment_id, amount, opts) do
    url = @test_url <> "charges/" <> payment_id <> "/capture"
    commit(:put, url, opts)
  end

  @doc """
  Transfers `amount` from the customer to the merchant.

  PinPay attempts to process a purchase on behalf of the customer, by
  debiting `amount` from the customer's account by charging the customer's
  `card`.

  ## Note

  > If there's anything noteworthy about this operation, it comes here.

  ## Example

  > A barebones example using the bindings you've suggested in the `moduledoc`.
  """
  @spec purchase(Money.t, CreditCard.t(), keyword) :: {:ok | :error, Response}
  def purchase(amount, card = %CreditCard{}, opts) do
    {currency, value, _} = Money.to_integer(amount)

    card_token = commit(:post, "cards", card_for_token(card, opts) ++ Keyword.delete(opts, :address))
    |> extract_card_token
    params =
      [
        amount: value,
        card_token: card_token,
        currency: currency
      ] ++ Keyword.delete(opts, :address)

    commit(:post, "charges", params)
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
  Voids the referenced payment.

  This method attempts a reversal of a previous transaction referenced by
  `payment_id`.

  > As a consequence, the customer will never see any booking on his statement.

  ## Note

  > Which transactions can be voided?
  > Is there a limited time window within which a void can be perfomed?

  ## Example

  > A barebones example using the bindings you've suggested in the `moduledoc`.
  """
  @spec void(String.t(), keyword) :: {:ok | :error, Response}
  def void(payment_id, opts) do
    #can't be implemented in pinpayments
  end

  @doc """
  Refunds the `amount` to the customer's account with reference to a prior transfer.

  > Refunds are allowed on which kinds of "prior" transactions?

  ## Note

  > The end customer will usually see two bookings/records on his statement. Is
  > that true for PinPay?
  > Is there a limited time window within which a void can be perfomed?

  ## Example

  > A barebones example using the bindings you've suggested in the `moduledoc`.
  """
  @spec refund(Money.t, String.t(), keyword) :: {:ok | :error, Response}
  def refund(amount, payment_id, opts) do
    url=@test_url <> "charges/" <> payment_id <> "/refunds"
    commit(:post, url, opts)
  end


  @doc """
  Stores the payment-source data for later use.

  > This usually enable "One Click" and/or "Recurring Payments"

  ## Note

  > If there's anything noteworthy about this operation, it comes here.

  ## Example

  > A barebones example using the bindings you've suggested in the `moduledoc`.
  """
  
  @spec store(CreditCard.t(), keyword) :: {:ok | :error, Response}
  def store(%CreditCard{} = card, opts) do
    commit(:post, "cards", card_for_token(card, opts) ++ opts)
  end

  @doc """
  Removes card or payment info that was previously `store/2`d

  Deletes previously stored payment-source data.

  ## Note

  > If there's anything noteworthy about this operation, it comes here.

  ## Example

  > A barebones example using the bindings you've suggested in the `moduledoc`.
  """
  @spec unstore(String.t(), keyword) :: {:ok | :error, Response}
  def unstore(registration_id, opts) do
    # can't be implemented in pinpayments
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
      "number": card.number,
      "name": CreditCard.full_name(card),
      "expiry_month": card.month |> Integer.to_string() |> String.pad_leading(2, "0"),
      "expiry_year": card.year |> Integer.to_string(),
      "cvc": card.verification_code,
      "address_line1": opts[:Address][:street1],
      "address_city": opts[:Address][:city],
      "address_country": opts[:Address][:country]
    ]
  end

  @spec commit(atom, String.t(), keyword) :: {:ok | :error, Response}
  defp commit(:post, endpoint, param) do
    auth_token = encoded_credentials(param[:config].apiKey, param[:config].pass)

    headers = [
      {"Content-Type", "application/x-www-form-urlencoded"},
      {"Authorization", auth_token}
    ]

    url = @test_url <> "#{endpoint}"
    param = Keyword.delete(param, :config)
    url
    |> HTTPoison.post({:form, param}, headers)
    |> respond
  end

  defp commit(method, url, opts) do
    auth_token = encoded_credentials(opts[:config].apiKey, opts[:config].pass)

    headers = [
      {"Content-Type", "application/x-www-form-urlencoded"},
      {"Authorization", auth_token}
    ]

    HTTPoison.request(method, url, [], headers)
    |> respond
  end

  defp encoded_credentials(login, password) do
    hash = Base.encode64("#{login}:#{password}")
    "Basic #{hash}"
  end

  defp extract_card_token({:ok, %{status_code: code, authorization: token}}) do
   token
  end

  # Parses PinPay's response and returns a `Gringotts.Response` struct
  # in a `:ok`, `:error` tuple.
  @spec respond(term) :: {:ok | :error, Response}

  defp respond({:ok, %{status_code: code, body: body}}) when code in [200, 201] do
    {:ok, parsed} = decode(body)
    token = parsed["response"]["token"]
    message = parsed["response"]["status_message"]
    {
      :ok, Response.success(authorization: token, message: message, raw: parsed, status_code: code)
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
