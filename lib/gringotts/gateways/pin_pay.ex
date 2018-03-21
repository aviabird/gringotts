defmodule Gringotts.Gateways.Pinpay do
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
      options[
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

    params =
      [
        amount: value,
        capture: false
      ] ++ card_params(card, opts) ++ Keyword.delete(opts, :address)

    commit(:post, "charges", params, [{:currency, currency} | opts])
  end

  def authorize(amount, card, opts) do
    {currency, value, _} = Money.to_integer(amount)

    params =
      [
        amount: value,
        capture: false,
        card_token: card
      ] ++ Keyword.delete(opts, :address)

    commit(:post, "charges", params, [{:currency, currency} | opts])
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
    url = @test_url <> "/1/charges/" <> payment_id <> "/capture"
    commit(:put, url)
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

  ###############################################################################
  #                                PRIVATE METHODS                              #
  ###############################################################################

  # Makes the request to PinPay's network.
  # For consistency with other gateway implementations, make your (final)
  # network request in here, and parse it using another private method called
  # `respond`.

  defp card_params(card, opts) do
    [
      "card[number]": card.number,
      "card[name]": card.first_name <> card.last_name,
      "card[expiry_month]": card.month |> Integer.to_string() |> String.pad_leading(2, "0"),
      "card[expiry_year]": card.year |> Integer.to_string(),
      "card[cvc]": card.verification_code,
      "card[address_line1]": opts[:address].street1,
      "card[address_city]": opts[:address].city,
      "card[address_country]": opts[:address].country
    ]
  end

  @spec commit(atom, String.t(), keyword, keyword) :: {:ok | :error, Response}
  defp commit(:post, endpoint, param, opts) do
    auth_token = encoded_credentials("c4nxgznanW4XZUaEQhxS6g", "")

    headers = [
      {"Content-Type", "application/x-www-form-urlencoded"},
      {"Authorization", auth_token}
    ]

    url = @test_url <> "#{endpoint}"

    url
    |> HTTPoison.post({:form, param}, headers)
    |> respond
  end

  defp commit(method, url) do
    auth_token = encoded_credentials("c4nxgznanW4XZUaEQhxS6g", "")

    headers = [
      {"Content-Type", "application/x-www-form-urlencoded"},
      {"Authorization", auth_token}
    ]

    HTTPoison.request(method, url, [], headers)
    |> respond
  end

  defp encoded_credentials(login, password) do
    [login, password]
    |> join_string(":")
    |> Base.encode64()
    |> (&("Basic " <> &1)).()
  end

  defp join_string(list_of_words, joiner), do: Enum.join(list_of_words, joiner)

  # Parses PinPay's response and returns a `Gringotts.Response` struct
  # in a `:ok`, `:error` tuple.
  @spec respond(term) :: {:ok | :error, Response}

  defp respond({:ok, %{status_code: 200, body: body}}) do
    parsed = Poison.decode!(body)

    {:ok,
     %{
       success: true,
       id: Map.get(parsed, "token"),
       token: Map.get(parsed["card"], "token"),
       status_code: 201,
       reason: nil,
       message: "Card succesfully authorized",
       avs_result: nil,
       cvc_result: nil,
       raw: body,
       fraud_review: nil,
       email: Map.get(parsed, "email"),
       description: Map.get(parsed, "description")
     }}
  end

  defp respond({:ok, %{body: body, status_code: code}}) do
    {:error, %Response{raw: body, status_code: code}}
  end

  defp respond({:error, %HTTPoison.Error{} = error}) do
    {
      :error,
      %Response{
        reason: "network related failure",
        message: "HTTPoison says '#{error.reason}' [ID: #{error.id || "nil"}]"
      }
    }
  end
end
