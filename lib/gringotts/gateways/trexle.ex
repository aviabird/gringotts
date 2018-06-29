defmodule Gringotts.Gateways.Trexle do
  @moduledoc """
  [Trexle][home] Payment Gateway implementation.

  > For further details, please refer [Trexle API documentation][docs].

  Following are the features that have been implemented for the Trexle Gateway:

  | Action                       | Method        |
  | ------                       | ------        |
  | Authorize                    | `authorize/3` |
  | Purchase                     | `purchase/3`  |
  | Capture                      | `capture/3`   |
  | Refund                       | `refund/3`    |
  | Store                        | `store/2`     |

  ## PCI compliance is mandatory!

  _You, the merchant needs to be PCI-DSS Compliant if you wish to use this
  module! Your server will recieve sensitive card and customer information._

  ## The `opts` argument

  Most `Gringotts` API calls accept an optional `keyword` list `opts` to supply
  optional arguments for transactions with Trexle. The following keys are
  supported:

  * `email`
  * `ip_address`
  * `description`

  [docs]: https://docs.trexle.com/
  [home]: https://trexle.com/

  ## Registering your Trexle account at `Gringotts`

  After [creating your account][dashboard] successfully on Trexle, head to the dashboard and find
  your account "secrets" in the [`API keys`][keys] section.

  Here's how the secrets map to the required configuration parameters for Trexle:

  | Config parameter | Trexle secret   |
  | -------          | ----            |
  | `:api_key`       | **API key**     |

  Your Application config must look something like this:

      config :gringotts, Gringotts.Gateways.Trexle,
          api_key: "your-secret-API-key"

  [dashboard]: https://trexle.com/dashboard/
  [keys]: https://trexle.com/dashboard/api-keys

  ## Scope of this module

  * Trexle processes money in cents.**citation-needed**.

  ## Supported Gateways

  Find the official [list here][gateways].

  [gateways]: https://trexle.com/payment-gateway

  ## Following the examples

  1. First, set up a sample application and configure it to work with Trexle.
  - You could do that from scratch by following our [Getting Started][gs] guide.
      - To save you time, we recommend [cloning our example repo][example-repo]
        that gives you a pre-configured sample app ready-to-go.
        + You could use the same config or update it the with your "secrets"
          that as described
          [above](#module-registering-your-trexle-account-at-gringotts).

  2. To save a lot of time, create a [`.iex.exs`][iex-docs] file as shown in
     [this gist][trexle.iex.exs] to introduce a set of handy bindings and
     aliases.

  We'll be using these bindings in the examples below.

  [example-repo]: https://github.com/aviabird/gringotts_example
  [iex-docs]: https://hexdocs.pm/iex/IEx.html#module-the-iex-exs-file
  [trexle.iex.exs]: https://gist.github.com/oyeb/055f40e9ad4102f5480febd2cfa00787
  [gs]: https://github.com/aviabird/gringotts/wiki
  """

  @base_url "https://core.trexle.com/api/v1/"

  use Gringotts.Gateways.Base
  use Gringotts.Adapter, required_config: [:api_key]
  import Poison, only: [decode: 1]
  alias Gringotts.{Address, CreditCard, Money, Response}

  @doc """
  Performs a (pre) Authorize operation.

  The authorization validates the `card` details with the banking network,
  places a hold on the transaction `amount` in the customer’s issuing bank and
  also triggers risk management. Funds are not transferred.

  Trexle returns a "charge token", avaliable in the `Response.id`
  field, which can be used in future to perform a `capture/3`.

  ### Example

  The following session shows how one would (pre) authorize a payment of $100 on
  a sample `card`.

  ```
  iex> amount = Money.new(100, :USD)
  iex> card = %CreditCard{
               first_name: "Harry",
               last_name: "Potter",
               number: "5200828282828210",
               year: 2099, month: 12,
               verification_code: "123",
               brand: "VISA"}
  iex> address = %Address{
                  street1: "301, Gryffindor",
                  street2: "Hogwarts School of Witchcraft and Wizardry, Hogwarts Castle",
                  city: "Highlands",
                  region: "SL",
                  country: "GB",
                  postal_code: "11111",
                  phone: "(555)555-5555"}
  iex> options = [email: "masterofdeath@ministryofmagic.gov",
                  ip_address: "127.0.0.1",
                  billing_address: address,
                  description: "For our valued customer, Mr. Potter"]
  iex> Gringotts.authorize(Gringotts.Gateways.Trexle, amount, card, options)
  ```
  """
  @spec authorize(Money.t(), CreditCard.t(), keyword) :: {:ok | :error, Response}
  def authorize(amount, payment, opts \\ []) do
    params = create_params_for_auth_or_purchase(amount, payment, opts, false)
    commit(:post, "charges", params, opts)
  end

  @doc """
  Captures a pre-authorized `amount`.

  `amount` is transferred to the merchant account by Trexle when it is smaller or
  equal to the amount used in the pre-authorization referenced by `charge_token`.

  Trexle returns a "charge token", avaliable in the `Response.id`
  field, which can be used in future to perform a `refund/2`.

  ## Note

  Multiple captures cannot be performed on the same "charge token". If the
  captured amount is smaller than the (pre) authorized amount, the "un-captured"
  amount is released.**citation-needed**

  ## Example

  The following example shows how one would (partially) capture a previously
  authorized a payment worth $10 by referencing the obtained `charge_token`.

  ```
  iex> amount = Money.new(10, :USD)
  iex> token = "some-real-token"
  iex> Gringotts.capture(Gringotts.Gateways.Trexle, token, amount)
  ```
  """
  @spec capture(String.t(), Money.t(), keyword) :: {:ok | :error, Response}
  def capture(charge_token, amount, opts \\ []) do
    {_, int_value, _} = Money.to_integer(amount)
    params = [amount: int_value]
    commit(:put, "charges/#{charge_token}/capture", params, opts)
  end

  @doc """
  Transfers `amount` from the customer to the merchant.

  Trexle attempts to process a purchase on behalf of the customer, by debiting
  `amount` from the customer's account by charging the customer's `card`.

  ## Example

  The following session shows how one would process a payment worth $100 in
  one-shot, without (pre) authorization.

  ```
  iex> amount = Money.new(100, :USD)
  iex> card = %CreditCard{
               first_name: "Harry",
               last_name: "Potter",
               number: "5200828282828210",
               year: 2099, month: 12,
               verification_code: "123",
               brand: "VISA"}
  iex> address = %Address{
                  street1: "301, Gryffindor",
                  street2: "Hogwarts School of Witchcraft and Wizardry, Hogwarts Castle",
                  city: "Highlands",
                  region: "SL",
                  country: "GB",
                  postal_code: "11111",
                  phone: "(555)555-5555"}
  iex> options = [email: "masterofdeath@ministryofmagic.gov",
                  ip_address: "127.0.0.1",
                  billing_address: address,
                  description: "For our valued customer, Mr. Potter"]
  iex> Gringotts.purchase(Gringotts.Gateways.Trexle, amount, card, options)
  ```
  """
  @spec purchase(Money.t(), CreditCard.t(), keyword) :: {:ok | :error, Response}
  def purchase(amount, payment, opts \\ []) do
    params = create_params_for_auth_or_purchase(amount, payment, opts)
    commit(:post, "charges", params, opts)
  end

  @doc """
  Refunds the amount to the customer's card with reference to a prior transfer.

  Trexle processes a full or partial refund worth `amount`, referencing a
  previous `purchase/3` or `capture/3`.

  Trexle returns a "refund token", avaliable in the `Response.id`
  field.

  Multiple, partial refunds can be performed on the same "charge token"
  referencing a previous `purchase/3` or `capture/3` till the cumulative refunds
  equals the `capture/3`d or `purchase/3`d amount.

  ## Example

  The following session shows how one would refund $100 of a previous
  `purchase/3` (and similarily for `capture/3`s).

  ```
  iex> amount = Money.new(100, :USD)
  iex> token = "some-real-token"
  iex> Gringotts.refund(Gringotts.Gateways.Trexle, amount, token)
  ```
  """
  @spec refund(Money.t(), String.t(), keyword) :: {:ok | :error, Response}
  def refund(amount, charge_token, opts \\ []) do
    {_, int_value, _} = Money.to_integer(amount)
    params = [amount: int_value]
    commit(:post, "charges/#{charge_token}/refunds", params, opts)
  end

  @doc """
  Stores the card information for future use.

  ## Example

  The following session shows how one would store a card (a payment-source) for
  future use.
  ```
  iex> card = %CreditCard{
               first_name: "Harry",
               last_name: "Potter",
               number: "5200828282828210",
               year: 2099, month: 12,
               verification_code: "123",
               brand: "VISA"}
  iex> address = %Address{
                  street1: "301, Gryffindor",
                  street2: "Hogwarts School of Witchcraft and Wizardry, Hogwarts Castle",
                  city: "Highlands",
                  region: "SL",
                  country: "GB",
                  postal_code: "11111",
                  phone: "(555)555-5555"}
  iex> options = [email: "masterofdeath@ministryofmagic.gov",
                  ip_address: "127.0.0.1",
                  billing_address: address,
                  description: "For our valued customer, Mr. Potter"]
  iex> Gringotts.store(Gringotts.Gateways.Trexle, card, options)
  ```
  """
  @spec store(CreditCard.t(), keyword) :: {:ok | :error, Response}
  def store(payment, opts \\ []) do
    params =
      [email: opts[:email]] ++ card_params(payment) ++ address_params(opts[:billing_address])

    commit(:post, "customers", params, opts)
  end

  defp create_params_for_auth_or_purchase(amount, payment, opts, capture \\ true) do
    {currency, int_value, _} = Money.to_integer(amount)

    [
      capture: capture,
      amount: int_value,
      currency: currency,
      email: opts[:email],
      ip_address: opts[:ip_address],
      description: opts[:description]
    ] ++ card_params(payment) ++ address_params(opts[:billing_address])
  end

  defp card_params(%CreditCard{} = card) do
    [
      "card[name]": CreditCard.full_name(card),
      "card[number]": card.number,
      "card[expiry_year]": card.year,
      "card[expiry_month]": card.month,
      "card[cvc]": card.verification_code
    ]
  end

  defp address_params(%Address{} = address) do
    [
      "card[address_line1]": address.street1,
      "card[address_line2]": address.street2,
      "card[address_city]": address.city,
      "card[address_postcode]": address.postal_code,
      "card[address_state]": address.region,
      "card[address_country]": address.country
    ]
  end

  defp commit(method, path, params, opts) do
    auth_token = "Basic #{Base.encode64(opts[:config][:api_key])}"

    headers = [
      {"Content-Type", "application/x-www-form-urlencoded"},
      {"Authorization", auth_token}
    ]

    options = [basic_auth: {opts[:config][:api_key], "password"}]
    url = "#{base_url(opts)}#{path}"
    response = HTTPoison.request(method, url, {:form, params}, headers, options)
    response |> respond
  end

  @spec respond(term) :: {:ok | :error, Response}
  defp respond(response)

  defp respond({:ok, %{status_code: code, body: body}}) when code in [200, 201] do
    {:ok, results} = decode(body)
    token = results["response"]["token"]
    message = results["response"]["status_message"]

    {
      :ok,
      %Response{id: token, message: message, raw: body, status_code: code}
    }
  end

  defp respond({:ok, %{status_code: code, body: body}}) when code in [401] do
    {
      :error,
      %Response{reason: "Unauthorized access.", message: "Unauthorized access", raw: body}
    }
  end

  defp respond({:ok, %{status_code: status_code, body: body}}) do
    {:ok, results} = decode(body)
    detail = results["detail"]
    {:error, %Response{status_code: status_code, message: detail, reason: detail, raw: body}}
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

  defp base_url(opts), do: opts[:test_url] || @base_url
end
