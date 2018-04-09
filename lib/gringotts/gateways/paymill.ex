defmodule Gringotts.Gateways.Paymill do
  @moduledoc """
  [PAYMILL][home] gateway implementation.

  For refernce see [PAYMILL's API (v2.1) documentation][docs].

  The following features of PAYMILL are implemented:

  | Action                       | Method        |
  | ------                       | ------        |
  | Authorize                    | `authorize/3` |
  | Capture                      | `capture/3`   |
  | Purchase                     | `purchase/3`  |
  | Refund                       | `refund/3`    |
  | Store                        | `store/2`     |
  | Void                         | `void/2`      |

  ## The `opts` argument

  Most `Gringotts` API calls accept an optional `keyword` list `opts` to supply
  optional arguments for transactions with the PAYMILL gateway. **Currently, no
  optional params are supported.**

  > These are being implemented, track progress in [issue #50][iss50]!

  [iss50]: https://github.com/aviabird/gringotts/issues/50

  ## Registering your PAYMILL account at `Gringotts`

  After [making an account on PAYMILL][dashboard], head to the dashboard and find
  your account "secrets".

  Here's how the secrets map to the required configuration parameters for PAYMILL:

  | Config parameter | PAYMILL secret  |
  | -------          | ----            |
  | `:private_key`   | **Private Key** |
  | `:public_key`    | **Public Key**  |

  Your Application config **must include the `:private_key`, `:public_key`
  fields** and would look something like this:

      config :gringotts, Gringotts.Gateways.Paymill,
        private_key: "your_secret_private_key",
        public_key: "your_secret_public_key"

  ## Scope of this module

  * PAYMILL does processes money in cents.

  ## Supported countries
  **citation-needed**

  ## Supported currencies
  **citation-needed**

  ## Following the examples

  1. First, set up a sample application and configure it to work with PAYMILL.
  - You could do that from scratch by following our [Getting Started][gs] guide.
      - To save you time, we recommend [cloning our example repo][example-repo]
        that gives you a pre-configured sample app ready-to-go.
        + You could use the same config or update it the with your "secrets" as
          described
          [above](#module-registering-your-paymill-account-at-gringotts).

  2. Run an `iex` session with `iex -S mix` and add some variable bindings and
     aliases to it (to save some time):
  ```
  iex> alias Gringotts.{Response, CreditCard, Gateways.Paymill}
  iex> amount = %{value: Decimal.new(42), currency: "EUR"}
  iex> card = %CreditCard{first_name: "Harry",
                          last_name: "Potter",
                          number: "4200000000000000",
                          year: 2099, month: 12,
                          verification_code: "123",
                          brand: "VISA"}
  ```

  We'll be using these in the examples below.

  [home]: https://paymill.com
  [docs]: https://developers.paymill.com/API/index
  [dashboard]: https://app.paymill.com/user/register
  [all-card-list]: #
  [gs]: https://github.com/aviabird/gringotts/wiki
  [example-repo]: https://github.com/aviabird/gringotts_example
  """
  use Gringotts.Gateways.Base
  use Gringotts.Adapter, required_config: [:private_key, :public_key]

  alias Gringotts.{CreditCard, Response, Money}
  alias Gringotts.Gateways.Paymill.ResponseHandler, as: ResponseParser

  @live_url "https://api.paymill.com/v2.1/"
  @save_card_test_url "https://test-token.paymill.com/"
  @save_card_live_url "https://token-v2.paymill.de/"
  @headers [{"Content-Type", "application/x-www-form-urlencoded"}]
  @money_format :cents
  @default_currency "EUR"

  @doc """
  Performs a (pre) Authorize operation.

  The authorization validates the `card` details with the banking network,
  places a hold on the transaction `amount` in the customer’s issuing bank and
  also triggers risk management. Funds are not transferred.

  The authorization token is available in the `Response.authorization` field.

  ## Example

  The following example shows how one would (pre) authorize a payment of €42 on
  a sample `card`.
  ```
  iex> amount = %{value: Decimal.new(42), currency: "EUR"}
  iex> card = %CreditCard{first_name: "Harry",
                          last_name: "Potter",
                          number: "4111111111111111",
                          year: 2099, month: 12,
                          verification_code: "123",
                          brand: "VISA"}

  iex> {:ok, auth_result} = Gringotts.authorize(Gringotts.Gateways.Paymill, amount, card)
  iex> auth_result.authorization # This is the auth-token
  ```
  """
  @spec authorize(Money.t(), String.t() | CreditCard.t(), keyword) :: {:ok | :error, Response}
  def authorize(amount, card_or_token, options) do
    action_with_token(:authorize, amount, card_or_token, options)
  end

  @doc """
  Captures a pre-authorized `amount`.

  `amount` is transferred to the merchant account by PAYMILL when it is smaller or
  equal to the amount used in the pre-authorization referenced by `payment_id`.

  ## Note

  PAYMILL allows partial captures and unlike many other gateways, and releases
  any remaining amount back to the payment source.
  > Thus, the same pre-authorisation ID **cannot** be used to perform multiple
    captures.

  ## Example

  The following example shows how one would (partially) capture a previously
  authorized a payment worth €35 by referencing the obtained authorization `id`.

  ```
  iex> amount = %{value: Decimal.new(35), currency: "EUR"}
  iex> token = auth_result.authorization
  # token = "some_authorization_token"
  iex> Gringotts.capture(Gringotts.Gateways.Paymill, token, amount)
  ```
  """
  @spec capture(String.t(), Money.t(), keyword) :: {:ok | :error, Response}
  def capture(payment_id, amount, options) do
    {currency, int_value, _} = Money.to_integer(amount)
    post = [amount: int_value, currency: currency] ++ [preauthorization: payment_id]
    commit(:post, "transactions", post, options)
  end

  @doc """
  Transfers `amount` from the customer to the merchant.

  PAYMILL attempts to process a purchase on behalf of the customer, by debiting
  `amount` from the customer's account by charging the customer's `card`.

  ## Example

  The following example shows how one would process a payment worth €42 in
  one-shot, without (pre) authorization.

  ```
  iex> amount = %{value: Decimal.new(42), currency: "EUR"}
  iex> card = %CreditCard{first_name: "Harry",
                          last_name: "Potter",
                          number: "4111111111111111",
                          year: 2099, month: 12,
                          verification_code: "123",
                          brand: "VISA"}

  iex> {:ok, purchase_result} = Gringotts.purchase(Gringotts.Gateways.Paymill, amount, card)
  ```
  """
  @spec purchase(Money.t(), CreditCard.t(), keyword) :: {:ok | :error, Response}
  def purchase(amount, card, options) do
    action_with_token(:purchase, amount, card, options)
  end

  @doc """
  Refunds the `amount` to the customer's account with reference to a prior transfer.

  PAYMILL processes a full or partial refund worth `amount`, where `payment_id`
  references a previous `purchase/3` or `capture/3`. Multiple partial refunds
  are allowed on the same `payment_id` till all the captured/purchased amount
  has been refunded.

  ## Example

  The following example shows how one would refund a previous purchase (and
  similarily for captures).
  ```
  iex> purchase_token = purchase_result.authorization
  iex> amount = %{value: Decimal.new(42), currency: "EUR"}
  iex> Gringotts.refund(Gringotts.Gateways.Paymill, amount, purchase_token)
  ```
  """
  @spec refund(Money.t(), String.t(), keyword) :: {:ok | :error, Response}
  def refund(amount, payment_id, options) do
    {_, int_value, _} = Money.to_integer(amount)

    commit(:post, "refunds/#{payment_id}", [amount: int_value], options)
  end

  @doc """
  Stores card details at Paymill.
  ### Example

  The following example shows how one would store any valid card details
  at Paymill.
  '''
  iex> card = %CreditCard{first_name: "Harry",
                      last_name: "Potter",
                      number: "4111111111111111",
                      year: 2099, month: 12,
                      verification_code: "123",
                      brand: "VISA"}

  iex> options = [config: [mode: <:live | :test>, private_key: <your_private_key>, public_key: <your_public_key>]]
  iex> Gringotts.store(Gringotts.Gateways.Paymill, card, options)
  '''
  """
  @spec store(CreditCard.t(), keyword) :: Response
  def store(card, options) do
    save_card(card, options)
  end

  @doc """
  Voids the referenced authorization.

  This method attempts a reversal of the a previous `authorize/3` referenced by
  `authorization_id`.

  PAYMILL supports voiding captures and purchases as well, but that's not
  implemented yet. **citation-needed**

  ## Example

  The following example shows how one would void a previous capture.
  ```
  iex> auth_token = auth_result.authorization
  iex> Gringotts.void(Gringotts.Gateways.Paymill, auth_token)
  ```
  """
  @spec void(String.t(), keyword) :: {:ok | :error, Response}
  def void(authorization_id, options) do
    commit(:delete, "preauthorizations/#{authorization_id}", [], options)
  end

  @doc false
  @spec authorize_with_token(Money.t(), String.t(), keyword) :: term
  def authorize_with_token(money, card_token, options) do
    post = amount_params(money) ++ [token: card_token]

    commit(:post, "preauthorizations", post, options)
  end

  @doc false
  @spec purchase_with_token(Money.t(), String.t(), keyword) :: term
  def purchase_with_token(money, card_token, options) do
    post = amount_params(money) ++ [token: card_token]

    commit(:post, "transactions", post, options)
  end

  @doc false
  @spec save_card(CreditCard.t(), keyword) :: Response
  defp save_card(card, options) do
    {:ok, %HTTPoison.Response{body: response}} =
      HTTPoison.get(
        get_save_card_url_by_mode(options),
        get_headers(options),
        params: get_save_card_params(card, options)
      )

    parse_card_response(response)
  end

  @doc false
  defp get_save_card_url_by_mode(options) do
    case get_config(:mode, options) do
      :test -> @save_card_test_url
      _ -> @save_card_live_url
    end
  end

  @doc false
  defp action_with_token(action, amount, "tok_" <> _ = card_token, options) do
    apply(__MODULE__, String.to_atom("#{action}_with_token"), [amount, card_token, options])
  end

  @doc false
  defp action_with_token(action, amount, %CreditCard{} = card, options) do
    {currency, int_value, _} = Money.to_integer(amount)
    {:ok, response} = save_card(card, [money: int_value, currency: currency] ++ options)
    card_token = get_token(response)

    apply(__MODULE__, String.to_atom("#{action}_with_token"), [amount, card_token, options])
  end

  @doc false
  defp action_with_token(action, amount, _ = card_token, options) do
    {:error, "Expected valid card or token, received '#{card_token}'"}
    |> ResponseParser.parse()
  end

  @doc false
  defp get_save_card_params(card, options) do
    [
      {"transaction.mode", "CONNECTOR_TEST"},
      {"channel.id", get_config(:public_key, options)},
      {"jsonPFunction", "jsonPFunction"},
      {"account.number", card.number},
      {"account.expiry.month", card.month},
      {"account.expiry.year", card.year},
      {"account.verification", card.verification_code},
      {"account.holder", "#{card.first_name} #{card.last_name}"},
      {"presentation.amount3D", get_amount(options)},
      {"presentation.currency3D", get_currency(options)}
    ]
  end

  @doc false
  defp get_currency(options), do: options[:currency] || @default_currency

  @doc false
  defp get_amount(options), do: options[:money]

  @doc false
  defp get_headers(options) do
    @headers ++ set_username(options)
  end

  @doc false
  defp amount_params(money) do
    {currency, int_value, _} = Money.to_integer(money)
    [amount: int_value, currency: currency]
  end

  @doc false
  defp set_username(options) do
    [{"Authorization", "Basic #{Base.encode64(get_config(:private_key, options))}"}]
  end

  @doc false
  defp parse_card_response(response) do
    response
    |> String.replace(~r/jsonPFunction\(/, "")
    |> String.replace(~r/\)/, "")
    |> Poison.decode()
  end

  @doc false
  defp get_token(response) do
    get_in(response, ["transaction", "identification", "uniqueId"])
  end

  @doc false
  defp commit(method, action, parameters, options) do
    method
    |> HTTPoison.request(@live_url <> action, {:form, parameters}, get_headers(options))
    |> ResponseParser.parse()
  end

  @doc false
  defp get_config(key, options) do
    get_in(options, [:config, key])
  end

  defmodule ResponseHandler do
    @moduledoc false

    alias Gringotts.Response

    @response_code %{
      10_001 => "Undefined response",
      10_002 => "Waiting for something",
      11_000 => "Retry request at a later time",
      20_000 => "Operation successful",
      20_100 => "Funds held by acquirer",
      20_101 => "Funds held by acquirer because merchant is new",
      20_200 => "Transaction reversed",
      20_201 => "Reversed due to chargeback",
      20_202 => "Reversed due to money-back guarantee",
      20_203 => "Reversed due to complaint by buyer",
      20_204 => "Payment has been refunded",
      20_300 => "Reversal has been canceled",
      22_000 => "Initiation of transaction successful",
      30_000 => "Transaction still in progress",
      30_100 => "Transaction has been accepted",
      31_000 => "Transaction pending",
      31_100 => "Pending due to address",
      31_101 => "Pending due to uncleared eCheck",
      31_102 => "Pending due to risk review",
      31_103 => "Pending due regulatory review",
      31_104 => "Pending due to unregistered/unconfirmed receiver",
      31_200 => "Pending due to unverified account",
      31_201 => "Pending due to non-captured funds",
      31_202 => "Pending due to international account (accept manually)",
      31_203 => "Pending due to currency conflict (accept manually)",
      31_204 => "Pending due to fraud filters (accept manually)",
      40_000 => "Problem with transaction data",
      40_001 => "Problem with payment data",
      40_002 => "Invalid checksum",
      40_100 => "Problem with credit card data",
      40_101 => "Problem with CVV",
      40_102 => "Card expired or not yet valid",
      40_103 => "Card limit exceeded",
      40_104 => "Card is not valid",
      40_105 => "Expiry date not valid",
      40_106 => "Credit card brand required",
      40_200 => "Problem with bank account data",
      40_201 => "Bank account data combination mismatch",
      40_202 => "User authentication failed",
      40_300 => "Problem with 3-D Secure data",
      40_301 => "Currency/amount mismatch",
      40_400 => "Problem with input data",
      40_401 => "Amount too low or zero",
      40_402 => "Usage field too long",
      40_403 => "Currency not allowed",
      40_410 => "Problem with shopping cart data",
      40_420 => "Problem with address data",
      40_500 => "Permission error with acquirer API",
      40_510 => "Rate limit reached for acquirer API",
      42_000 => "Initiation of transaction failed",
      42_410 => "Initiation of transaction expired",
      50_000 => "Problem with back end",
      50_001 => "Country blacklisted",
      50_002 => "IP address blacklisted",
      50_004 => "Live mode not allowed",
      50_005 => "Insufficient permissions (API key)",
      50_100 => "Technical error with credit card",
      50_101 => "Error limit exceeded",
      50_102 => "Card declined",
      50_103 => "Manipulation or stolen card",
      50_104 => "Card restricted",
      50_105 => "Invalid configuration data",
      50_200 => "Technical error with bank account",
      50_201 => "Account blacklisted",
      50_300 => "Technical error with 3-D Secure",
      50_400 => "Declined because of risk issues",
      50_401 => "Checksum was wrong",
      50_402 => "Bank account number was invalid (formal check)",
      50_403 => "Technical error with risk check",
      50_404 => "Unknown error with risk check",
      50_405 => "Unknown bank code",
      50_406 => "Open chargeback",
      50_407 => "Historical chargeback",
      50_408 => "Institution / public bank account (NCA)",
      50_409 => "KUNO/Fraud",
      50_410 => "Personal Account Protection (PAP)",
      50_420 => "Rejected due to acquirer fraud settings",
      50_430 => "Rejected due to acquirer risk settings",
      50_440 => "Failed due to restrictions with acquirer account",
      50_450 => "Failed due to restrictions with user account",
      50_500 => "General timeout",
      50_501 => "Timeout on side of the acquirer",
      50_502 => "Risk management transaction timeout",
      50_600 => "Duplicate operation",
      50_700 => "Cancelled by user",
      50_710 => "Failed due to funding source",
      50_711 => "Payment method not usable, use other payment method",
      50_712 => "Limit of funding source was exceeded",
      50_713 => "Means of payment not reusable (canceled by user)",
      50_714 => "Means of payment not reusable (expired)",
      50_720 => "Rejected by acquirer",
      50_730 => "Transaction denied by merchant",
      50_800 => "Preauthorisation failed",
      50_810 => "Authorisation has been voided",
      50_820 => "Authorisation period expired"
    }

    def parse({:ok, %HTTPoison.Response{body: body, status_code: 200}}) do
      body = Poison.decode!(body)
      parse_body([status_code: 200], body)
    end

    def parse({:ok, %HTTPoison.Response{body: body, status_code: status_code}})
        when status_code in [400, 404, 409] do
      body = Poison.decode!(body)

      [status_code: status_code, success: false]
      |> set_params(body)
      |> handle_error(body)
      |> handle_opts
    end

    def parse({:ok, %HTTPoison.Response{body: body, status_code: 403}}) do
      body = Poison.decode!(body)

      [status_code: 403, success: false]
      |> parse_body(body)
    end

    def parse({:error, %HTTPoison.Error{} = error}) do
      {:error, Response.error(error_code: error.id, message: "HTTPoison says '#{error.reason}'.")}
    end

    def parse({:error, rnd_error_msg}) do
      {:error, Response.error(message: rnd_error_msg)}
    end

    defp set_success(opts, %{"error" => error}) do
      opts ++ [message: error, success: false]
    end

    defp set_success(opts, %{"status" => "deleted"}) do
      opts ++ [success: true]
    end

    defp set_success(opts, %{"status" => "failed"}) do
      opts ++ [success: false]
    end

    defp set_success(opts, %{"transaction" => %{"response_code" => 20_000}}) do
      opts ++ [success: true]
    end

    defp set_success(opts, %{"response_code" => 20_000}) do
      opts ++ [success: true]
    end

    defp handle_error(opts, %{"error" => %{"messages" => messages}}) do
      [{_, msg} | _] = Map.to_list(messages)
      opts ++ [message: msg]
    end

    defp handle_error(opts, %{"error" => msg}) do
      opts ++ [message: msg]
    end

    defp parse_body(opts, %{"data" => data}) do
      opts
      |> set_success(data)
      |> parse_authorization(data)
      |> parse_status_code(data)
      |> set_params(data)
      |> handle_opts()
    end

    defp handle_opts(opts) do
      case Keyword.fetch(opts, :success) do
        {:ok, true} -> {:ok, Response.success(opts)}
        {:ok, false} -> {:error, Response.error(opts)}
      end
    end

    # Status code
    defp parse_status_code(opts, %{"status" => "failed", "response_code" => code}) do
      response_msg = Map.get(@response_code, code, -1)

      opts ++ [error_code: code, message: response_msg]
    end

    defp parse_status_code(opts, %{"status" => "failed"} = body) do
      response_code = get_in(body, ["transaction", "response_code"])
      response_msg = Map.get(@response_code, response_code, -1)
      opts ++ [error_code: response_code, message: response_msg]
    end

    defp parse_status_code(opts, %{"transaction" => transaction}) do
      response_code = Map.get(transaction, "response_code", -1)
      response_msg = Map.get(@response_code, response_code, -1)
      opts ++ [error_code: response_code, message: response_msg]
    end

    defp parse_status_code(opts, %{"response_code" => code}) do
      response_msg = Map.get(@response_code, code, -1)
      opts ++ [error_code: code, message: response_msg]
    end

    # Authorization
    defp parse_authorization(opts, %{"status" => "failed"}) do
      opts ++ [success: false]
    end

    defp parse_authorization(opts, %{"id" => id}) do
      opts ++ [authorization: id]
    end

    defp set_params(opts, body), do: opts ++ [params: body]
  end
end
