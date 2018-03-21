defmodule Gringotts.Gateways.SecurionPay do
  @moduledoc """
  [SecurionPay][home] gateway implementation.

  For reference see [MONEI's API (v1) documentation][docs].

  The following set of functions for SecurionPay have been implemented:

  | Action                                       | Method        |
  | ------                                       | ------        |
  | Authorize a Credit Card                      | `authorize/3` |

  [home]: https://securionpay.com/
  [docs]: https://securionpay.com/docs

  ## The `opts` argument

  Most `Gringotts` API calls accept an optional `keyword` list `opts` to supply
  [optional arguments][extra-arg-docs] for transactions with the MONEI
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
  Authorize a credit card transaction.

  The authorization validates the `card` details with the banking network,
  places a hold on the transaction `amount` in the customer’s issuing bank and
  also triggers risk management. Funds are not transferred.

  The second argument can be a CreditCard or a cardId. The customerId of the cutomer who owns the card must be
  given in optional field. 

  To transfer the funds to merchant's account follow this up with a `capture/3`.

  SecurionPay returns a `chargeId` which uniquely identifies a transaction (available in the `Response.id` field) 
  which should be stored at your side to use in:

  * `capture/3` an authorized transaction.
  * `void/2` a transaction.


  ## Example 1
      iex> amount = Money.new(20, :USD}
      iex> opts = [config: [:secret_key: "c2tfdGVzdF9GZjJKcHE1OXNTV1Q3cW1JOWF0aWk1elI6"]]
      iex> card = %CreditCard{
           first_name: "Harry",
           last_name: "Potter",
           number: "4200000000000000",
           year: 2027,
           month: 12,
           verification_code: "123",
           brand: "VISA"
          }
      iex> result = Gringotts.Gateways.SecurionPay.authorize(amount, card, opts)

  ## Example 2
      iex> amount = Money.new(20, :USD}
      iex> opts = [config: [:secret_key: "c2tfdGVzdF9GZjJKcHE1OXNTV1Q3cW1JOWF0aWk1elI6"], customerId: "cust_zpYEBK396q3rvIBZYc3PIDwT"]
      iex> card = "card_LqTT5tC10BQzDbwWJhFWXDoP"
      iex> result = Gringotts.Gateways.SecurionPay.authorize(amount, card, opts)

  """
  @spec authorize(Money.t(), CreditCard.t() | {}, keyword) :: {:ok | :error, Response}
  def authorize(amount, card, opts)

  def authorize(amount, %CreditCard{} = card, opts) do
    header = [{"Authorization", "Basic " <> opts[:config][:secret_key]}]

    create_token(card, header)
    |> create_params(amount, false)
    |> commit(:post, "charges", header)
    |> respond
  end

  def authorize(amount, card, opts) do
    header = [{"Authorization", "Basic " <> opts[:config][:secret_key]}]

    create_params({card, opts[:customerId]}, amount, false)
    |> commit(:post, "charges", header)
    |> respond
  end

  @doc """
  Captures a pre-authorized `amount`.

  `amount` is transferred to the merchant account by SecurionPay used in the
  pre-authorization referenced by `payment_id`.

  ## Note

  > If there's anything noteworthy about this operation, it comes here.
  > For example, does the gateway support partial, multiple captures?

  ## Example

  > A barebones example using the bindings you've suggested in the `moduledoc`.
  """
  @spec capture(String.t(), Money.t(), keyword) :: {:ok | :error, Response}
  def capture(payment_id, amount, opts) do
    # commit(args, ...)
  end

  @doc """
  Transfers `amount` from the customer to the merchant.

  SecurionPay attempts to process a purchase on behalf of the customer, by
  debiting `amount` from the customer's account by charging the customer's
  `card`.

  ## Note

  > If there's anything noteworthy about this operation, it comes here.

  ## Example

  > A barebones example using the bindings you've suggested in the `moduledoc`.
  """
  @spec purchase(Money.t(), CreditCard.t() | {}, keyword) :: {:ok | :error, Response}
  def purchase(amount, card, opts)

  def purchase(amount, %CreditCard{} = card, opts) do
    header = [{"Authorization", "Basic " <> opts[:config][:secret_key]}]

    create_token(card, header)
    |> create_params(amount, true)
    |> commit(:post, "charges", header)
    |> respond
  end

 # @spec purchase(Money.t(), CreditCard.t(), keyword) :: {:ok | :error, Response}
  def purchase(amount, card , opts) do
    # commit(args, ...)
     header = [{"Authorization", "Basic " <> opts[:config][:secret_key]}]

    create_params({card, opts[:customerId]}, amount, true)
    |> commit(:post, "charges", header)
    |> respond

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
    # commit(args, ...)
  end

  @doc """
  Refunds the `amount` to the customer's account with reference to a prior transfer.

  > Refunds are allowed on which kinds of "prior" transactions?

  ## Note

  > The end customer will usually see two bookings/records on his statement. Is
  > that true for SecurionPay?
  > Is there a limited time window within which a void can be perfomed?

  ## Example

  > A barebones example using the bindings you've suggested in the `moduledoc`.
  """
  @spec refund(Money.t(), String.t(), keyword) :: {:ok | :error, Response}
  def refund(amount, payment_id, opts) do
    # commit(args, ...)
    header = [{"Authorization", "Basic " <> opts[:config][:secret_key]}]
    params = create_params(amount)
    url = "charges/#{payment_id}/refund"
    commit(params, :post, url, header)


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
    # commit(args, ...)
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
    # commit(args, ...)
  end

  ###############################################################################
  #                                PRIVATE METHODS                              #
  ###############################################################################

  # Creates the parameter for authorise and capture function when cardId and customerId is provided.
  @spec create_params({}, Money.t(), boolean) :: {[]}
  defp create_params({cardId, customerId}, amount, captured) do
    {currency, value, _, _} = Money.to_integer_exp(amount)

    [
      {"amount", value},
      {"currency", to_string(currency)},
      {"card", cardId},
      {"captured", "#{captured}"},
      {"customerId", customerId}
    ]
  end

  # Creates the parameter for authorise and capture function when token is provided.
  @spec create_params(Integer.t(), Money.t(), boolean) :: {[]}
  defp create_params(token, amount, captured) do
    {currency, value, _, _} = Money.to_integer_exp(amount)

    [
      {"amount", value},
      {"currency", to_string(currency)},
      {"card", token},
      {"captured", "#{captured}"}
    ]
  end
  
  defp create_params(amount) do
    {currency, value, _, _} = Money.to_integer_exp(amount)
    [
       {"amount", value}
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
    parsedBody = Poison.decode!(body)

    {:ok,
     %{
       success: true,
       id: Map.get(parsedBody, "id"),
       token: Map.get(parsedBody["card"], "id"),
       status_code: 200,
       gateway_code: 200,
       reason: nil,
       message: "Card succesfully authorized",
       avs_result: nil,
       cvc_result: nil,
       raw: body,
       fraud_review: Map.get(parsedBody, "fraudDetails")
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
      {"cardholderName", card.first_name <> " " <> card.last_name}
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
