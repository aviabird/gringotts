defmodule Gringotts.Gateways.SagePay do
  @moduledoc """
  [SagePay][home] gateway implementation.

  Most `Gringotts` API calls accept an optional `Keyword` list `opts` to supply
  optional arguments for transactions with the gateway.

  The following features of SagePay are implemented:

  | Action                       | Method        | 
  | ------                       | ------        | 
  | Authorize                    | `authorize/3` | 
  | Release                      | `capture/3`   | 
  | Refund                       | `refund/3`    | 
  | Reversal                     | `void/2`      | 
  | Purchase                     | `purchase/3`  | 

  [home]: http://sagepay.co.uk
  [docs]: integrations.sagepay.co.uk

  ## The `opts` argument

  Most `Gringotts` API calls accept an optional `keyword` list `opts` to supply
  optional arguments for transactions with the SagePay gateway. 

  The following keys are **mandatory**:

  |  Key                   |  Remarks                                                                    |
  |  ---                   |  -------                                                                    |
  |  `first_name`          |  First name of a customer.                                                  |
  |  `last_name`           |  Last name of a customer.                                                   |
  |  `billing_address`     |  Billing address of a customer.                                             |
  |  `vendor_tx_code`      |  A unique code merchant provided identifier for every transaction\
                              in SagePay.                                                                |

  ## Registering your SagePay account at `Gringotts`

  After [making an account on SagePay][dashboard], provide your `:auth_id` and 
  `:merchant_name` in Application config.

  Here's how the secrets map to the required configuration parameters for SagePay:

  | Config parameter        | SagePay secret             |
  | ------------------------| ---------------------------|
  | `:auth_id`              | Authorization Id           |
  | `:merchant_name`        | Name of merchant (account) |

  Your Application config **must include the `:auth_id`, `:merchant_name`
  fields** and would look something like this:

      config :gringotts, Gringotts.Gateways.SagePay,
        auth_id: "your_secret_user_id",
        merchant_name: "name_of_merchant"
        
  [dashboard]: https://applications.sagepay.com/apply

  ## Scope of this module

  * SagePay does not process money in cents, and the `amount` is converted to integer.
  * The module supports payments from cards only., though the gateway also
    allows bank payments.

  ## Supported currencies and countries

  AUD, CAD, CHF, CYP, DKK, EUR, GBP, HKD, INR, JPY, MTL, NOK, NZD, RUB, SEK,
  SGD, THB, TRY, USD, ZAR

  ## Following the examples

  1. First, set up a sample application and configure it to work with SagePay.
  - You could do that from scratch by following our [Getting Started][gs] guide.
      - To save you time, we recommend [cloning our example
      repo][example] that gives you a pre-configured sample app ready-to-go.
          + You could use the same config or update it the with your "secrets"
          as described [above](#module-registering-your-sagepay-account-at-gringotts).

  2. To save a lot of time, create an [`.iex.exs`][iex-docs] file as shown in
     [here][sagepay.iex.exs] to introduce a set of handy bindings and
     aliases into your IEx session.

  We'll be using these in the examples below.

  [gs]: #
  [example]: https://github.com/aviabird/gringotts_example
  [iex-docs]: https://hexdocs.pm/iex/IEx.html#module-the-iex-exs-file
  [sagepay.iex.exs]: https://gist.github.com/oyeb/bcf80db5634c0b7e5fe5d1ebc8e1308b
  """

  use Gringotts.Gateways.Base
  use Gringotts.Adapter, required_config: ~w[auth_id merchant_name]a
  alias Gringotts.{CreditCard, Money, Response}

  @url "https://pi-test.sagepay.com/api/v1/"

  # SagePay supports payment only by providing Merchant `:auth_id` and `:merchant_name`
  # which generates `session_key` and then providing card details generates
  # `card_id` which is required for authorization.

  @doc """
  Performs a (pre) Authorize operation.

  The authorization validates the `card` details with the banking network,
  places a hold on the transaction `amount` in the customer’s issuing bank.

  SagePay returns an transaction ID (available in `Response.id`) string which
  can be used to:
  * `capture/3` an amount.
  * `void/2` abort deferred transaction.
  * `refund/3` an amount.

  ## Note

  * The `session_key` expires after 400 seconds and can only be used to
    create one successful `card_id`.
  * The `session_key` expires after 3 failed attempts to create a
    `card_id`.
  * `vendor_tx_code` in opts should always be unique, consider using a UUID
    generator for this.
  * `address` should be a `Gringotts.Address.t` struct.

  ## Example

  The following example shows how one would (pre) authorize a payment of 42£ on
  a sample `card`.
  ```
  # Assuming that you've already bound some variables in your session,

  iex> amount = Money.new(42, :GBP)
  iex> opts = [
    transaction_type: "Deferred",
    vendor_tx_code: "demotransaction-51",
    description: "Demo Payment",
    customer_first_name: "Sam",
    customer_last_name: "Jones",
    
  ]
  iex> {:ok, auth_result} = Gringotts.authorize(Gringotts.Gateways.SagePay, amount, card, opts)
  iex> auth_result.id
  ```
  """
  @spec authorize(Money.t(), CreditCard.t(), keyword) :: {:ok | :error, Response.t()}
  def authorize(amount, %CreditCard{} = card, opts) do
    do_transaction(amount, card, opts, "Deferred")
  end

  @doc """
  Captures a pre-authorized `amount`.

  `amount` is transferred to the merchant account by SagePay when it is smaller or
  equal to the amount used in the pre-authorization referenced by `payment_id`.

  ## Note
  * Multiple captures are not allowed, and the `amount` must not exceed the
    originally authorized amount.
  * SagePay refers to a capture as a "Release" instruction on a previous
    authorization ("Deferred" transaction).
  * SagePay does not return any "capture ID", the transaction is uniquely
    determined by the `payment_id` recieved in the `authorize/3` request.

  ## Example
  The following example shows how one would capture a previously authorized
  amount worth 100£ by referencing the obtained transaction ID (payment_id) from
  `authorize/3` function.
  ```
  iex> amount = Money.new(100, :GBP)
  iex> {:ok, auth_result} = Gringotts.authorize(Gringotts.Gateways.SagePay, amount, card, opts)
  iex> {:ok, capture_result} = Gringotts.capture(Gringotts.Gateways.SagePay, auth_result.id, amount, opts)
  ```
  """
  @spec capture(String.t(), Money.t(), keyword) :: {:ok | :error, Response.t()}
  def capture(payment_id, amount, opts) when is_binary(payment_id) do
    {_, value, _} = Money.to_integer(amount)

    params =
      Poison.encode!(%{
        "instructionType" => "Release",
        "amount" => value
      })

    :post
    |> commit("transactions/#{payment_id}/instructions", params, headers(opts))
    |> respond()
  end

  @doc """
  Transfers `amount` from the customer to the merchant.

  SagePay attempts to process a purchase on behalf of the customer, by
  debiting `amount` from the customer's account by charging the customer's
  `card`.

  ## Example
  ```
  iex> amount = Money.new(100, :GBP)
  iex> Gringotts.purchase(Gringotts.Gateways.SagePay, amount, card, opts)
  ```
  """
  @spec purchase(Money.t(), CreditCard.t(), keyword) :: {:ok | :error, Response.t()}
  def purchase(amount, card, opts) do
    do_transaction(amount, card, opts, "Payment")
  end

  ###############################################################################
  #                                PRIVATE METHODS                              #
  ###############################################################################

  # Makes the request to sagepay's network.
  # For consistency with other gateway implementations, make your (final)
  # network request in here, and parse it using another private method called
  # `respond`.

  defp commit(:post, endpoint, params, headers) do
    HTTPoison.post(@url <> endpoint, params, headers)
  end

  # Generates a `session_key` that will exist only for 400
  # seconds and for 3 wrong `card_ids`.
  defp generate_session_key(opts) do
    params = Poison.encode!(%{vendorName: opts[:config][:merchant_name]})

    case commit(:post, "merchant-session-keys", params, headers(opts)) do
      {:ok, %{body: body, status_code: 201}} ->
        {:ok, session} = Poison.decode(body)
        {:ok, {session["merchantSessionKey"], session["expiry"]}}

      response ->
        respond(response)
    end
  end

  defp generate_card_id(card, {session_key, _} = session) do
    card_header = [
      {"Authorization", "Bearer " <> session_key},
      {"Content-type", "application/json"}
    ]

    case commit(:post, "card-identifiers", Poison.encode!(card), card_header) do
      {:ok, %{body: body, status_code: 201}} ->
        {:ok, card} = Poison.decode(body)
        {:ok, {card["cardIdentifier"], card["expiry"]}}

      response ->
        respond(response, session_key: session)
    end
  end

  # Returns credit card details of a customer from a `Gringotts.Creditcard`
  defp card_params(card) do
    expiry_date = card.month * 100 + card.year

    %{
      "cardDetails" => %{
        "cardholderName" => CreditCard.full_name(card),
        "cardNumber" => card.number,
        "expiryDate" =>
          expiry_date
          |> Integer.to_string()
          |> String.pad_leading(4, "0"),
        "securityCode" => card.verification_code
      }
    }
  end

  defp do_transaction(amount, card, opts, type) do
    with {:ok, session} <- generate_session_key(opts),
         {:ok, {card_id, _} = card} <- generate_card_id(card_params(card), session) do
      params = build_transaction(amount, session, card_id, opts, type)

      :post
      |> commit("transactions", params, headers(opts))
      |> respond(card_id: card)
    end
  end

  defp build_transaction(amount, {session_key, _}, card_id, opts, type) do
    {currency, value, _} = Money.to_integer(amount)
    full_address = "#{opts[:billing_address].street1}, #{opts[:billing_address].street2}"

    Poison.encode!(%{
      "transactionType" => type,
      "paymentMethod" => %{
        "card" => %{
          "merchantSessionKey" => session_key,
          "cardIdentifier" => card_id,
          "save" => true
        }
      },
      "vendorTxCode" => opts[:vendor_tx_code],
      "amount" => value,
      "currency" => currency,
      "description" => opts[:description],
      "customerFirstName" => opts[:first_name],
      "customerLastName" => opts[:last_name],
      "billingAddress" => %{
        "address1" => full_address,
        "city" => opts[:billing_address].city,
        "postalCode" => opts[:billing_address].postal_code,
        "country" => opts[:billing_address].country
      },
      "applyAvsCvcCheck" => "Force"
    })
  end

  @spec respond({:ok | :error, HTTPoison.Response.t()}, tuple) :: {:ok | :error, Response}
  defp respond(response, tokens \\ [])

  defp respond({:ok, %{status_code: 201, body: body}}, tokens) do
    parsed_body = Poison.decode!(body)

    avs = %{
      street: get_in(parsed_body, ~w(avsCvcCheck address)),
      postal_code: get_in(parsed_body, ~w(avsCvcCheck postalCode))
    }

    {:ok,
     %Response{
       success: true,
       id: parsed_body["transactionId"],
       tokens: tokens,
       status_code: 201,
       gateway_code: parsed_body["statusCode"],
       avs_result: avs,
       cvc_result: get_in(parsed_body, ~w(avsCvcCheck securityCode)),
       message: parsed_body["statusDetail"],
       raw: body
     }}
  end

  defp respond({:ok, %{status_code: status_code, body: body}}, tokens) do
    parsed_body = Poison.decode!(body)

    {:error,
     %Response{
       success: false,
       id: parsed_body["transactionId"],
       tokens: tokens,
       status_code: status_code,
       gateway_code: parsed_body["statusCode"] || parsed_body["code"],
       reason: parsed_body["statusDetail"] || parsed_body["errors"] || parsed_body["description"],
       raw: body
     }}
  end

  defp respond({:error, %HTTPoison.Error{} = error}, tokens) do
    {
      :error,
      Response.error(
        success: false,
        tokens: tokens,
        reason: "network related failure",
        message: "HTTPoison says '#{error.reason}' [ID: #{error.id || "nil"}]"
      )
    }
  end

  defp headers(opts) do
    config = Keyword.fetch!(opts, :config)

    [
      {"Authorization", "Basic " <> config[:auth_id]},
      {"Content-type", "application/json"}
    ]
  end
end
