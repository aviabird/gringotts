defmodule Gringotts.Gateways.Monei do
  @moduledoc """
  [MONEI](https://www.monei.net) gateway implementation.

  For reference see [MONEI's API (v1) documentation](https://docs.monei.net).

  The following features of MONEI are implemented:

  | Action                       | Method        | `type` |
  | ------                       | ------        | ------ |
  | Pre-authorize                | `authorize/3` | `PA`   |
  | Capture                      | `capture/3`   | `CP`   |
  | Refund                       | `refund/3`    | `RF`   |
  | Reversal                     | `void/2`      | `RV`   |
  | Debit                        | `purchase/3`  | `DB`   |
  | Tokenization / Registrations | `store/2`     |        |

  > **What's this last column `type`?**\
  > That's the `paymentType` of the request, which you can ignore unless you'd
  > like to contribute to this module. Please read the [MONEI
  > Guides](https://docs.monei.net).

  ## The `opts` argument

  Most `Gringotts` API calls accept an optional `Keyword` list `opts` to supply
  [optional arguments](https://docs.monei.net/reference/parameters) for
  transactions with the MONEI gateway. The following keys are supported:

  | Key                 | Remark                                                                                        | Status          |
  | ----                | ---                                                                                           | ----            |
  | `billing`           | Address of the customer, which can be used for AVS risk check                                 | **Implemented** |
  | `cart`              |                                                                                               | Not implemented |
  | `custom`            | It's a map of "name"-"value" pairs, and all of it is echoed back in the response              | **Implemented** |
  | `customer`          | Annotate transactions with customer info on your Monei account, and helps in risk management. | **Implemented** |
  | `invoice_id`        | Merchant provided invoice identifier, must be unique per transaction with Monei               | **Implemented** |
  | `transaction_id`    | Merchant provided token for a transaction, must be unique per transaction with Monei          | **Implemented** |
  | `category`          | The category of the transaction                                                               | **Implemented** |
  | `merchant`          | Information about the merchant, which overrides the cardholder's bank statement               | **Implemented** |
  | `register`          | Also store payment data included in this request for future use.                              | **Implemented** |
  | `shipping`          | Location of recipient of goods, for logistics                                                 | **Implemented** |
  | `shipping_customer` | Recipient details, could be different from `customer`                                         | **Implemented** |

  > All these keys are being implemented, track progress in
  > [issue #36](https://github.com/aviabird/gringotts/issues/36)!

  ## Registering your MONEI account at `Gringotts`

  After [making an account on MONEI](https://dashboard.monei.net/signin), head
  to the dashboard and find your account "secrets" in the `Sub-Accounts >
  Overview` section.

  Here's how the secrets map to the required configuration parameters for MONEI:

  | Config parameter | MONEI secret   |
  | -------          | ----           |
  | `:userId`        | **User ID**    |
  | `:entityId`      | **Channel ID** |
  | `:password`      | **Password**   |

  Your Application config **must include the `:userId`, `:entityId`, `:password`
  fields** and would look something like this:

      config :gringotts, Gringotts.Gateways.Monei,
        adapter: Gringotts.Gateways.Monei,
        userId: "your_secret_user_id",
        password: "your_secret_password",
        entityId: "your_secret_channel_id"


  ## Scope of this module, and _quirks_

  * MONEI does not process money in cents, and the `amount` is rounded to 2
    decimal places.
  * Although MONEI supports payments from [various
  cards](https://support.monei.net/charges-and-refunds/accepted-credit-cards-payment-methods),
  banks and virtual accounts (like some wallets), this library only accepts
  payments by (supported) cards.

  ## Supported currencies and countries

  The following currencies are supported: `EUR`, `USD`, `GBP`, `NAD`, `TWD`,
  `VUV`, `NZD`, `NGN`, `NIO`, `NGN`, `NOK`, `PKR`, `PAB`, `PGK`, `PYG`, `PEN`,
  `NPR`, `ANG`, `AWG`, `PHP`, `QAR`, `RUB`, `RWF`, `SHP`, `STD`, `SAR`, `SCR`,
  `SLL`, `SGD`, `VND`, `SOS`, `ZAR`, `ZWL`, `YER`, `SDG`, `SZL`, `SEK`, `CHF`,
  `SYP`, `TJS`, `THB`, `TOP`, `TTD`, `AED`, `TND`, `TRY`, `AZN`, `UGX`, `MKD`,
  `EGP`, `GBP`, `TZS`, `UYU`, `UZS`, `WST`, `YER`, `RSD`, `ZMW`, `TWD`, `AZN`,
  `GHS`, `RSD`, `MZN`, `AZN`, `MDL`, `TRY`, `XAF`, `XCD`, `XOF`, `XPF`, `MWK`,
  `SRD`, `MGA`, `AFN`, `TJS`, `AOA`, `BYN`, `BGN`, `CDF`, `BAM`, `UAH`, `GEL`,
  `PLN`, `BRL` and `CUC`.

  > [Here](https://support.monei.net/international/currencies-supported-by-monei)
  > is the up-to-date currency list. _Please [raise an
  > issue](https://github.com/aviabird/gringotts/issues) if the list above has
  > become out-of-date!_

  MONEI supports the countries listed
  [here](https://support.monei.net/international/what-countries-does-monei-support).

  ## Following the examples

  1. First, set up a sample application and configure it to work with MONEI.
      - You could do that from scratch by following our [Getting Started](#) guide.
      - To save you time, we recommend [cloning our example
  repo](https://github.com/aviabird/gringotts_example) that gives you a
  pre-configured sample app ready-to-go.
          + You could use the same config or update it the with your "secrets"
          that you see in `Dashboard > Sub-accounts` as described
          [above](#module-registering-your-monei-account-at-gringotts).

  2. Run an `iex` session with `iex -S mix` and add some variable bindings and
  aliases to it (to save some time):
  ```
  iex> alias Gringotts.{Response, CreditCard, Gateways.Monei}
  iex> amount = %{value: Decimal.new(42), currency: "EUR"}
  iex> card = %CreditCard{first_name: "Harry",
                          last_name: "Potter",
                          number: "4200000000000000",
                          year: 2099, month: 12,
                          verification_code: "123",
                          brand: "VISA"}
  iex> customer = %{"givenName": "Harry",
                    "surname": "Potter",
                    "merchantCustomerId": "the_boy_who_lived",
                    "sex": "M", 
                    "birthDate": "1980-07-31", 
                    "mobile": "+15252525252", 
                    "email": "masterofdeath@ministryofmagic.go v",
                    "ip": "1.1.1", 
                    "status": "NEW"} 
  iex> merchant = %{"name": "Ollivanders",
                    "city": "South Side",
                    "street": "Diagon Alley",
                    "state": "London",
                    "country": "GB",
                    "submerchantId": "Makers of Fine Wands since 382 B.C."}
  iex> billing = %{"street1": "301, Gryffindor",
                   "street2": "Hogwarts School of Witchcraft and Wizardry, Hogwarts Castle",
                   "city": "Highlands",
                   "state": "Scotland",
                   "country": "GB"}
  iex> shipping = %{"street1": "301, Gryffindor",
                    "street2": "Hogwarts School of Witchcraft and Wizardry, Hogwarts Castle",
                    "city": "Highlands",
                    "state": "Scotland",
                    "country": "GB",
                    "method": "SAME_DAY_SERVICE",
                    "comment": "For our valued customer, Mr. Potter"}
  iex> opts = [customer: customer,
               merchant: merchant,
               billing: billing,
               shipping: shipping,
               category: "EC",
               custom: %{"voldemort": "he who must not be named"},
               register: true]
  ```

  We'll be using these in the examples below.

  ## TODO

  * [Backoffice operations](https://docs.monei.net/tutorials/manage-payments/backoffice)
    - Credit
    - Rebill
  * [Recurring payments](https://docs.monei.net/recurring)
  * [Reporting](https://docs.monei.net/tutorials/reporting)
  """

  use Gringotts.Gateways.Base
  use Gringotts.Adapter, required_config: [:userId, :entityId, :password]
  import Poison, only: [decode: 1]
  alias Gringotts.{CreditCard, Response, Money}

  @base_url "https://test.monei-api.net"
  @default_headers ["Content-Type": "application/x-www-form-urlencoded", charset: "UTF-8"]

  @supported_currencies [
    "EUR", "USD", "GBP", "NAD", "TWD", "VUV", "NZD", "NGN", "NIO", "NGN", "NOK",
    "PKR", "PAB", "PGK", "PYG", "PEN", "NPR", "ANG", "AWG", "PHP", "QAR", "RUB",
    "RWF", "SHP", "STD", "SAR", "SCR", "SLL", "SGD", "VND", "SOS", "ZAR", "ZWL",
    "YER", "SDG", "SZL", "SEK", "CHF", "SYP", "TJS", "THB", "TOP", "TTD", "AED",
    "TND", "TRY", "AZN", "UGX", "MKD", "EGP", "GBP", "TZS", "UYU", "UZS", "WST",
    "YER", "RSD", "ZMW", "TWD", "AZN", "GHS", "RSD", "MZN", "AZN", "MDL", "TRY",
    "XAF", "XCD", "XOF", "XPF", "MWK", "SRD", "MGA", "AFN", "TJS", "AOA", "BYN",
    "BGN", "CDF", "BAM", "UAH", "GEL", "PLN", "BRL", "CUC"
  ]

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
  use, and you will recieve a registration `token` in the `Response` struct.
  * A stand-alone pre-authorization [expires in
  72hrs](https://docs.monei.net/tutorials/manage-payments/backoffice).

  ## Example

  The following session shows how one would (pre) authorize a payment of $40 on
  a sample `card`.

      iex> amount = %{value: Decimal.new(42), currency: "EUR"}
      iex> card = %Gringotts.CreditCard{first_name: "Harry", last_name: "Potter", number: "4200000000000000", year: 2099, month: 12, verification_code:  "123", brand: "VISA"}
      iex> auth_result = Gringotts.authorize(Gringotts.Gateways.Monei, amount, card, opts)
      iex> auth_result.id # This is the authorization ID
  """
  @spec authorize(Money.t(), CreditCard.t(), keyword) :: {:ok | :error, Response}
  def authorize(amount, card = %CreditCard{}, opts) do
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

  The following session shows how one would (partially) capture a previously
  authorized a payment worth $35 by referencing the obtained authorization `id`.

      iex> amount = %{value: Decimal.new(42), currency: "EUR"}
      iex> card = %Gringotts.CreditCard{first_name: "Harry", last_name: "Potter", number: "4200000000000000", year: 2099, month: 12, verification_code:  "123", brand: "VISA"}
      iex> capture_result = Gringotts.capture(Gringotts.Gateways.Monei, 35, auth_result.id, opts)
  """
  @spec capture(Money.t(), String.t(), keyword) :: {:ok | :error, Response}
  def capture(amount, payment_id, opts)

  def capture(amount, <<payment_id::bytes-size(32)>>, opts) do
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
  use, and you will recieve a registration `token` in the `Response` struct.
  
  ## Example

  The following session shows how one would process a payment in one-shot,
  without (pre) authorization.

      iex> amount = %{value: Decimal.new(42), currency: "EUR"}
      iex> card = %Gringotts.CreditCard{first_name: "Harry", last_name: "Potter", number: "4200000000000000", year: 2099, month: 12, verification_code:  "123", brand: "VISA"}
      iex> purchase_result = Gringotts.purchase(Gringotts.Gateways.Monei, amount, card, opts)
  """
  @spec purchase(Money.t(), CreditCard.t(), keyword) :: {:ok | :error, Response}
  def purchase(amount, card = %CreditCard{}, opts) do
    {currency, value} = Money.to_string(amount)

    params =
      [
        paymentType: "DB",
        amount: value
      ] ++ card_params(card)
    commit(:post, "payments", params, [{:currency, currency} | opts])
  end

  @doc """
  Voids the referenced payment.

  This method attempts a reversal of the either a previous `purchase/3` or
  `authorize/3` referenced by `payment_id`.

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

  The following session shows how one would void a previous (pre)
  authorization. Remember that our `capture/3` example only did a partial
  capture.

      iex> card = %Gringotts.CreditCard{first_name: "Harry", last_name: "Potter", number: "4200000000000000", year: 2099, month: 12, verification_code:  "123", brand: "VISA"}
      iex> void_result = Gringotts.void(Gringotts.Gateways.Monei, auth_result.id, opts)
  """
  @spec void(String.t(), keyword) :: {:ok | :error, Response}
  def void(payment_id, opts)

  def void(<<payment_id::bytes-size(32)>>, opts) do
    params = [paymentType: "RV"]
    commit(:post, "payments/#{payment_id}", params, opts)
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

  The following session shows how one would refund a previous purchase (and
  similarily for captures).

      iex> amount = %{value: Decimal.new(42), currency: "EUR"}
      iex> card = %Gringotts.CreditCard{first_name: "Harry", last_name: "Potter", number: "4200000000000000", year: 2099, month: 12, verification_code:  "123", brand: "VISA"}
      iex> refund_result = Gringotts.refund(Gringotts.Gateways.Monei, purchase_result.id, amount)
  """
  @spec refund(Money.t(), String.t(), keyword) :: {:ok | :error, Response}
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

  It is recommended to associate these details with a "Customer" by passing
  customer details in the `opts`.

  ## Note

  * _One-Click_ and _Recurring_ payments are currently not implemented.
  * Payment details can be saved during a `purchase/3` or `capture/3`.

  ## Example

  The following session shows how one would store a card (a payment-source) for
  future use.

      iex> card = %Gringotts.CreditCard{first_name: "Harry", last_name: "Potter", number: "4200000000000000", year: 2099, month: 12, verification_code:  "123", brand: "VISA"}
      iex> store_result = Gringotts.store(Gringotts.Gateways.Monei, card, [])
  """
  @spec store(CreditCard.t(), keyword) :: {:ok | :error, Response}
  def store(%CreditCard{} = card, opts) do
    params = card_params(card)
    commit(:post, "registrations", params, opts)
  end

  @doc """
  WIP

  **MONEI unstore does not seem to work. MONEI always returns a `403`**

  Deletes previously stored payment-source data.
  """
  @spec unstore(String.t(), keyword) :: {:ok | :error, Response}
  def unstore(<<registrationId::bytes-size(32)>>, opts) do
    commit(:delete, "registrations/#{registrationId}", [], opts)
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

  # Makes the request to MONEI's network.
  @spec commit(atom, String.t(), keyword, keyword) :: {:ok | :error, Response}
  defp commit(method, endpoint, params, opts) do
    auth_params = [
      "authentication.userId": opts[:config][:userId],
      "authentication.password": opts[:config][:password],
      "authentication.entityId": opts[:config][:entityId]
    ]

    url = "#{base_url(opts)}/#{version(opts)}/#{endpoint}"

    case expand_params(opts, params[:paymentType]) do
      {:error, reason} ->
        {:error, Response.error(description: reason)}

      validated_params ->
        network_response =
          case method do
            :post ->
              HTTPoison.post(
                url,
                {:form, params ++ validated_params ++ auth_params},
                @default_headers
              )

            :delete ->
              HTTPoison.delete(url <> "?" <> URI.encode_query(auth_params))
          end

        respond(network_response)
    end
  end

  # Parses MONEI's response and returns a `Gringotts.Response` struct in a
  # `:ok`, `:error` tuple.
  @spec respond(term) :: {:ok | :error, Response}
  defp respond(monei_response)

  defp respond({:ok, %{status_code: 200, body: body}}) do
    case decode(body) do
      {:ok, decoded_json} ->
        case verification_result(decoded_json) do
          {:ok, results} -> {:ok, Response.success([{:id, decoded_json["id"]} | results])}
          {:error, errors} -> {:ok, Response.error([{:id, decoded_json["id"]} | errors])}
        end

      {:error, _} ->
        {:error, Response.error(raw: body, code: :undefined_response_from_monei)}
    end
  end

  defp respond({:ok, %{status_code: status_code, body: body}}) do
    {:error, Response.error(code: status_code, raw: body)}
  end

  defp respond({:error, %HTTPoison.Error{} = error}) do
    {
      :error,
      Response.error(
        code: error.id,
        reason: "network related failure",
        description: "HTTPoison says '#{error.reason}'"
      )
    }
  end

  defp expand_params(params, action_type) do
    Enum.reduce_while(params, [], fn {k, v}, acc ->
      case k do
        :currency ->
          if valid_currency?(v),
            do: {:cont, [{:currency, v} | acc]},
            else: {:halt, {:error, "Invalid currency"}}

        :customer ->
          {:cont, acc ++ make("customer", v)}

        :merchant ->
          {:cont, acc ++ make("merchant", v)}

        :billing ->
          {:cont, acc ++ make("billing", v)}

        :shipping ->
          {:cont, acc ++ make("shipping", v)}

        :invoice_id ->
          {:cont, [{"merchantInvoiceId", v} | acc]}

        :transaction_id ->
          {:cont, [{"merchantTransactionId", v} | acc]}

        :category ->
          {:cont, [{"transactionCategory", v} | acc]}

        :shipping_customer ->
          {:cont, acc ++ make("shipping.customer", v)}

        :custom ->
          {:cont, acc ++ make_custom(v)}

        :register ->
          {
            :cont,
            if action_type in ["PA", "DB"] do
              [{"createRegistration", true} | acc]
            else
              acc
            end
          }
          
        _ ->
          {:cont, acc}
      end
    end)
  end

  defp valid_currency?(currency) do
    currency in @supported_currencies
  end

  defp verification_result(%{"result" => result} = data) do
    {address, zip_code} = @avs_code_translator[result["avsResponse"]]
    code = result["code"]
    token = data["registrationId"]
    common = [
      code: code,
      description: result["description"],
      risk: data["risk"]["score"],
      cvc_result: @cvc_code_translator[result["cvvResponse"]],
      avs_result: [address: address, zip_code: zip_code],
      raw: data
    ]

    results = if token != nil, do: common ++ [token: token], else: common
    if String.match?(code, ~r{^(000\.000\.|000\.100\.1|000\.[36])}) do
      {:ok, results}
    else
      {:error, [{:reason, result["description"]} | results]}
    end
  end

  defp make(prefix, param) do
    Enum.into(param, [], fn {k, v} -> {"#{prefix}.#{k}", v} end)
  end

  defp make_custom(custom_map) do
    Enum.into(custom_map, [], fn {k, v} -> {"customParameters[#{k}]", "#{v}"} end)
  end

  defp base_url(opts), do: opts[:config][:test_url] || @base_url
  defp version(opts), do: opts[:config][:api_version] || @version
end
