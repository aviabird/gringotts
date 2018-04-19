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
  | Void                         | `void/2`      |

  ## The `opts` argument

  Most `Gringotts` API calls accept an optional `keyword` list `opts` to supply
  optional arguments for transactions with the PAYMILL gateway. **Currently, no
  optional params are supported.**

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
  * PAYMILL processes money in the sub-divided unit of currency (ie, in case of USD it works in cents).
  * PAYMILL does not offer direct API integration for [PCI DSS][pci-dss] compliant merchants, everyone must use PAYMILL as if they are not PCI compliant.
  - To use their product, a merchant (aka user of this library) would have to use their [Bridge (js integration)](https://developers.paymill.com/guides/reference/paymill-bridge.html) (or equivalent) in your application frontend to collect Credit/Debit Card data.
  - This would obtain a unique `card_token` at the client-side which can be used by this module for various operations like `authorize/3` and `purchase/3`.

  ## Supported countries
  As a PAYMILL merchant you can accept payments from around the globe. For more details
  refer to [Paymill country support][country-support].

  ## Supported currencies
  Your transactions will be processed in your native currency. For more information
  refer to [Paymill currency support][currency-support].

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
  iex> amount = Money.new(4200, :EUR)
  ```

  We'll be using these in the examples below.

  [home]: https://paymill.com
  [docs]: https://developers.paymill.com
  [dashboard]: https://app.paymill.com/user/register
  [all-card-list]: #
  [gs]: https://github.com/aviabird/gringotts/wiki
  [example-repo]: https://github.com/aviabird/gringotts_example
  [currency-support]: https://www.paymill.com/en/faq/in-which-currency-will-my-transactions-be-processed-and-payout-in
  [country-support]: https://www.paymill.com/en/faq/which-countries-is-paymill-available-in
  [pci-dss]: https://www.paymill.com/en/pci-dss
  """
  use Gringotts.Gateways.Base
  use Gringotts.Adapter, required_config: [:private_key, :public_key]

  alias Gringotts.{CreditCard, Response, Money}
  alias Gringotts.Gateways.Paymill.ResponseHandler, as: ResponseParser

  @base_url "https://api.paymill.com/v2.1/"
  @headers [{"Content-Type", "application/x-www-form-urlencoded"}]
  @action %{:purchase => "transactions", :authorize => "preauthorizations", :refund => "refunds"}
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

  @doc """
  Performs a (pre) Authorize operation.

  The authorization validates the `card` details for `token` with the banking network,
  places a hold on the transaction `amount` in the customer’s issuing bank and
  also triggers risk management. Funds are not transferred.

  The authorization token is available in the `Response.id` field.

  ## Example

  The following example shows how one would (pre) authorize a payment of €42 on
  a sample `token`.
  ```
  iex> amount = Money.new(4200, :EUR)
  iex> card_token = "tok_XXXXXXXXXXXXXXXXXXXXXXXXXXXX"

  iex> {:ok, auth_result} = Gringotts.authorize(Gringotts.Gateways.Paymill, amount, card_token)
  iex> auth_result.id # This is the preauth-id
  ```
  """

  @spec authorize(Money.t(), String.t(), keyword) :: {:ok | :error, Response.t()}
  def authorize(amount, card_token, opts) do
    param = amount_params(amount) ++ [token: card_token]
    commit(:post, "preauthorizations", param, opts)
  end

  @doc """
  Captures a pre-authorized `amount`.

  `amount` is transferred to the merchant account by PAYMILL when it is smaller or
  equal to the amount used in the pre-authorization referenced by `preauth_id`.

  ## Note

  PAYMILL allows partial captures and unlike many other gateways, and releases
  any remaining amount back to the payment source.
  > Thus, the same pre-authorisation ID **cannot** be used to perform multiple
    captures.

  ## Example

  The following example shows how one would (partially) capture a previously
  authorized a payment worth €35 by referencing the obtained authorization `id`.

  ```
  iex> amount = Money.new(4200, :EUR)
  iex> preauth_id = auth_result.id
  # preauth_id = "some_authorization_id"
  iex> Gringotts.capture(Gringotts.Gateways.Paymill, preauth_id, amount)
  ```
  """
  @spec capture(String.t(), Money.t(), keyword) :: {:ok | :error, Response.t()}
  def capture(id, amount, opts) do
    param = amount_params(amount) ++ [preauthorization: id]
    commit(:post, "transactions", param, opts)
  end

  @doc """
  Transfers `amount` from the customer to the merchant.

  PAYMILL attempts to process a purchase on behalf of the customer, by debiting
  `amount` from the customer's account by charging the customer's `card` via `token`.

  ## Example

  The following example shows how one would process a payment worth €42 in
  one-shot, without (pre) authorization.

  ```
  iex> amount = Money.new(4200, :EUR)
  iex> token = "tok_XXXXXXXXXXXXXXXXXXXXXXXXXXXX"

  iex> {:ok, purchase_result} = Gringotts.purchase(Gringotts.Gateways.Paymill, amount, token)
  ```
  """

  @spec purchase(Money.t(), String.t(), keyword) :: {:ok | :error, Response.t()}
  def purchase(amount, card_token, opts) do
    param = amount_params(amount) ++ [token: card_token]
    commit(:post, "transactions", param, opts)
  end

  @doc """
  Refunds the `amount` to the customer's account with reference to a prior transfer.

  PAYMILL processes a full or partial refund worth `amount`, where `transaction_id`
  references a previous `purchase/3` or `capture/3`. Multiple partial refunds
  are allowed on the same `transaction_id` till all the captured/purchased amount
  has been refunded.

  ## Example

  The following example shows how one would refund a previous purchase (and
  similarily for captures).
  ```
  iex> transaction_id = purchase_result.id
  iex> amount = Money.new(4200, :EUR)
  iex> Gringotts.refund(Gringotts.Gateways.Paymill, amount, transaction_id)
  ```
  """
  @spec refund(Money.t(), String.t(), keyword) :: {:ok | :error, Response.t()}
  def refund(amount, id, opts) do
    commit(:post, "refunds/#{id}", amount_params(amount), opts)
  end

  @doc """
  Voids the referenced authorization.

  This method attempts a reversal of the a previous `authorize/3` referenced by
  `preauth_id`.

  ## Example

  The following example shows how one would void a previous capture.
  ```
  iex> preauth_id = auth_result.id
  iex> Gringotts.void(Gringotts.Gateways.Paymill, preauth_id)
  ```
  """
  @spec void(String.t(), keyword) :: {:ok | :error, Response.t()}
  def void(id, opts) do
    commit(:delete, "preauthorizations/#{id}", [], opts)
  end

  defp request_maker(method, url, body \\ "", headers \\ [], options \\ []) do
    HTTPoison.request(method, url, body, headers, options)
  end

  defp response_matcher({:ok, %HTTPoison.Response{} = response}) do
    response.body
  end

  defp response_matcher({:error, %HTTPoison.Error{} = error}) do
    error
    |> string_key_map
  end

  defp string_key_map(map) do
    new_map = %{}

    new_map =
      for key <- Map.keys(map), into: %{}, do: {Atom.to_string(key), to_string(Map.get(map, key))}

    new_map
  end

  defp response_maker(response \\ %{}, status_code, atom) do
    {:ok, parsed_resp} = parse_response(response)

    resp_code =
      parsed_resp["transaction"]["response_code"] ||
        parsed_resp["data"]["transaction"]["response_code"] ||
        parsed_resp["data"]["response_code"]

    {atom,
     %Response{
       id: parsed_resp["id"] || parsed_resp["data"]["id"],
       token: parsed_resp["transaction"]["identification"]["uniqueId"],
       status_code: status_code,
       gateway_code: resp_code,
       reason: parsed_resp["reason"] || parsed_resp["error"] || parsed_resp["exception"],
       message: @response_code[resp_code],
       raw: response,
       fraud_review:
         parsed_resp["transaction"]["is_fraud"] || parsed_resp["data"]["transaction"]["is_fraud"] ||
           parsed_resp["data"]["transaction"]["is_markable_as_fraud"] ||
           parsed_resp["data"]["is_markable_as_fraud"]
     }}
  end

  defp get_headers(opts) do
    @headers ++ set_username(opts)
  end

  defp amount_params(money) do
    {currency, int_value, _} = Money.to_integer(money)
    [amount: int_value, currency: currency]
  end

  defp set_username(opts) do
    [{"Authorization", "Basic #{Base.encode64(get_config(:private_key, opts))}"}]
  end

  defp parse_response(response) do
    if is_map(response) do
      {:ok, response}
    else
      response
      |> String.replace(~r/jsonPFunction\(/, "")
      |> String.replace(~r/\)/, "")
      |> Poison.decode()
    end
  end

  defp get_token(response) do
    get_in(response, ["transaction", "identification", "uniqueId"])
  end

  defp commit(method, action, parameters, opts) do
    response =
      request_maker(method, base_url(opts) <> action, {:form, parameters}, get_headers(opts))

    matched_response = response_matcher(response)
    {atom, actual_response} = response
    response_maker(matched_response, get_status_code(actual_response), atom)
  end

  defp get_status_code(response) do
    if Map.has_key?(response, :status_code) do
      response.status_code
    else
      nil
    end
  end

  defp base_url(opts), do: opts[:config][:test_url] || @base_url

  defp get_config(key, opts) do
    get_in(opts, [:config, key])
  end
end
