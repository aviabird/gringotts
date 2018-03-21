defmodule Gringotts.Gateways.SecurionPay do
  @moduledoc """
  [SecurionPay][home] gateway implementation.

  For reference see [SecurionPay's API (v1) documentation][docs].

  The following set of functions for SecurionPay have been implemented:

  | Action                                       | Method        |
  | ------                                       | ------        |
  | Authorize a Credit Card                      | `authorize/3` |

  [home]: https://securionpay.com/
  [docs]: https://securionpay.com/docs

  ## The `opts` argument

  Most `Gringotts` API calls accept an optional `keyword` list `opts` to supply
  [optional arguments][extra-arg-docs] for transactions with the SecurionPay
  gateway. The following keys are supported:

  | Key                      | Remark                                                                                        |
  | ----                     | ---                                                                                           |
  | `customerId`             | Unique identifier of the customer                                                             |

  ## Registering your SecurionPay account at `Gringotts`

  After [making an account on SecurionPay][SP], find your `Secret key` at [Account Settings][api-key] 

  Your Application config **must include the `:secret_key`  field**.
  It would look something like this:

      config :gringotts, Gringotts.Gateways.SecurionPay,
        secret_key: "your_secret_key"

  [SP]: https://securionpay.com/
  [api-key]: https://securionpay.com/account-settings#api-keys


  ## Note

  * SecurionPay always processes the transactions in the minor units of the currency eg. `cents` instead of `dollar`

  ## Supported countries

  SecurionPay supports the countries listed [here][country-list]

  [country-list]: https://securionpay.com/supported-countries-businesses/
  """
  @base_url "https://api.securionpay.com/"
  # The Base module has the (abstract) public API, and some utility
  # implementations.

  use Gringotts.Gateways.Base

  # The Adapter module provides the `validate_config/1`
  # Add the keys that must be present in the Application config in the
  # `required_config` list
  use Gringotts.Adapter, required_config: [:secret_key]

  import Poison, only: [decode: 1]

  alias Gringotts.{CreditCard, Response, Address}

  @doc """
  Authorizes a credit card transaction.

  The authorization validates the card details with the banking network,
  places a hold on the transaction `amount` in the customer’s issuing bank and
  also triggers risk management. Funds are not transferred.

  The second argument can be a `CreditCard` or a `card_id`. The `customer_id` of the customer who owns the card must be
  given in optional field if `card_id` is used. 

  To transfer the funds to merchant's account follow this up with a `capture/3`.

  SecurionPay returns a `charge_id` which uniquely identifies a transaction (available in the `Response.id` field) 
  which should be stored by the caller for using in:

  * `capture/3` an authorized transaction.
  * `void/2` an authorized transaction.

  ## Example
  ### With a `CreditCard` struct
      iex> amount = Money.new(20, :USD)
      iex> opts = [config: [secret_key: "c2tfdGVzdF9GZjJKcHE1OXNTV1Q3cW1JOWF0aWk1elI6"]]
      iex> card = %Gringotts.CreditCard{first_name: "Harry", last_name: "Potter", number: "4200000000000000", year: 2099, month: 12, verification_code:  "123", brand: "VISA"}
      iex> result = Gringotts.Gateways.SecurionPay.authorize(amount, card, opts)

  ## Example
  ### With a `card_token` and `customer_token`
      iex> amount = Money.new(20, :USD}
      iex> opts = [config: [:secret_key: "c2tfdGVzdF9GZjJKcHE1OXNTV1Q3cW1JOWF0aWk1elI6"], customer_id: "cust_zpYEBK396q3rvIBZYc3PIDwT"]
      iex> card = "card_LqTT5tC10BQzDbwWJhFWXDoP"
      iex> result = Gringotts.Gateways.SecurionPay.authorize(amount, card, opts)

  """
  @spec authorize(Money.t(), CreditCard.t() | String.t(), keyword) :: {:ok | :error, Response.t()}

  def authorize(amount, %CreditCard{} = card, opts) do
    header = [{"Authorization", "Basic " <> opts[:config][:secret_key]}]
    token_id = create_token(card, header)
    {currency, value, _, _} = Money.to_integer_exp(amount)

    token_id
    |> create_params(currency, value, false)
    |> commit(:post, "charges", header)
    |> respond
  end

  def authorize(amount, card_id, opts) when is_binary(card_id) do
    header = [{"Authorization", "Basic " <> opts[:config][:secret_key]}]
    {currency, value, _, _} = Money.to_integer_exp(amount)
    params = create_params(card_id, opts[:customer_id], currency, value, false)

    params
    |> commit(:post, "charges", header)
    |> respond
  end

  ###############################################################################
  #                                PRIVATE METHODS                              #
  ###############################################################################

  # Creates the parameters for authorise function when 
  # card_id and customerId is provided.
  @spec create_params(String.t(), String.t(), String.t(), Integer.t(), boolean) :: {[]}
  defp create_params(card_id, customer_id, currency, value, captured) do
    [
      {"amount", value},
      {"currency", to_string(currency)},
      {"card", card_id},
      {"captured", "#{captured}"},
      {"customerId", customer_id}
    ]
  end

  # Creates the parameters for authorise when token is provided.
  @spec create_params(String.t(), String.t(), Integer.t(), boolean) :: {[]}
  defp create_params(token, currency, value, captured) do
    [
      {"amount", value},
      {"currency", to_string(currency)},
      {"card", token},
      {"captured", "#{captured}"}
    ]
  end

  # Makes the request to SecurionPay's network.
  # For consistency with other gateway implementations, make your (final)
  # network request in here, and parse it using another private method called
  # `respond`.
  defp commit(params, method, path, header) do
    HTTPoison.request(method, "#{@base_url}#{path}", {:form, params}, header)
  end

  # Parses SecurionPay's response and returns a `Gringotts.Response` struct
  # in a `:ok`, `:error` tuple.
  @spec respond(term) :: {:ok | :error, Response}

  defp respond({:ok, %{status_code: 200, body: body}}) do
    parsed_body = Poison.decode!(body)

    {:ok,
     %{
       success: true,
       id: Map.get(parsed_body, "id"),
       token: Map.get(parsed_body["card"], "id"),
       status_code: 200,
       raw: body,
       fraud_review: Map.get(parsed_body, "fraudDetails")
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

  defp create_token(card, header) do
    [
      {"number", card.number},
      {"expYear", card.year},
      {"cvc", card.verification_code},
      {"expMonth", card.month},
      {"cardholderName", CreditCard.full_name(card)}
    ]
    |> commit(:post, "tokens", header)
    |> make_map
    |> Map.fetch!("id")
  end

  defp make_map(response) do
    case response do
      {:ok, %HTTPoison.Response{body: body}} -> body |> Poison.decode!()
    end
  end
end
