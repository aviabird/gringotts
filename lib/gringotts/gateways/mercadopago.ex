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
  optional arguments for transactions with the mercadopago
  gateway. The following keys are supported:

  | Key                      | Remark                                                                                  |
  | ----                     | ---                                                                                     |
  | `email`                  | Email of the customer. Type - string .                                                  |
  | `order_id`               | Order id issued by the merchant. Type- integer.                                         |
  | `payment_method_id`      | Payment network operators, eg. `visa`, `mastercard`. Type- string.                      |
  | `customer_id`            | Unique customer id issued by the gateway. For new customer it must be nil. Type- string |  

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

  2. Run an `iex` session with `iex -S mix` and add some variable bindings :
  ```
  iex> card = %CreditCard{first_name: "John", last_name: "Doe", number: "4509953566233704", year: 2099, month: 12, verification_code: "123", brand: "VISA"}
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

  alias Gringotts.{CreditCard, Response}

  @doc """
  Performs a (pre) Authorize operation.

  The authorization validates the `card` details with the banking network,
  places a hold on the transaction `amount` in the customer’s issuing bank.

  mercadoapgo's `authorize` returns authorization ID :

  * `capture/3` _an_ amount.
  * `void/2` a pre-authorization.
  ## Note

  For a new customer, `customer_id` field should be ignored. Otherwise it should be provided.

  ## Example

  ### Authorization for new customer. (Ignore `customer_id`)
    The following example shows how one would (pre) authorize a payment of 42 BRL on a sample `card`.
      iex> amount = Money.new(42, :BRL)
      iex> card = %Gringotts.CreditCard{first_name: "Lord", last_name: "Voldemort", number: "4509953566233704", year: 2099, month: 12, verification_code: "123", brand: "VISA"}
      iex> opts = [email: "tommarvolo@riddle.com", order_id: 123123, payment_method_id: "visa", config: %{access_token: YOUR_ACCESS_TOKEN, public_key: YOUR_PUBLIC_KEY}]
      iex> {:ok, auth_result} = Gringotts.authorize(Gringotts.Gateways.Mercadopago, amount, card, opts)
      iex> auth_result.id # This is the authorization ID
      iex> auth_result.token # This is the customer ID/token

  ### Authorization for old customer. (Mention `customer_id`)
    The following example shows how one would (pre) authorize a payment of 42 BRL on a sample `card`.
      iex> amount = Money.new(42, :BRL)
      iex> card = %Gringotts.CreditCard{first_name: "Hermione", last_name: "Granger", number: "4509953566233704", year: 2099, month: 12, verification_code: "123", brand: "VISA"}
      iex> opts = [email: "hermione@granger.com", order_id: 123125, customer_id: "308537342-HStv9cJCgK0dWU", payment_method_id: "visa", config: %{access_token: YOUR_ACCESS_TOKEN, public_key: YOUR_PUBLIC_KEY}]
      iex> {:ok, auth_result} = Gringotts.authorize(Gringotts.Gateways.Mercadopago, amount, card, opts)
      iex> auth_result.id # This is the authorization ID
      iex> auth_result.token # This is the customer ID/token

  """

  @spec authorize(Money.t(), CreditCard.t(), keyword) :: {:ok | :error, Response}
  def authorize(amount , %CreditCard{} = card, opts) do
    if Keyword.has_key?(opts, :customer_id) do
      auth_token(amount, card, opts, opts[:customer_id], false)
    else
      case create_customer(opts) do
        {:error, res} -> {:error, res}
        {:ok, customer_id} ->  auth_token(amount, card, opts, customer_id, false)
      end
    end
  end
  

  

  ###############################################################################
  #                                PRIVATE METHODS                              #
  ###############################################################################
  
  # Makes the request to mercadopago's network.
  # For consistency with other gateway implementations, make your (final)
  # network request in here, and parse it using another private method called
  # `respond`.
  #@spec commit(_, _, _, _) :: {:ok | :error, Response}
  defp commit(method, path, body, headers) do
    HTTPoison.request(method, path, body, headers, [])
  end

  # Parses mercadopago's response and returns a `Gringotts.Response` struct
  # in a `:ok`, `:error` tuple.

  defp auth_token(amount, %CreditCard{} = card, opts, customer_id, capture) do
    opts = opts ++ [customer_id: customer_id]
    {state, res} = create_token(card, opts)
    if state == :error do
      {state, res}
    else
      auth(amount, card, opts, res, capture)
    end
  end

  defp auth(amount, %CreditCard{} = card, opts, token_id, capture) do
    {_, value, _, _} = Money.to_integer_exp(amount)
    opts = opts ++ [token_id: token_id]
    url = "#{@base_url}/v1/payments?access_token=#{opts[:config][:access_token]}"
    body = authorize_params(value, card, opts, opts[:token_id], opts[:customer_id], capture) |> Poison.encode!
    headers = [{"content-type", "application/json"}, {"accept", "application/json"}]
    commit(:post, url, body, headers)
    |> respond(opts)
  end
  
  defp create_customer(opts) do
    url = "#{@base_url}/v1/customers?access_token=#{opts[:config][:access_token]}"
    body = %{"email": opts[:email]} |> Poison.encode!
    headers = [{"content-type", "application/json"}, {"accept", "application/json"}]
    {state, res} = commit(:post, url, body, headers) |> respond(opts)
    if state == :error do
      {state, res}
    else
      {state, res.id}
    end
  end

  defp token_params(%CreditCard{} = card) do
    %{
      "expirationYear": card.year,
      "expirationMonth": card.month,
      "cardNumber": card.number,
      "securityCode": card.verification_code,
      "cardholder": %{"name": CreditCard.full_name(card)}
    }
  end

  defp create_token(%CreditCard{} = card, opts) do
    url = "#{@base_url}/v1/card_tokens/#{opts[:customer_id]}?public_key=#{opts[:config][:public_key]}"
    body = token_params(card) |> Poison.encode!()
    headers = [{"content-type", "application/json"}, {"accept", "application/json"}]
    {state, res} = commit(:post, url, body, headers) |> respond(opts)
    case state do
       :error -> {state, res}
       _ -> {state, res.id}
    end
  end

  defp authorize_params(value, %CreditCard{} = card, opts, token_id, customer_id, capture) do
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
      "installments": opts[:installments],
      "transaction_amount": value,
      "payment_method_id": opts[:payment_method_id], 
      "token": token_id,
      "capture": capture
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

  defp respond({:ok, %HTTPoison.Response{body: body, status_code: status_code}}, opts) do
    body = body |> Poison.decode!
    case body["cause"] do
      nil -> {:ok, get_success_body(body, status_code, opts)}
      _ -> {:error, get_error_body(body, status_code, opts)}
    end
  end

  defp respond({:error, %HTTPoison.Error{id: _, reason: _}}, opts) do
    {:error, "Network Error"}
  end

end

