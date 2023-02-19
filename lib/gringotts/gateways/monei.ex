defmodule Gringotts.Gateways.Monei do
  @moduledoc """
  [MONEI][home] gateway implementation.

  For reference see [MONEI's API (v1) documentation][docs].

  The following features of MONEI are implemented:

  | Action                       | Method        | `type` |
  | ------                       | ------        | ------ |
  | Pre-authorize                | `authorize/3` | `PA`   |
  | Capture                      | `capture/3`   | `CP`   |
  | Refund                       | `refund/3`    | `RF`   |
  | Reversal                     | `void/2`      | `RV`   |
  | Debit                        | `purchase/3`  | `DB`   |
  | Tokenization / Registrations | `store/2`     |        |

  > **What's this last column `type`?**
  >
  > That's the `paymentType` of the request, which you can ignore unless you'd
  > like to contribute to this module. Please read the [MONEI Guides][docs].

  [home]: https://monei.net
  [docs]: https://docs.monei.net

  ## The `opts` argument

  Most `Gringotts` API calls accept an optional `keyword` list `opts` to supply
  [optional arguments][extra-arg-docs] for transactions with the MONEI
  gateway. The following keys are supported:

  | Key                      | Remark                                                                                        |
  | ----                     | ---                                                                                           |
  | [`billing`][ba]          | Address of the customer, which can be used for AVS risk check.                                |
  | [`cart`][cart]           | **Not Implemented**                                                                           |
  | [`custom`][custom]       | It's a map of "name"-"value" pairs, and all of it is echoed back in the response.             |
  | [`customer`][c]          | Annotate transactions with customer info on your Monei account, and helps in risk management. |
  | [`invoice_id`][b]        | Merchant provided invoice identifier, must be unique per transaction with Monei.              |
  | [`transaction_id`][b]    | Merchant provided token for a transaction, must be unique per transaction with Monei.         |
  | [`category`][b]          | The category of the transaction.                                                              |
  | [`merchant`][m]          | Information about the merchant, which overrides the cardholder's bank statement.              |
  | [`register`][t]          | Also store payment data included in this request for future use.                              |
  | [`shipping`][sa]         | Location of recipient of goods, for logistics.                                                |
  | [`shipping_customer`][c] | Recipient details, could be different from `customer`.                                        |

  [extra-arg-docs]: https://docs.monei.net/reference/parameters
  [ba]: https://docs.monei.net/reference/parameters#billing-address
  [cart]: https://docs.monei.net/reference/parameters#cart
  [custom]: https://docs.monei.net/reference/parameters#custom-parameters
  [c]: https://docs.monei.net/reference/parameters#customer
  [b]: https://docs.monei.net/reference/parameters#basic
  [m]: https://docs.monei.net/reference/parameters#merchant
  [t]: https://docs.monei.net/reference/parameters#tokenization
  [sa]: https://docs.monei.net/reference/parameters#shipping-address

  ## Registering your MONEI account at `Gringotts`

  After [making an account on MONEI][dashboard], head to the dashboard and find
  your account "secrets" in the `Sub-Accounts > Overview` section.

  Here's how the secrets map to the required configuration parameters for MONEI:

  | Config parameter | MONEI secret   |
  | -------          | ----           |
  | `:userId`        | **User ID**    |
  | `:entityId`      | **Channel ID** |
  | `:password`      | **Password**   |

  Your Application config **must include the `:userId`, `:entityId`, `:password`
  fields** and would look something like this:

      config :gringotts, Gringotts.Gateways.Monei,
        userId: "your_secret_user_id",
        password: "your_secret_password",
        entityId: "your_secret_channel_id"

  [dashboard]: https://dashboard.monei.net/signin

  ## Scope of this module

  * _You, the merchant needs to be PCI-DSS Compliant if you wish to use this
    module. Your server will recieve sensitive card and customer information._
  * MONEI does not process money in cents, and the `amount` is rounded to 2
    decimal places.
  * Although MONEI supports payments from [various][all-card-list]
    [cards][card-acc], [banks][bank-acc] and [virtual accounts][virtual-acc]
    (like some wallets), this library only accepts payments by [(supported)
    cards][all-card-list].

  [all-card-list]: https://support.monei.net/charges-and-refunds/accepted-credit-cards-payment-methods
  [card-acc]: https://docs.monei.net/reference/parameters#card
  [bank-acc]: https://docs.monei.net/reference/parameters#bank-account
  [virtual-acc]: https://docs.monei.net/reference/parameters#virtual-account

  ## Supported countries

  MONEI supports the countries listed [here][all-country-list]

  ## Supported currencies

  MONEI supports the currecncies [listed here][all-currency-list], and ***this
  module*** supports a subset of those:

      :AED, :AFN, :ANG, :AOA, :AWG, :AZN, :BAM, :BGN, :BRL, :BYN, :CDF, :CHF, :CUC,
      :EGP, :EUR, :GBP, :GEL, :GHS, :MDL, :MGA, :MKD, :MWK, :MZN, :NAD, :NGN, :NIO,
      :NOK, :NPR, :NZD, :PAB, :PEN, :PGK, :PHP, :PKR, :PLN, :PYG, :QAR, :RSD, :RUB,
      :RWF, :SAR, :SCR, :SDG, :SEK, :SGD, :SHP, :SLL, :SOS, :SRD, :STD, :SYP, :SZL,
      :THB, :TJS, :TOP, :TRY, :TTD, :TWD, :TZS, :UAH, :UGX, :USD, :UYU, :UZS, :VND,
      :VUV, :WST, :XAF, :XCD, :XOF, :XPF, :YER, :ZAR, :ZMW, :ZWL

  > Please [raise an issue][new-issue] if you'd like us to add support for more
  > currencies

  [all-currency-list]: https://support.monei.net/international/currencies-supported-by-monei
  [new-issue]: https://github.com/aviabird/gringotts/issues
  [all-country-list]: https://support.monei.net/international/what-countries-does-monei-support

  ## Following the examples

  1. First, set up a sample application and configure it to work with MONEI.
      - You could do that from scratch by following our [Getting Started](#) guide.
      - To save you time, we recommend [cloning our example repo][example-repo]
        that gives you a pre-configured sample app ready-to-go.
        + You could use the same config or update it the with your "secrets"
          that you see in `Dashboard > Sub-accounts` as described
          [above](#module-registering-your-monei-account-at-gringotts).

  2. To save a lot of time, create a [`.iex.exs`][iex-docs] file as shown in
     [this gist][monei.iex.exs] to introduce a set of handy bindings and
     aliases.

  We'll be using these bindings in the examples below.

  [example-repo]: https://github.com/aviabird/gringotts_example
  [iex-docs]: https://hexdocs.pm/iex/IEx.html#module-the-iex-exs-file
  [monei.iex.exs]: https://gist.github.com/oyeb/a2e2ac5986cc90a12a6136f6bf1357e5

  ## TODO

  * [Backoffice operations](https://docs.monei.net/tutorials/manage-payments/backoffice)
    - Credit
    - Rebill
  * [Recurring payments](https://docs.monei.net/recurring)
  * [Reporting](https://docs.monei.net/tutorials/reporting)
  """

  use Gringotts.Gateways.Base
  use Gringotts.Adapter, required_config: [:userId, :entityId, :password]
  alias Gringotts.{CreditCard, Money, Response}

  @base_url "https://test.monei-api.net"
  @default_headers ["Content-Type": "application/x-www-form-urlencoded", charset: "UTF-8"]

  @supported_currencies ~w(AED AFN ANG AOA AWG AZN BAM BGN BRL BYN CDF CHF CUC
    EGP EUR GBP GEL GHS MDL MGA MKD MWK MZN NAD NGN NIO NOK NPR NZD PAB PEN PGK
    PHP PKR PLN PYG QAR RSD RUB RWF SAR SCR SDG SEK SGD SHP SLL SOS SRD STD SYP
    SZL THB TJS TOP TRY TTD TWD TZS UAH UGX USD UYU UZS VND VUV WST XAF XCD XOF
    XPF YER ZAR ZMW ZWL)

  @version "v1"

  @cvc_code_translator %{
    "M" => "pass",
    "N" => "fail",
    "P" => "not_processed",
    "U" => "issuer_unable",
    "S" => "issuer_unable"
  }

  @avs_code_translator %{
    "F" => {"pass", "pass"},
    "A" => {"pass", "fail"},
    "Z" => {"fail", "pass"},
    "N" => {"fail", "fail"},
    "U" => {"error", "error"},
    nil => {nil, nil}
  }

  # MONEI supports payment by card, bank account and even something obscure:
  # virtual account opts has the auth keys.

  @doc """
  Performs a (pre) Authorize operation.

  The authorization validates the `card` details with the banking network,
  places a hold on the transaction `amount` in the customer’s issuing bank and
  also triggers risk management. Funds are not transferred.

  MONEI returns an ID string which can be used to:

  * `capture/3` _an_ amount.
  * `void/2` a pre-authorization.

  ## Note

  * The `:register` option when set to `true` will store this card for future
    use, and you will recieve a registration `token` in the `:token` field of
    the `Response` struct.
  * A stand-alone pre-authorization [expires in
    72hrs](https://docs.monei.net/tutorials/manage-payments/backoffice).

  ## Example

  The following example shows how one would (pre) authorize a payment of $42 on
  a sample `card`.

      iex> amount = Money.new(42, :USD)
      iex> card = %Gringotts.CreditCard{first_name: "Harry", last_name: "Potter", number: "4200000000000000", year: 2099, month: 12, verification_code:  "123", brand: "VISA"}
      iex> {:ok, auth_result} = Gringotts.authorize(Gringotts.Gateways.Monei, amount, card, opts)
      iex> auth_result.id # This is the authorization ID
      iex> auth_result.token # This is the registration ID/token
  """
  @spec authorize(Money.t(), CreditCard.t(), keyword) :: {:ok | :error, Response.t()}
  def authorize(amount, %CreditCard{} = card, opts) do
    {currency, value} = Money.to_string(amount)

    params =
      [
        paymentType: "PA",
        amount: value
      ] ++ card_params(card)

    commit(:post, "payments", params, [{:currency, currency} | opts])
  end

  @doc """
  Captures a pre-authorized `amount`.

  `amount` is transferred to the merchant account by MONEI when it is smaller or
  equal to the amount used in the pre-authorization referenced by `payment_id`.

  ## Note

  MONEI allows partial captures and unlike many other gateways, does not release
  the remaining amount back to the payment source. Thus, the same
  pre-authorisation ID can be used to perform multiple captures, till:
  * all the pre-authorized amount is captured or,
  * the remaining amount is explicitly "reversed" via `void/2`. **[citation-needed]**

  ## Example

  The following example shows how one would (partially) capture a previously
  authorized a payment worth $35 by referencing the obtained authorization `id`.

      iex> amount = Money.new(35, :USD)
      iex> {:ok, capture_result} = Gringotts.capture(Gringotts.Gateways.Monei, amount, auth_result.id, opts)
  """
  @spec capture(String.t(), Money.t(), keyword) :: {:ok | :error, Response.t()}
  def capture(payment_id, amount, opts)

  def capture(<<payment_id::bytes-size(32)>>, amount, opts) do
    {currency, value} = Money.to_string(amount)

    params = [
      paymentType: "CP",
      amount: value
    ]

    commit(:post, "payments/#{payment_id}", params, [{:currency, currency} | opts])
  end

  @doc """
  Transfers `amount` from the customer to the merchant.

  MONEI attempts to process a purchase on behalf of the customer, by debiting
  `amount` from the customer's account by charging the customer's `card`.

  ## Note

  * The `:register` option when set to `true` will store this card for future
    use, and you will recieve a registration `token` in the `:token` field of
    the `Response` struct.

  ## Example

  The following example shows how one would process a payment worth $42 in
  one-shot, without (pre) authorization.

      iex> amount = Money.new(42, :USD)
      iex> card = %Gringotts.CreditCard{first_name: "Harry", last_name: "Potter", number: "4200000000000000", year: 2099, month: 12, verification_code:  "123", brand: "VISA"}
      iex> {:ok, purchase_result} = Gringotts.purchase(Gringotts.Gateways.Monei, amount, card, opts)
      iex> purchase_result.token # This is the registration ID/token
  """
  @spec purchase(Money.t(), CreditCard.t(), keyword) :: {:ok | :error, Response.t()}
  def purchase(amount, %CreditCard{} = card, opts) do
    {currency, value} = Money.to_string(amount)

    params =
      [
        paymentType: "DB",
        amount: value
      ] ++ card_params(card)

    commit(:post, "payments", params, [{:currency, currency} | opts])
  end

  @doc """
  Refunds the `amount` to the customer's account with reference to a prior transfer.

  MONEI processes a full or partial refund worth `amount`, referencing a
  previous `purchase/3` or `capture/3`.

  The end customer will always see two bookings/records on his statement.
  Refer MONEI's [Backoffice
  Operations](https://docs.monei.net/tutorials/manage-payments/backoffice)
  guide.

  ## Example

  The following example shows how one would (completely) refund a previous
  purchase (and similarily for captures).

      iex> amount = Money.new(42, :USD)
      iex> {:ok, refund_result} = Gringotts.refund(Gringotts.Gateways.Monei, purchase_result.id, amount)
  """
  @spec refund(Money.t(), String.t(), keyword) :: {:ok | :error, Response.t()}
  def refund(amount, <<payment_id::bytes-size(32)>>, opts) do
    {currency, value} = Money.to_string(amount)

    params = [
      paymentType: "RF",
      amount: value
    ]

    commit(:post, "payments/#{payment_id}", params, [{:currency, currency} | opts])
  end

  @doc """
  Stores the payment-source data for later use.

  MONEI can store the payment-source details, for example card or bank details
  which can be used to effectively process _One-Click_ and _Recurring_ payments,
  and return a registration token for reference.

  The registration token is available in the `Response.id` field.

  It is recommended to associate these details with a "Customer" by passing
  customer details in the `opts`.

  ## Note

  * _One-Click_ and _Recurring_ payments are currently not implemented.
  * Payment details can be saved during a `purchase/3` or `capture/3`.

  ## Example

  The following example shows how one would store a card (a payment-source) for
  future use.

      iex> card = %Gringotts.CreditCard{first_name: "Harry", last_name: "Potter", number: "4200000000000000", year: 2099, month: 12, verification_code:  "123", brand: "VISA"}
      iex> {:ok, store_result} = Gringotts.store(Gringotts.Gateways.Monei, card)
      iex> store_result.id # This is the registration token
  """
  @spec store(CreditCard.t(), keyword) :: {:ok | :error, Response.t()}
  def store(%CreditCard{} = card, opts) do
    params = card_params(card)
    commit(:post, "registrations", params, opts)
  end

  @doc """
  WIP

  **MONEI unstore does not seem to work. MONEI always returns a `403`**

  Deletes previously stored payment-source data.
  """
  @spec unstore(String.t(), keyword) :: {:ok | :error, Response.t()}
  def unstore(registration_id, opts)

  def unstore(<<registration_id::bytes-size(32)>>, opts) do
    commit(:delete, "registrations/#{registration_id}", [], opts)
  end

  @doc """
  Voids the referenced payment.

  This method attempts a reversal of the either a previous `purchase/3`,
  `capture/3` or `authorize/3` referenced by `payment_id`.

  As a consequence, the customer will never see any booking on his
  statement. Refer MONEI's [Backoffice
  Operations](https://docs.monei.net/tutorials/manage-payments/backoffice)
  guide.

  ## Voiding a previous authorization

  MONEI will reverse the authorization by sending a "reversal request" to the
  payment source (card issuer) to clear the funds held against the
  authorization. If some of the authorized amount was captured, only the
  remaining amount is cleared. **[citation-needed]**

  ## Voiding a previous purchase

  MONEI will reverse the payment, by sending all the amount back to the
  customer. Note that this is not the same as `refund/3`.

  ## Example

  The following example shows how one would void a previous (pre)
  authorization. Remember that our `capture/3` example only did a partial
  capture.

      iex> {:ok, void_result} = Gringotts.void(Gringotts.Gateways.Monei, auth_result.id, opts)
  """
  @spec void(String.t(), keyword) :: {:ok | :error, Response.t()}
  def void(payment_id, opts)

  def void(<<payment_id::bytes-size(32)>>, opts) do
    params = [paymentType: "RV"]
    commit(:post, "payments/#{payment_id}", params, opts)
  end

  defp card_params(card) do
    [
      "card.number": card.number,
      "card.holder": CreditCard.full_name(card),
      "card.expiryMonth": card.month |> Integer.to_string() |> String.pad_leading(2, "0"),
      "card.expiryYear": card.year |> Integer.to_string(),
      "card.cvv": card.verification_code,
      paymentBrand: card.brand
    ]
  end

  defp auth_params(opts) do
    [
      "authentication.userId": opts[:config][:userId],
      "authentication.password": opts[:config][:password],
      "authentication.entityId": opts[:config][:entityId]
    ]
  end

  # Makes the request to MONEI's network.
  @spec commit(atom, String.t(), keyword, keyword) :: {:ok | :error, Response.t()}
  defp commit(:post, endpoint, params, opts) do
    url = "#{base_url(opts)}/#{version(opts)}/#{endpoint}"

    case expand_params(Keyword.delete(opts, :config), params[:paymentType]) do
      {:error, reason} ->
        {:error, Response.error(reason: reason)}

      validated_params ->
        url
        |> HTTPoison.post(
          {:form, params ++ validated_params ++ auth_params(opts)},
          @default_headers
        )
        |> respond
    end
  end

  # This clause is only used by `unstore/2`
  defp commit(:delete, endpoint, _params, opts) do
    base_url = "#{base_url(opts)}/#{version(opts)}/#{endpoint}"
    auth_params = auth_params(opts)
    query_string = auth_params |> URI.encode_query()

    (base_url <> "?" <> query_string)
    |> HTTPoison.delete()
    |> respond
  end

  # Parses MONEI's response and returns a `Gringotts.Response` struct in a
  # `:ok`, `:error` tuple.
  @spec respond(term) :: {:ok | :error, Response.t()}
  defp respond(monei_response)

  defp respond({:ok, %{status_code: 200, body: body}}) do
    common = [raw: body, status_code: 200]

    with {:ok, decoded_json} <- Jason.decode(body),
         {:ok, results} <- parse_response(decoded_json) do
      {:ok, Response.success(common ++ results)}
    else
      {:not_ok, errors} ->
        {:ok, Response.error(common ++ errors)}

      {:error, _} ->
        {:error, Response.error([reason: "undefined response from monei"] ++ common)}
    end
  end

  defp respond({:ok, %{status_code: status_code, body: body}}) do
    {:error, Response.error(status_code: status_code, raw: body)}
  end

  defp respond({:error, %HTTPoison.Error{} = error}) do
    {
      :error,
      Response.error(
        reason: "network related failure",
        message: "HTTPoison says '#{error.reason}' [ID: #{error.id || "nil"}]"
      )
    }
  end

  defp parse_response(%{"result" => result} = data) do
    {address, zip_code} = @avs_code_translator[result["avsResponse"]]

    results = [
      id: data["id"],
      token: data["registrationId"],
      gateway_code: result["code"],
      message: result["description"],
      fraud_review: data["risk"],
      cvc_result: @cvc_code_translator[result["cvvResponse"]],
      avs_result: %{address: address, zip_code: zip_code}
    ]

    non_nil_params = Enum.filter(results, fn {_, v} -> v != nil end)
    verify(non_nil_params)
  end

  defp verify(results) do
    if String.match?(results[:gateway_code], ~r{^(000\.000\.|000\.100\.1|000\.[36])}) do
      {:ok, results}
    else
      {:not_ok, [{:reason, results[:message]} | results]}
    end
  end

  defp expand_params(params, action_type) do
    Enum.reduce_while(params, [], fn {k, v}, acc ->
      case k do
        :currency ->
          if valid_currency?(v),
            do: {:cont, [{:currency, v} | acc]},
            else: {:halt, {:error, "Invalid currency"}}

        :customer ->
          {:cont, acc ++ make(action_type, "customer", v)}

        :merchant ->
          {:cont, acc ++ make(action_type, "merchant", v)}

        :billing ->
          {:cont, acc ++ make(action_type, "billing", v)}

        :shipping ->
          {:cont, acc ++ make(action_type, "shipping", v)}

        :invoice_id ->
          {:cont, [{"merchantInvoiceId", v} | acc]}

        :transaction_id ->
          {:cont, [{"merchantTransactionId", v} | acc]}

        :category ->
          {:cont, [{"transactionCategory", v} | acc]}

        :shipping_customer ->
          {:cont, acc ++ make(action_type, "shipping.customer", v)}

        :custom ->
          {:cont, acc ++ make_custom(v)}

        :register ->
          {:cont, acc ++ make(action_type, :register, v)}

        unsupported ->
          {:halt, {:error, "Unsupported optional param '#{unsupported}'"}}
      end
    end)
  end

  defp valid_currency?(currency) do
    currency in @supported_currencies
  end

  defp make(action_type, _prefix, _param) when action_type in ["CP", "RF", "RV"], do: []

  defp make(action_type, prefix, param) do
    case prefix do
      :register ->
        if action_type in ["PA", "DB"], do: [createRegistration: true], else: []

      _ ->
        Enum.into(param, [], fn {k, v} -> {"#{prefix}.#{k}", v} end)
    end
  end

  defp make_custom(custom_map) do
    Enum.into(custom_map, [], fn {k, v} -> {"customParameters[#{k}]", "#{v}"} end)
  end

  defp base_url(opts), do: opts[:config][:test_url] || @base_url
  defp version(opts), do: opts[:config][:api_version] || @version
end
