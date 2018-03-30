defmodule Gringotts.Gateways.SecurionPay do
  @moduledoc """
  [SecurionPay][home] gateway implementation.

  For reference see [SecurionPay's API (v1) documentation][docs].

  The following set of functions for SecurionPay have been implemented:

  | Action                                       | Method        |
  | ------                                       | ------        |
  | Authorize a Credit Card                      | `authorize/3` |
  | Capture an authorized transaction            | `capture/3`   |
  | Cancel an authorized transaction             | `void/2`      |

  [home]: https://securionpay.com/
  [docs]: https://securionpay.com/docs

  ## The `opts` argument

  Most `Gringotts` API calls accept an optional `keyword` list `opts` to supply
  optional arguments for transactions with the SecurionPay gateway. 
  The following keys are supported:

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
  use Gringotts.Gateways.Base
  use Gringotts.Adapter, required_config: [:secret_key]
  import Poison, only: [decode!: 1]
  alias Gringotts.{CreditCard, Response}
  @base_url "https://api.securionpay.com/"

  @doc """
  Authorizes a credit card transaction.

  The authorization validates the card details with the banking network,
  places a hold on the transaction `amount` in the customer’s issuing bank and
  also triggers risk management. Funds are not transferred.

  The second argument can be a `CreditCard` or a `card_id`. The `customer_id` of the customer who owns the card must be
  given in optional field if `card_id` is used. 

  SecurionPay returns a `charge_id` (available in the `Response.id` field) which uniquely identifies a transaction  
  which should be stored by the caller for using in:

  * `capture/3` an authorized transaction.
  * `void/2` an authorized transaction.

  ## Note
  * A stand-alone pre-authorization expires in 5-days.

  ## Example
  ### With a `CreditCard` struct
      iex> amount = Money.new(20, :USD)
      iex> card = %Gringotts.CreditCard{first_name: "Harry", last_name: "Potter", number: "4200000000000000", year: 2099, month: 12, verification_code:  "123", brand: "VISA"}
      iex> result = Gringotts.Gateways.SecurionPay.authorize(amount, card, [])

  ## Example
  ### With a `card_token` and `customer_token`
      iex> amount = Money.new(20, :USD)
      iex> opts = [customer_id: "cust_9999999999999999999999999"]
      iex> card = "card_xxxxxxxxxxxxxxxxxxxxxx"
      iex> result = Gringotts.Gateways.SecurionPay.authorize(amount, card, opts)

  """
  @spec authorize(Money.t(), CreditCard.t() | String.t(), keyword) :: {:ok | :error, Response.t()}

  def authorize(amount, %CreditCard{} = card, opts) do
    params = common_params(amount, false) ++ card_params(card)
    commit(params, "charges", opts)
  end

  def authorize(amount, card_id, opts) when is_binary(card_id) do
    params = common_params(amount, false) ++ card_params(card_id, opts)
    commit(params, "charges", opts)
  end

  @doc """
  Captures a pre-authorized transcation from the customer.

  The complete amount present in the pre-authorization referenced by `payment_id` is transferred
  to the merchant account by SecurionPay. The `amount` argument is ignored.

  Successful request returns a charge object that was captured.

  ## Note
  * Because SecurionPay **does not support partial captures**, please pass `nil` in `amount`

  ## Example
      iex> amount = nil
      iex> payment_id = "char_9999999999999999" 
      iex> result = Gringotts.Gateways.SecurionPay.capture(payment_id, amount, opts)     

  """
  @spec capture(String.t(), Money.t(), keyword) :: {:ok | :error, Response}
  def capture(payment_id, _amount, opts) do
    commit([], "charges/#{payment_id}/capture", opts)
  end

  @doc """
  Cancels an pre-authorized transaction.

  This method attempts a reversal of a previous `authorize/3` referenced by `payment_id`.

  ## Note
  * SecurionPay **does not** allow partial cancellation of a non-captured(authorized) transaction.

  ## Example

  The following example shows how one would void a previous authorization. 

      iex> {:ok, void_result} = Gringotts.void(Gringotts.Gateways.SecurionPay, auth_result.id, opts)
  """
  @spec void(String.t(), keyword) :: {:ok | :error, Response.t()}
  def void(payment_id, opts) do
    commit([], "charges/#{payment_id}/refund", opts)
  end

  ##########################################################################
  #                          PRIVATE METHODS                               #
  ##########################################################################

  # Creates the common parameters for authorize function
  @spec common_params(String.t(), String.t()) :: keyword
  defp common_params(amount, captured) do
    {currency, value, _, _} = Money.to_integer_exp(amount)

    [
      amount: value,
      currency: to_string(currency),
      captured: captured
    ]
  end

  # Creates the card parameters for authorize function when
  # card_id and customer_id is provided.
  @spec card_params(String.t(), keyword) :: keyword
  defp card_params(card_id, opts) do
    [
      card: card_id,
      customerId: opts[:customer_id]
    ]
  end

  # Creates the card parameters for authorize when
  # `CreditCard` structure is provided
  @spec card_params(CreditCard.t()) :: keyword
  defp card_params(card) do
    [
      "card[expYear]": card.year,
      "card[cvc]": card.verification_code,
      "card[cardholderName]": CreditCard.full_name(card),
      "card[number]": card.number,
      "card[expMonth]": card.month
    ]
  end

  # Makes the request to SecurionPay's network.
  @spec commit(keyword, String.t(), keyword) :: {:ok | :error, Response}
  defp commit(params, path, opts) do
    header = set_header(opts)
    response = HTTPoison.post("#{@base_url}#{path}", {:form, params}, header)
    respond(response)
  end

  # Parses SecurionPay's response and returns a `Gringotts.Response` struct
  # in a `:ok`, `:error` tuple.
  @spec respond(term) :: {:ok | :error, Response}

  defp respond({:ok, %{status_code: 200, body: body}}) do
    parsed_body = decode!(body)

    parsed_response = [
      id: parsed_body["id"],
      token: get_in(parsed_body, ["card", "id"]),
      status_code: 200,
      raw: body,
      fraud_review: parsed_body["fraudDetails"]
    ]

    {:ok, Response.success(parsed_response)}
  end

  defp respond({:ok, %{body: body, status_code: code}}) do
    parsed_body = decode!(body)

    parsed_response = [
      raw: body,
      status_code: code,
      reason: get_in(parsed_body, ["error", "message"]),
      message: get_in(parsed_body, ["error", "type"])
    ]

    {:error, Response.error(parsed_response)}
  end

  defp respond({:error, %HTTPoison.Error{} = error}) do
    {
      :error,
      %Response{
        reason: "Network related failure",
        message: "HTTPoison says '#{error.reason}' [ID: #{error.id || "nil"}]"
      }
    }
  end

  defp set_header(opts) do
    encoded_key = Base.encode64("#{opts[:config][:secret_key]}:")
    [{"Authorization", "Basic #{encoded_key}"}]
  end
end
