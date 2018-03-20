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
    with {:ok, %{body: body, status_code: 201}} <- generate_session_key(opts),
         {:ok, %{"merchantSessionKey" => session_key} = session} <- Poison.decode(body),
         {:ok, %{body: body, status_code: 201}} <-
           generate_card_id(card_params(card), session_key),
         {:ok, %{"cardIdentifier" => card_id} = card} <- Poison.decode(body) do
      params = transaction_details(amount, session_key, card_id, opts)

      :post
      |> commit("transactions", params, headers(opts))
      |> respond({session_key, session["expiry"]}, {card_id, card["expiry"]})
    else
      {:error, %HTTPoison.Error{}} = error ->
        respond(error)

      {:ok, %HTTPoison.Response{} = response} ->
        {
          :error,
          %Response{
            status_code: response.status_code,
            raw: response.body,
            reason: Poison.decode!(response.body)
          }
        }
    end
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
  def generate_session_key(opts) do
    params = Poison.encode!(%{vendorName: opts[:config][:merchant_name]})

    commit(:post, "merchant-session-keys", params, headers(opts))
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

  defp generate_card_id(card, merchant_key) do
    card_header = [
      {"Authorization", "Bearer " <> merchant_key},
      {"Content-type", "application/json"}
    ]

    commit(:post, "card-identifiers", Poison.encode!(card), card_header)
  end

  defp transaction_details(amount, merchant_key, card_id, opts) do
    {currency, value} = Money.to_string(amount)
    full_address = "#{opts[:billing_address].street1}, #{opts[:billing_address].street2}"

    Poison.encode!(%{
      "transactionType" => "Deferred",
      "paymentMethod" => %{
        "card" => %{
          "merchantSessionKey" => merchant_key,
          "cardIdentifier" => card_id,
          "save" => true
        }
      },
      "vendorTxCode" => opts[:vendor_tx_code],
      "amount" => Kernel.trunc(String.to_float(value)),
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

  @spec respond({:ok | :error, HTTPoison.Response.t()}, term, term) :: {:ok | :error, Response}
  defp respond(response, session_key \\ nil, card_id \\ nil)

  defp respond({:ok, %{status_code: 201, body: body}}, session_key, card_id) do
    parsed_body = Poison.decode!(body)

    tokens =
      Enum.reject(
        [
          card_id: card_id,
          session_key: session_key
        ],
        fn x -> is_nil(x) end
      )

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

  defp respond({:ok, %{status_code: status_code, body: body}}, session_key, _) do
    parsed_body = Poison.decode!(body)

    tokens =
      Enum.reject(
        [
          session_key: session_key
        ],
        fn x -> is_nil(x) end
      )

    {:error,
     %Response{
       success: false,
       id: parsed_body["transactionId"],
       tokens: tokens,
       status_code: status_code,
       gateway_code: parsed_body["statusCode"],
       reason: parsed_body["statusDetail"],
       raw: body
     }}
  end

  defp respond({:error, %HTTPoison.Error{} = error}, _, _) do
    {
      :error,
      Response.error(
        success: false,
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
