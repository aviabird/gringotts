defmodule Gringotts.Gateways.Adyen do
  @moduledoc """
  [ADYEN][home] gateway implementation.

  For refernce see [ADYEN's API documentation][docs].

  The following features of ADYEN are implemented:

  | Action                       | Method        |
  | ------                       | ------        |
  | Authorise                    | `authorize/3` |
  | Purchase                     | `purchase/3`  |
  | Capture                      | `capture/3`   |
  | Refund                       | `refund/3`    |
  | Cancel                       | `void/2`      |

  ## The `opts` argument

  Most `Gringotts` API calls accept an optional `keyword` list `opts` to supply
  [optional arguments][extra-arg-docs] for transactions with the ADYEN
  gateway. The following keys are supported:

  | Key                             | Remark                                                                                                                                                                                                                                                                                                                                           |
  | ----                            | ---                                                                                                                                                                                                                                                                                                                                              |
  | `billingAddress`                | The address where to send the invoice.                                                                                                                                                                                                                                                                                                           |
  | `browserInfo`                   | The shopper's browser information.                                                                                                                                                                                                                                                                                                               |
  | `captureDelayHours`             | The delay between the authorisation and scheduled auto-capture, specified in hours.                                                                                                                                                                                                                                                              |
  | `dateOfBirth`                   | The shopper's date of birth. Format ISO-8601: YYYY-MM-DD                                                                                                                                                                                                                                                                                         |
  | `deliveryAddress`               | The address where the purchased goods should be delivered.                                                                                                                                                                                                                                                                                       |
  | `deliveryDate`                  | The date and time the purchased goods should be delivered. Format ISO 8601: YYYY-MM-DDThh:mm:ss.sssTZD, Example: 2017-07-17T13:42:40.428+01:00                                                                                                                                                                                                   |
  | `entityType`                    | The type of the entity the payment is processed for.                                                                                                                                                                                                                                                                                             |
  | `fraudOffset`                   | An integer value that is added to the normal fraud score. The value can be either positive or negative.                                                                                                                                                                                                                                          |
  | `mcc`                           | The merchant category code (MCC) is a four-digit number, which relates to a particular market segment. This code reflects the predominant activity that is conducted by the merchant.                                                                                                                                                            |
  | `merchantAccount`               | The merchant account identifier, with which you want to process the transaction.                                                                                                                                                                                                                                                                 |
  | `nationality`                   | The two-character country code of the shopper's nationality.                                                                                                                                                                                                                                                                                     |
  | `orderReference`                | The order reference to link multiple partial payments.                                                                                                                                                                                                                                                                                           |
  | `reference`                     | The reference to uniquely identify a payment. This reference is used in all communication with you about the payment status. We recommend using a unique value per payment; however, it is not a requirement. If you need to provide multiple references for a transaction, separate them with hyphens ("-"). Maximum length: 80 characters.     |
  | `selectedBrand`                 | Some payment methods require defining a value for this field to specify how to process the transaction.                                                                                                                                                                                                                                          |
  | `sessionId`                     | A session ID used to identify a payment session.                                                                                                                                                                                                                                                                                                 |                   
  | `shopperEmail`                  | The shopper's email address. We recommend that you provide this data, as it is used in velocity fraud checks.                                                                                                                                                                                                                                    |                     
  | `shopperIP`                     | The shopper's IP address. We recommend that you provide this data, as it is used in a number of risk checks (for instance, number of payment attempts or location-based checks).                                                                                                                                                                 |
  | `shopperLocale`                 | The combination of a language code and a country code to specify the language to be used in the payment.                                                                                                                                                                                                                                         |
  | `shopperName`                   | The shopper's full name and gender (if specified).                                                                                                                                                                                                                                                                                               |
  | `shopperReference`              | The shopper's reference to uniquely identify this shopper (e.g. user ID or account ID).                                                                                                                                                                                                                                                          |
  | `shopperStatement`              | The text to appear on the shopper's bank statement.                                                                                                                                                                                                                                                                                              |
  | `socialSecurityNumber`          | The shopper's social security number.                                                                                                                                                                                                                                                                                                            |
  | `store`                         | The physical store, for which this payment is processed.                                                                                                                                                                                                                                                                                         |
  | `telephoneNumber`               | The shopper's telephone number.                                                                                                                                                                                                                                                                                                                  |
  | `totalsGroup`                   | The reference value to aggregate sales totals in reporting. When not specified, the store field is used (if available).                                                                                                                                                                                                                          |
  | `modificationAmount`            | The amount that needs to be captured/refunded. Required for /capture and /refund, not allowed for /cancel. The currency must match the currency used in authorisation, the value must be smaller than or equal to the authorised amount.                                                                                                         |
  | `originalMerchantReference`     | The original merchant reference to cancel.                                                                                                                                                                                                                                                                                                       |
  | `originalReference`             | The original pspReference of the payment to modify. This reference is returned in, authorisation response, authorisation notification.                                                                                                                                                                                                           |

  ## Registering your ADYEN account at `Gringotts`

  After [making an account on ADYEN][signup], head to the [getting started][get-start].

  Here's how the secrets map to the required configuration parameters for ADYEN:

  | Config parameter | Adyen secret   |
  | -------          | ----           |
  | `:username`      | **User Name**  |
  | `:password`      | **Password**   |
  | `:account`       | **Account**    |
  | `:mode`          | **Mode**       |
  | `:url`           | **URL**        |

  [home]: https://www.adyen.com/
  [docs]: https://docs.adyen.com/developers
  [signup]: https://www.adyen.com/signup
  [gs]: https://github.com/aviabird/gringotts/wiki
  [example-repo]: https://github.com/aviabird/gringotts_example
  [country-currency]: https://docs.adyen.com/developers/currency-codes
  [extra-arg-docs]: https://docs.adyen.com/api-explorer/#/Payment/v30/overview
  [get-start]: https://docs.adyen.com/developers/get-started-with-adyen

  [example-repo]: https://github.com/aviabird/gringotts_example
  [iex-docs]: https://hexdocs.pm/iex/IEx.html#module-the-iex-exs-file
  [ADYEN.iex.exs]: https://gist.github.com/anantanant2015/255cb867a72d79ae69b3566fb929a8e8

  Your Application config **must include the `:username`, `:password`, `:account`, `:mode`, `:url`
  fields** and would look something like this:

      config :gringotts, Gringotts.Gateways.Adyen,
        username: "your username",
        password: "your generated password",
        account: "your account",
        mode: :test | :live,
        url: "your url"

  For username, password, account details refer to `Settings > Users > Name` of your account.

  ## Scope of this module 

  * This module does not support these endpoints given below.
      - adjustAuthorisation
      - authorise3d
      - cancelOrRefund
      - technicalCancel
  * This module supports only card payments, and you have to be PCI Compliant for using it.
  * This module currently supports only the optional `keyword` list `opts` given above in the `opts` argument.
  * This module returnes `pspReference` for any transaction in `Response.id`.
  * This module expects some required `keyword` list `opts` for methods given below.
      - `authorize/3`
          - reference
          - merchantAccount
      - `capture/3`
          - merchantAccount
      - `purchase/3`
          - reference
          - merchantAccount
      - `refund/3`
          - merchantAccount
      - `void/2`
          - merchantAccount

  ## Supported countries and countries

  For ADYEN supported countries and currencies [here][country-currency].

  ## Following the examples

  1. First, set up a sample application and configure it to work with ADYEN.
      - You could do that from scratch by following our [Getting Started](#) guide.
      - To save you time, we recommend [cloning our example repo][example-repo]
        that gives you a pre-configured sample app ready-to-go.
        + You could use the same config or update it the with your "secrets"
          that you see in `Settings > Users > Name` as described
          [above](#module-registering-your-adyen-account-at-gringotts).

  2. To save a lot of time, create a [`.iex.exs`][iex-docs] file as shown in
     [this gist][ADYEN.iex.exs] to introduce a set of handy bindings and
     aliases.

  We'll be using these bindings in the examples below.
  """

  use Gringotts.Gateways.Base
  use Gringotts.Adapter, required_config: [:username, :password, :account, :mode, :url]

  alias Gringotts.{Response, Money, CreditCard}

  @base_url "https://pal-test.adyen.com/pal/servlet/Payment/v30/"
  @headers [{"Content-Type", "application/json"}]

  @doc """
  Performs a (pre) Authorize operation.

  The authorization validates the `card` details with the banking network,
  places a hold on the transaction `amount` in the customer’s issuing bank and
  also triggers risk management. Funds are transferred depending on [Capture Delay][capture-delay]
  in your ADYEN account for more details refer to [Capture Delay][capture-delay].

  For more details of authorize `opts`, please refer to [Authorize Fields][authorise-api-explorer].

  ADYEN returns an ID string which can be used to:

  * `capture/3` _an_ amount.
  * `void/2` a pre-authorization.

  ## Note

  * For the reference of various stages in Payment, please refer [here][payment-cycle].

  [capture-delay]: https://docs.adyen.com/developers/payment-modifications/capture#capturedelay
  [authorise-api-explorer]: https://docs.adyen.com/api-explorer/#/Payment/v30/authorise
  [payment-cycle]: https://docs.adyen.com/developers/payments-lifecycle

  ## Example

  The following example shows how one would (pre) authorize a payment of $42 on
  a sample `card`.

      iex> amount = Money.new(42, :USD)
      iex> card = %Gringotts.CreditCard{first_name: "Harry", last_name: "Potter", number: "4200000000000000", year: 2099, month: 12, verification_code:  "123", brand: "VISA"}
      iex> {:ok, auth_result} = Gringotts.authorize(Gringotts.Gateways.Adyen, amount, card, opts)
      iex> auth_result.id # This is the authorization ID
  """

  @spec authorize(Money.t(), CreditCard.t(), keyword) :: {:ok | :error, Response.t()}
  def authorize(amount, card, opts) do
    params = authorize_params(card, amount, opts)
    commit(:post, "authorise", params, opts)
  end

  @doc """
  Captures a pre-authorized `amount`.

  Please refer to [Capture Delay][capture-delay] for details.

  `amount` is transferred to the merchant account by ADYEN when it is smaller or
  equal to the amount used in the pre-authorization referenced by `payment_id`.

  ## Note

  ADYEN allows partial captures for more details please refer [here][partial-capture].

  For more details please refer to [Capture Fields][capture-api-explorer].

  [capture-api-explorer]: https://docs.adyen.com/api-explorer/#/Payment/v30/capture
  [partial-capture]: https://docs.adyen.com/developers/payments-lifecycle/payment-capture

  ADYEN returns an ID string which can be used to:

  * `refund/3` _an_ amount.

  ## Example

  The following example shows how one would (partially) capture a previously
  authorized a payment worth $35 by referencing the obtained authorization `id`.

      iex> amount = Money.new(35, :USD)
      iex> {:ok, capture_result} = Gringotts.capture(Gringotts.Gateways.Adyen, amount, auth_result.id, opts)
  """

  @spec capture(String.t(), Money.t(), keyword) :: {:ok | :error, Response.t()}
  def capture(id, amount, opts) do
    params = capture_and_refund_params(id, amount, opts)
    commit(:post, "capture", params, opts)
  end

  @doc """
  Transfers `amount` from the customer to the merchant.

  ADYEN attempts to process a authorize on behalf of the customer, then
  capture for debiting `amount` from the customer's account by charging 
  the customer's `card`.

  Because we are using `authorize/3` and `capture/3` in sequence here, so
  the `reference` will be the same in the whole transaction, and the opts
  will also be the same for both of these operations.

  For more details of authorize `opts`, please refer to [Authorize Fields][authorise-api-explorer]
  and for details of capture `opts`, please refer to [Capture Fields][capture-api-explorer].

  [capture-api-explorer]: https://docs.adyen.com/api-explorer/#/Payment/v30/capture
  [authorise-api-explorer]: https://docs.adyen.com/api-explorer/#/Payment/v30/authorise
  [capture-delay]: https://docs.adyen.com/developers/payment-modifications/capture#capturedelay

  ADYEN returns an ID string which can be used to:

  * `refund/3` _an_ amount.
  * `void/2` a pre-authorization in case of failure in capture after successful authorize.

  ## Note

  * You will recieve a `pspReference` in `Response.id`
    struct.
  * In the response struct you will receive the result same as of `capture/3`
    when transaction is successful or it failed after successful `authorize/3`.
    And in case of any failures during the process of `authorize/3` it's
    response struct will be from `authorize/3`.

  ## Example

  The following example shows how one would process a payment worth $42 in
  one-shot, without (pre) authorization.

      iex> amount = Money.new(42, :USD)
      iex> card = %Gringotts.CreditCard{first_name: "Harry", last_name: "Potter", number: "4200000000000000", year: 2099, month: 12, verification_code:  "123", brand: "VISA"}
      iex> {:ok, purchase_result} = Gringotts.purchase(Gringotts.Gateways.Adyen, amount, card, opts)
  """

  @spec purchase(Money.t(), CreditCard.t(), keyword) :: {:ok | :error, Response.t()}
  def purchase(amount, card, opts) do
    {auth_atom, auth_response} = authorize(amount, card, opts)

    case auth_atom do
      :ok -> capture(auth_response.id, amount, opts)
      _ -> {auth_atom, auth_response}
    end
  end

  @doc """
  Refunds the `amount` to the customer's account with reference to a prior transfer.

  ADYEN processes a full or partial refund worth `amount`, referencing a
  previous `purchase/3` or `capture/3`.

  For more details please refer to [Refund Fields][refund-api-explorer].

  [refund-api-explorer]: https://docs.adyen.com/api-explorer/#/Payment/v30/refund

  ## Example

  The following example shows how one would (completely) refund a previous
  purchase (and similarily for captures).

      iex> amount = Money.new(42, :USD)
      iex> {:ok, refund_result} = Gringotts.refund(Gringotts.Gateways.Adyen, purchase_result.id, amount, opts)
  """

  @spec refund(Money.t(), String.t(), keyword) :: {:ok | :error, Response.t()}
  def refund(amount, id, opts) do
    params = capture_and_refund_params(id, amount, opts)
    commit(:post, "refund", params, opts)
  end

  @doc """
  Voids the referenced payment.

  This method attempts a reversal of the previous `authorize/3`referenced by `Response.id`.

  ADYEN will reverse the authorization by sending a "cancel request" to the
  payment source (card issuer) to clear the funds held against the authorization.

  For more details please refer to [Void Fields][void-api-explorer].

  [void-api-explorer]: https://docs.adyen.com/api-explorer/#/Payment/v30/cancel

  ## Example

  The following example shows how one would void a previous (pre)
  authorization.

      iex> {:ok, void_result} = Gringotts.void(Gringotts.Gateways.Adyen, auth_result.id, opts)
  """

  @spec void(String.t(), keyword) :: {:ok | :error, Response.t()}
  def void(id, opts) do
    params = void_params(id, opts)
    commit(:post, "cancel", params, opts)
  end

  defp merge_keyword_list_to_map(exclude_keys, keyword_list, map) do
    keyword_list
    |> Keyword.drop(exclude_keys)
    |> Map.new()
    |> Map.merge(map)
  end

  defp authorize_params(%CreditCard{} = card, amount, opts) do
    body = merge_keyword_list_to_map([:config], opts, get_authorize_params(card, amount, opts))

    Poison.encode!(body)
  end

  defp get_authorize_params(card, amount, opts) do
    %{
      card: card_params(card),
      amount: amount_params(amount),
      merchantAccount: opts[:config][:account]
    }
  end

  defp capture_and_refund_params(id, amount, opts) do
    body =
      merge_keyword_list_to_map([:config], opts, get_capture_and_refund_params(id, amount, opts))

    Poison.encode!(body)
  end

  defp get_capture_and_refund_params(id, amount, opts) do
    %{
      originalReference: id,
      modificationAmount: amount_params(amount),
      merchantAccount: opts[:config][:account]
    }
  end

  defp void_params(id, opts) do
    body = merge_keyword_list_to_map([:config], opts, get_void_params(id, opts))

    Poison.encode!(body)
  end

  defp get_void_params(id, opts) do
    %{
      originalReference: id,
      merchantAccount: opts[:config][:account]
    }
  end

  defp card_params(%CreditCard{} = card) do
    %{
      number: card.number,
      expiryMonth: card.month,
      expiryYear: card.year,
      cvc: card.verification_code,
      holderName: CreditCard.full_name(card)
    }
  end

  defp amount_params(amount) do
    {currency, int_value, _} = Money.to_integer(amount)

    %{
      value: int_value,
      currency: currency
    }
  end

  defp commit(method, endpoint, params, opts) do
    method
    |> HTTPoison.request(base_url(opts) <> endpoint, params, headers(opts))
    |> respond
  end

  defp respond({:ok, response}) do
    case Poison.decode(response.body) do
      {:ok, parsed_resp} ->
        gateway_code = parsed_resp["status"]

        status = if gateway_code == 200 || response.status_code == 200, do: :ok, else: :error

        {status,
         %Response{
           id: parsed_resp["pspReference"],
           status_code: response.status_code,
           gateway_code: gateway_code,
           reason: parsed_resp["errorType"],
           message:
             parsed_resp["message"] || parsed_resp["resultCode"] || parsed_resp["response"],
           raw: response.body
         }}

      :error ->
        {:error, %Response{raw: response.body, reason: "could not parse ADYEN response"}}
    end
  end

  defp respond({:error, %HTTPoison.Error{} = response}) do
    {
      :error,
      Response.error(
        reason: "network related failure",
        message: "HTTPoison says '#{response.reason}' [ID: #{response.id || "nil"}]"
      )
    }
  end

  defp headers(opts) do
    arg = get_in(opts, [:config, :username]) <> ":" <> get_in(opts, [:config, :password])

    [
      {"Authorization", "Basic #{Base.encode64(arg)}"}
      | @headers
    ]
  end

  defp base_url(opts) do
    if opts[:config][:mode] == :test do
      @base_url
    else
      opts[:config][:url]
    end
  end
end
