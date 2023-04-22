defmodule Gringotts.Gateways.Mercadopago do
  @moduledoc """
  [mercadopago][home] gateway implementation.

  For reference see [mercadopago documentation][docs].

  The following features of mercadopago are implemented:

  | Action                       | Method        |
  | ------                       | ------        |
  | Pre-authorize                | `authorize/3` |
  | Capture                      | `capture/3`   |
  | Purchase                     | `purchase/3`  |
  | Reversal                     | `void/2`      |
  | Refund                       | `refund/3`    |

  [home]: https://www.mercadopago.com/
  [docs]: https://www.mercadopago.com.ar/developers/en/api-docs/

  ## The `opts` argument

  Most `Gringotts` API calls accept an optional `keyword` list `opts` to supply
  optional arguments for transactions with the mercadopag. The following keys are supported:

  | Key                      | Remark                                                                                  |
  | ----                     | ---                                                                                     |
  | `email`                  | Email of the customer. Type - string                                                    |
  | `order_id`               | Order id issued by the merchant. Type- integer                                          |
  | `customer_id`            | Unique customer id issued by the gateway. For new customer it must skipped. Type- string|
  | `order_type`             | `"mercadopago"` or `"mercadolibre"` as per the order. Type- string                      |
  | `installments`           | No of installments for payment. Type- integer                                           |

  ## Registering your mercadopago account at `Gringotts`

  After [making an account on mercadopago][credentials], head to the credentials and find
  your account "secrets" in the `Checkout Transparent`.

  | Config parameter | MERCADOPAGO secret |
  | -------          | ----               |
  | `:access_token`  | **Access Token**   |
  | `:public_key`    | **Public Key**     |

  > Your Application config **must include the `[:public_key, :access_token]` field(s)** and would look
  > something like this:
  >
  >     config :gringotts, Gringotts.Gateways.Mercadopago,
  >         public_key: "your_secret_public_key"
  >         access_token: "your_secret_access_token"

  [credentials]: https://www.mercadopago.com/mlb/account/credentials?type=basic

  ## Note

  * mercadopago processes money in the subdivided units (like `cents` in case of
    US Dollar).
  * Also, there is no way to set the currency of the transaction via the API. It
    is automatically set from the merchant's account. Hence, if you've
    configured your mercadopago account to work in Chilean Peso (`CLP`), make
    sure that the `amount` argument is always a `Money.t` struct with the `:CLP`
    as currency.

  ## Supported currencies and countries

  mercadopago supports the currencies listed [here][currencies].

  [currencies]: https://api.mercadopago.com/currencies

  ## Following the examples

  1. First, set up a sample application and configure it to work with MERCADOPAGO.
  - You could do that from scratch by following our [Getting Started][gs] guide.
      - To save you time, we recommend [cloning our example
      repo][example] that gives you a pre-configured sample app ready-to-go.
          + You could use the same config or update it the with your "secrets"
          as described [above](#module-registering-your-mercadopago-account-at-gringotts).

  [gs]: https://github.com/aviabird/gringotts/wiki/
  [home]: https://www.mercadopago.com
  [example]: https://github.com/aviabird/gringotts_payment
  """

  @base_url "https://api.mercadopago.com"
  use Gringotts.Gateways.Base
  alias Gringotts.CreditCard
  # The Adapter module provides the `validate_config/1`
  # Add the keys that must be present in the Application config in the
  # `required_config` list
  use Gringotts.Adapter, required_config: [:public_key, :access_token]

  alias Gringotts.{CreditCard, Money, Response}

  @doc """
  Performs a (pre) Authorize operation.

  The authorization validates the `card` details with the banking network,
  places a hold on the transaction `amount` in the customer’s issuing bank.

  mercadoapgo's `authorize` returns:
  * `customer_id`, available in `Response.token` field and
  * `authorization_id`, available in the `Response.id` field.

  The `id` can be used to
  * `capture/3` _an_ amount.
  * `void/2` a pre-authorization.

  ## Note

  For a new customer, `customer_id` field should be `nil`. Otherwise it should
  be provided.

  ## Example

  ### Authorization for new customer.

    The following example shows how one would (pre) authorize a payment of 42
    BRL on a sample `card`.

      iex> amount = Money.new(42, :BRL)
      iex> card = %Gringotts.CreditCard{first_name: "Lord", last_name: "Voldemort", number: "4509953566233704", year: 2099, month: 12, verification_code: "123", brand: "VISA"}
      iex> opts = [email: "tommarvolo@riddle.com", order_id: 123123, payment_method_id: "visa"]
      iex> {:ok, auth_result} = Gringotts.authorize(Gringotts.Gateways.Mercadopago, amount, card, opts)
      iex> auth_result.id # This is the authorization ID
      iex> auth_result.token # This is the customer ID/token

  ### Authorization for old customer.

    The following example shows how one would (pre) authorize a payment of 42
    BRL on a sample `card`.

      iex> amount = Money.new(42, :BRL)
      iex> card = %Gringotts.CreditCard{first_name: "Hermione", last_name: "Granger", number: "4509953566233704", year: 2099, month: 12, verification_code: "123", brand: "VISA"}
      iex> opts = [email: "hermione@granger.com", order_id: 123125, customer_id: "hermoine's customer id", payment_method_id: "visa"]
      iex> {:ok, auth_result} = Gringotts.authorize(Gringotts.Gateways.Mercadopago, amount, card, opts)
      iex> auth_result.id # This is the authorization ID
      iex> auth_result.token # This is the customer ID/token
  """
  @spec authorize(Money.t(), CreditCard.t(), keyword) :: {:ok | :error, Response}
  def authorize(amount, %CreditCard{} = card, opts) do
    with {:ok, card_token} <- create_token(card, opts) do
      {currency, value, exponent} = Money.to_integer(amount)
      url_params = [access_token: opts[:config][:access_token]]

      params = [
        authorize_params(value, opts, card_token, false, card)
      ]

      body =
        params
        |> Enum.reduce(&Map.merge/2)
        |> Poison.encode!()

      commit(:post, "/v1/payments", body, opts, url_params)
    end
  end

  @doc """
  Captures a pre-authorized `amount`.
  `amount` is transferred to the merchant account by mercadopago used in the
  pre-authorization referenced by `payment_id`.
  ## Note
  mercadopago allows partial captures also. However, you can make a partial capture to a payment only **once**.
  > The authorization will be valid for 7 days. If you do not capture it by that time, it will be cancelled.
  > The specified amount can not exceed the originally reserved.
  > If you do not specify the amount, all the reserved money is captured.
  > In Argentina only available for Visa and American Express cards.
  ## Example
  The following example shows how one would (partially) capture a previously
  authorized a payment worth 35 BRL by referencing the obtained authorization `id`.
      iex> amount = Money.new(35, :BRL)
      iex> {:ok, capture_result} = Gringotts.capture(Gringotts.Gateways.Mercadopago, auth_result.id, amount, opts)
  """
  @spec capture(String.t(), Money.t(), keyword) :: {:ok | :error, Response}
  def capture(payment_id, amount, opts) do
    {currency, value, exponent} = Money.to_integer(amount)
    url_params = [access_token: opts[:config][:access_token]]
    body = %{capture: true, transaction_amount: value} |> Poison.encode!()
    commit(:put, "/v1/payments/#{payment_id}", body, opts, url_params)
  end

  @doc """
  Transfers `amount` from the customer to the merchant.
  mercadopago attempts to process a purchase on behalf of the customer, by
  debiting `amount` from the customer's account by charging the customer's
  `card`.
  ## Example
  The following example shows how one would process a payment worth 42 BRL in
  one-shot, without (pre) authorization.
      iex> amount = Money.new(42, :BRL)
      iex> card = %Gringotts.CreditCard{first_name: "Harry", last_name: "Potter", number: "4200000000000000", year: 2099, month: 12, verification_code:  "123", brand: "VISA"}
      iex> {:ok, purchase_result} = Gringotts.purchase(Gringotts.Gateways.Mercadopago, amount, card, opts)
      iex> purchase_result.token # This is the customer ID/token
  """
  @spec purchase(Money.t(), CreditCard.t(), keyword) :: {:ok | :error, Response}
  def purchase(amount, %CreditCard{} = card, opts) do
    with {:ok, card_token} <- create_token(card, opts) do
      {currency, value, exponent} = Money.to_integer(amount)
      url_params = [access_token: opts[:config][:access_token]]

      body = value |> authorize_params(opts, card_token, true, card) |> Poison.encode!()
      commit(:post, "/v1/payments", body, opts, url_params)
    end
  end

  @doc """
  Voids the referenced payment.
  This method attempts a reversal of a previous transaction referenced by
  `payment_id`.
  > As a consequence, the customer will never see any booking on his statement.
  ## Note
  > Only pending or in_process payments can be cancelled.
  > Cancelled coupon payments, deposits and/or transfers will be deposited in the buyer’s Mercadopago account.
  ## Example
  The following example shows how one would void a previous (pre)
  authorization. Remember that our `capture/3` example only did a partial
  capture.
      iex> {:ok, void_result} = Gringotts.void(Gringotts.Gateways.Mercadopago, auth_result.id, opts)
  """
  @spec void(String.t(), keyword) :: {:ok | :error, Response}
  def void(payment_id, opts) do
    # url = "#{@base_url}/v1/payments/#{payment_id}?access_token=#{opts[:config][:access_token]}"
    url_params = [access_token: opts[:config][:access_token]]
    body = %{status: "cancelled"} |> Poison.encode!()
    commit(:put, "/v1/payments/#{payment_id}", body, opts, url_params)
  end

  @doc """
  Refunds the `amount` to the customer's account with reference to a prior transfer.
  mercadopago processes a full or partial refund worth `amount`, referencing a
  previous `purchase/3` or `capture/3`.
  ## Note
  > You must have enough available money in your account so you can refund the payment amount successfully. Otherwise, you'll get a 400 Bad Request error.
  > You can refund a payment within 90 days after it was accredited.
  > You can only refund approved payments.
  > You can perform up to 20 partial refunds in one payment.
  ## Example
  The following example shows how one would (completely) refund a previous
  purchase (and similarily for captures).
      iex> amount = Money.new(35, :BRL)
      iex> {:ok, refund_result} = Gringotts.refund(Gringotts.Gateways.Mercadopago, purchase_result.id, amount)
  """
  @spec refund(Money.t(), String.t(), keyword) :: {:ok | :error, Response}
  def refund(amount, payment_id, opts) do
    {currency, value, exponent} = Money.to_integer(amount)

    # url =
    # "#{@base_url}/v1/payments/#{payment_id}/refunds?access_token=#{opts[:config][:access_token]}"
    url_params = [access_token: opts[:config][:access_token]]
    body = %{amount: value} |> Poison.encode!()
    commit(:post, "/v1/payments/#{payment_id}/refunds", body, opts, url_params)
  end

  ###############################################################################
  #                                PRIVATE METHODS                              #
  ###############################################################################

  # Makes the request to mercadopago's network.
  # For consistency with other gateway implementations, make your (final)
  # network request in here, and parse it using another private method called
  # `respond`.
  @spec commit(atom, String.t(), String.t(), keyword, keyword) :: {:ok | :error, Response.t()}
  defp commit(method, path, body, opts, url_params) do
    headers = [{"content-type", "application/json"}, {"accept", "application/json"}]
    url = "#{@base_url}#{path}"

    res =
      HTTPoison.request(
        method,
        url,
        body,
        headers,
        opts ++ [params: [access_token: opts[:config][:access_token]]]
      )

    respond(res, opts)
  end

  defp token_params(%CreditCard{} = card) do
    %{
      expirationYear: card.year,
      expirationMonth: card.month,
      cardNumber: card.number,
      securityCode: card.verification_code,
      cardholder: %{name: CreditCard.full_name(card)}
    }
  end

  defp create_token(%CreditCard{} = card, opts) do
    url_params = [public_key: opts[:config][:public_key]]

    body =
      card
      |> token_params()
      |> Poison.encode!()

    {state, res} = commit(:post, "/v1/card_tokens/#{opts[:customer_id]}", body, opts, url_params)

    case state do
      :error -> {state, res}
      _ -> {state, res.id}
    end
  end

  defp authorize_params(value, opts, token_id, capture, %CreditCard{} = card) do
    %{
      installments: opts[:installments] || 1,
      transaction_amount: value,
      payment_method_id: String.downcase(card.brand),
      token: token_id,
      capture: capture,
      payer: %{
        email: opts[:email]
      }
    }
  end

  defp customer_params(%CreditCard{} = card, customer_id, opts) do
    %{
      payer: %{
        type: "customer",
        id: customer_id,
        first_name: card.first_name,
        last_name: card.last_name
      },
      order: %{
        type: opts[:order_type],
        id: opts[:order_id]
      }
    }
  end

  defp success_body(body, status_code, opts) do
    %Response{
      success: true,
      id: body["id"],
      token: opts[:customer_id],
      status_code: status_code,
      message: body["status"]
    }
  end

  defp error_body(body, status_code, opts) do
    %Response{
      success: false,
      token: opts[:customer_id],
      status_code: status_code,
      message: body["message"]
    }
  end

  defp respond({:ok, %HTTPoison.Response{body: body, status_code: status_code}}, opts) do
    body = body |> Poison.decode!()

    case body["cause"] do
      nil -> {:ok, success_body(body, status_code, opts)}
      _ -> {:error, error_body(body, status_code, opts)}
    end
  end

  defp respond({:error, %HTTPoison.Error{} = error}, _) do
    {
      :error,
      Response.error(
        reason: "network related failure",
        message: "HTTPoison says '#{error.reason}' [ID: #{error.id || "nil"}]"
      )
    }
  end
end
