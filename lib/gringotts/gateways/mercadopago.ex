defmodule Gringotts.Gateways.Mercadopago do
  @moduledoc """
  [MERCADOPAGO][home] gateway implementation.

  For reference see [MERCADOPAGO API (v1) documentation][docs].

  The following features of MERCADOPAGO are implemented:

  | Action                       | Method        | 
  | ------                       | ------        | 
  | Pre-authorize                | `authorize/3` | 

  [home]: https://www.mercadopago.com/
  [docs]: https://www.mercadopago.com.ar/developers/en/api-docs/

  ## The `opts` argument

  Most `Gringotts` API calls accept an optional `keyword` list `opts` to supply
  optional arguments for transactions with the MERCADOAPGO
  gateway. The following keys are supported:

  | Key                      | Remark                                                                                  |
  | ----                     | ---                                                                                     |
  | `email`                  | Email of the customer. Type - string .                                                  |
  | `order_id`               | Order id issued by the merchant. Type- integer.                                         |
  | `payment_method_id`      | Payment network operators, eg. `visa`, `mastercard`. Type- string.                      |
  | `customer_id`            | Unique customer id issued by the gateway. For new customer it must be nil. Type- string |  

  ## Registering your MERCADOPAGO account at `Gringotts`

  After [making an account on MERCADOPAGO][credentials], head to the credentials and find
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

  * MERCADOPAGO does not process money in cents, and the `amount` is rounded to 2
    decimal places.

  > Please [raise an issue][new-issue] if you'd like us to add support for more
  > currencies
  [new-issue]: https://github.com/aviabird/gringotts/issues

  ## Supported currencies and countries

  > MERCADOPAGO supports the currencies listed [here][all-currency-list]
  [all-currency-list]: https://www.mercadopago.com.br/developers/en/api-docs/account/payments/search
      :ARS, :BRL, :VEF,:CLP, :MXN, :COP, :PEN, :UYU

  ## Following the examples

  1. First, set up a sample application and configure it to work with MERCADOPAGO.
  - You could do that from scratch by following our [Getting Started][gs] guide.
      - To save you time, we recommend [cloning our example
      repo][example] that gives you a pre-configured sample app ready-to-go.
          + You could use the same config or update it the with your "secrets"
          as described [above](#module-registering-your-monei-account-at-mercadopago).

  2. Run an `iex` session with `iex -S mix` and add some variable bindings :
  ```
  iex> card = %{first_name: "John",
                last_name: "Doe",
                number: "4509953566233704",
                year: 2099,
                month: 12,
                verification_code: "123",
                brand: "VISA"}
  ```

  We'll be using these in the examples below.

  [gs]: https://github.com/aviabird/gringotts/wiki/
  [home]: https://www.mercadopago.com
  [example]: https://github.com/aviabird/gringotts_example
  """

  # The Base module has the (abstract) public API, and some utility
  # implementations.  
  @base_url "https://api.mercadopago.com"
  use Gringotts.Gateways.Base
  alias Gringotts.CreditCard
  # The Adapter module provides the `validate_config/1`
  # Add the keys that must be present in the Application config in the
  # `required_config` list
  use Gringotts.Adapter, required_config: [:public_key, :access_token]
  
  import Poison, only: [decode: 1]

  alias Gringotts.{CreditCard,
                   Response}

  @doc """
  Performs a (pre) Authorize operation.

  The authorization validates the `card` details with the banking network,
  places a hold on the transaction `amount` in the customer’s issuing bank.

  MERCADOPAGO's `authorize` returns a map containing authorization ID string which can be used to:

  * `capture/3` _an_ amount.
  * `void/2` a pre-authorization.
  
  ## Note

  > If there's anything noteworthy about this operation, it comes here.

  ## Example
      iex> amount = Money.new(42, :BRL)
      iex> card = %Gringotts.CreditCard{
            first_name: "John",
            last_name: "Doe",
            number: "4509953566233704",
            year: 2099,
            month: 12,
            verification_code: "123",
            brand: "VISA"
        }
      iex> opts = [email: "xyz@test.com",
           order_id: 123125,
           customer_id: "308537342-HStv9cJCgK0dWU",
           payment_method_id: "visa",
           config: %{access_token: "TEST-2774702803649645-031303-1b9d3d63acb57cdad3458d386eee62bd-307592510",
           public_key: "TEST-911f45a1-0560-4c16-915e-a8833830b29a"}]
      iex> {:ok, auth_result} = Gringotts.authorize(Gringotts.Gateways.Mercadopago, amount, card, opts)
      iex> auth_result.id # This is the authorization ID
      iex> auth_result.token # This is the customer ID/token

  """

  @spec authorize(Money.t(), CreditCard.t(), keyword) :: {:ok | :error, Response}
  def authorize(amount , %CreditCard{} = card, opts) do
    {_, value, _, _} = Money.to_integer_exp(amount)
    if(is_nil(opts[:customer_id])) do
      customer_id = get_customer_id(opts)
      opts = opts ++ [customer_id: customer_id]
    end
    token_id = get_token_id(card, opts)
    opts = opts ++ [token_id: token_id]

    body = get_authorize_body(value, card, opts, opts[:token_id], opts[:customer_id]) |> Poison.encode!()
    headers = [{"content-type", "application/json"}, {"accept", "application/json"}]

    response = HTTPoison.post!("#{@base_url}/v1/payments?access_token=#{opts[:config][:access_token]}", body, headers, [])
    %HTTPoison.Response{body: body, status_code: status_code} = response
    body = body |> Poison.decode!()
    format_response(body, status_code, opts)
  end

  @doc """
  Captures a pre-authorized `amount`.

  `amount` is transferred to the merchant account by mercadopago used in the
  pre-authorization referenced by `payment_id`.

  ## Note

  > If there's anything noteworthy about this operation, it comes here.
  > For example, does the gateway support partial, multiple captures?

  ## Example

  > A barebones example using the bindings you've suggested in the `moduledoc`.
  """
  @spec capture(String.t(), Money.t, keyword) :: {:ok | :error, Response}
  def capture(payment_id, amount, opts) do
    body = %{"capture": true} |> Poison.encode!
    headers = [{"content-type", "application/json"}, {"accept", "application/json"}]
    response = HTTPoison.put!("#{@base_url}/v1/payments/#{payment_id}?access_token=#{opts[:config][:access_token]}", body, headers, [])
    %HTTPoison.Response{body: body, status_code: status_code} = response
    body = body |> Poison.decode!()
    format_response(body, status_code, opts)
  end

  @doc """
  Transfers `amount` from the customer to the merchant.

  mercadopago attempts to process a purchase on behalf of the customer, by
  debiting `amount` from the customer's account by charging the customer's
  `card`.

  ## Note

  > If there's anything noteworthy about this operation, it comes here.

  ## Example

  > A barebones example using the bindings you've suggested in the `moduledoc`.
  """
  @spec purchase(Money.t, CreditCard.t(), keyword) :: {:ok | :error, Response}
  def purchase(amount, %CreditCard{} = card, opts) do
    # commit(args, ...)
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
  > that true for mercadopago?
  > Is there a limited time window within which a void can be perfomed?

  ## Example

  > A barebones example using the bindings you've suggested in the `moduledoc`.
  """
  @spec refund(Money.t, String.t(), keyword) :: {:ok | :error, Response}
  def refund(amount, payment_id, opts) do
    {_, value, _, _} = Money.to_integer_exp(amount)
    body = %{"amount": value} |> Poison.encode!
    headers = [{"content-type", "application/json"}]
    response = HTTPoison.post!("#{@base_url}/v1/payments/#{payment_id}/refunds?access_token=#{opts[:config][:access_token]}", body, headers, [])
    %HTTPoison.Response{body: body, status_code: status_code} = response
    body = body |> Poison.decode!
    format_response(body, status_code, opts)
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
  
  # Makes the request to mercadopago's network.
  # For consistency with other gateway implementations, make your (final)
  # network request in here, and parse it using another private method called
  # `respond`.
  @spec commit(_) :: {:ok | :error, Response}
  defp commit(_) do
    # resp = HTTPoison.request(args, ...)
    # respond(resp, ...)
  end

  # Parses mercadopago's response and returns a `Gringotts.Response` struct
  # in a `:ok`, `:error` tuple.
  @spec respond(term) :: {:ok | :error, Response}
  defp respond(mercadopago_response)
  defp respond({:ok, %{status_code: 200, body: body}}), do: "something"
  defp respond({:ok, %{status_code: status_code, body: body}}), do: "something"
  defp respond({:error, %HTTPoison.Error{} = error}), do: "something"

  defp get_customer_id(opts) do
    body = %{"email": opts[:email]} |> Poison.encode!
    headers = [{"content-type", "application/json"}, {"accept", "application/json"}]
    response = HTTPoison.post!("#{@base_url}/v1/customers?access_token=#{opts[:config][:access_token]}", body, headers, [])
    %HTTPoison.Response{body: body} = response
    body = body |> Poison.decode!()
    body["id"]
  end

  defp get_token_body(%CreditCard{} = card) do
    %{
      "expirationYear": card.year,
      "expirationMonth": card.month,
      "cardNumber": card.number,
      "securityCode": card.verification_code,
      "cardholder": %{
        "name": card.first_name <> card.last_name
      }
    }
  end 

  defp get_token_id(%CreditCard{} = card, opts) do
    body = get_token_body(card) |> Poison.encode!()
    headers = [{"content-type", "application/json"}, {"accept", "application/json"}]
    token = HTTPoison.post!("#{@base_url}/v1/card_tokens/#{opts[:customer_id]}?public_key=#{opts[:config][:public_key]}", body, headers, [])
    %HTTPoison.Response{body: body} = token
    body = body |> Poison.decode!()
    body["id"]
  end

  defp get_authorize_body(value, %CreditCard{} = card, opts, token_id, customer_id) do
    %{
      "payer": %{
                "type": "customer",
                "id": customer_id,
                "first_name": card.first_name,
                "last_name": card.last_name
              },
      "order": %{
                "type": "mercadopago",
                "id": opts[:order_id]
              },
      "installments": 1,
      "transaction_amount": value,
      "payment_method_id": opts[:payment_method_id],    #visa
      "token": token_id,
      "capture": false
  }
  end

  defp get_success_body(body, status_code, opts) do
    %Response{
    success: true,
    id: body["id"],
    token: opts[:customer_id],
    status_code: status_code,
    message: body["status"]
  }
  end
  defp get_error_body(body, status_code, opts) do
    %Response{
    success: false,
    token: opts[:customer_id],
    status_code: status_code,
    message: body["message"]
    }
  end

  defp format_response(body, status_code, opts) do
    case body["cause"] do
      nil -> {:ok, get_success_body(body, status_code, opts)}
      _ -> {:error, get_error_body(body, status_code, opts)}
    end
  end

end
