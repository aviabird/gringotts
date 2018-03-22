defmodule Gringotts.Gateways.GlobalCollect do
  @moduledoc """
  [GlobalCollect][home] gateway implementation.

  For further details, please refer [GlobalCollect API documentation](https://epayments-api.developer-ingenico.com/s2sapi/v1/en_US/index.html).

  Following are the features that have been implemented for the GlobalCollect Gateway:

  | Action                       | Method        |
  | ------                       | ------        |
  | Authorize                    | `authorize/3` |
  | Purchase                     | `purchase/3`  |
  | Capture                      | `capture/3`   |
  | Refund                       | `refund/3`    |
  | Void                         | `void/2`      |

  ## Optional or extra parameters

  Most `Gringotts` API calls accept an optional `Keyword` list `opts` to supply
  optional arguments for transactions with the gateway.

  | Key                      | Status          |
  | ----                     | ---             |
  | `merchantCustomerId`     |  implemented    |
  | `description`            |  implemented    |
  | `customer_name`          |  implemented    |
  | `dob`                    |  implemented    |
  | `company`                |  implemented    |
  | `email`                  |  implemented    |
  | `phone`                  |  implemented    |
  | `order_id`               |  implemented    |
  | `invoice`                |  implemented    |
  | `billingAddress`         |  implemented    |
  | `shippingAddress`        |  implemented    |
  | `name`                   |  implemented    |
  | `skipAuthentication`     |  implemented    |

  ## Registering your GlobalCollect account at `Gringotts`

  After creating your account successfully on [GlobalCollect](http://www.globalcollect.com/) follow the [dashboard link](https://sandbox.account.ingenico.com/#/account/apikey) to fetch the secret_api_key, api_key_id and [here](https://sandbox.account.ingenico.com/#/account/merchantid) for merchant_id.

  Here's how the secrets map to the required configuration parameters for GlobalCollect:

  | Config parameter | GlobalCollect secret |
  | -------          | ----                 |
  | `:secret_api_key`| **SecretApiKey**     |
  | `:api_key_id`    | **ApiKeyId**         |
  | `:merchant_id`   | **MerchantId**       |

   Your Application config **must include the `[:secret_api_key, :api_key_id, :merchant_id]` field(s)** and would look
   something like this:

       config :gringotts, Gringotts.Gateways.GlobalCollect,
           secret_api_key: "your_secret_secret_api_key"
           api_key_id: "your_secret_api_key_id"
           merchant_id: "your_secret_merchant_id"

  ## Supported currencies and countries

  The GlobalCollect platform is able to support payments in [over 150 currencies][currencies]

  [currencies]: https://epayments.developer-ingenico.com/best-practices/services/currency-conversion
  ## Following the examples

  1. First, set up a sample application and configure it to work with GlobalCollect.
      - You could do that from scratch by following our [Getting Started][gs] guide.
      - To save you time, we recommend [cloning our example
      repo][example] that gives you a pre-configured sample app ready-to-go.
          + You could use the same config or update it the with your "secrets"
          as described [above](#module-registering-your-globalcollect-account-at-GlobalCollect).

  2. Run an `iex` session with `iex -S mix` and add some variable bindings and
  aliases to it (to save some time):
  ```
  iex> alias Gringotts.{Response, CreditCard, Gateways.GlobalCollect}

  iex> shippingAddress = %{
      street: "Desertroad",
      houseNumber: "1",
      additionalInfo: "Suite II",
      zip: "84536",
      city: "Monument Valley",
      state: "Utah",
      countryCode: "US"
    }

  iex> billingAddress = %{
      street: "Desertroad",
      houseNumber: "13",
      additionalInfo: "b",
      zip: "84536",
      city: "Monument Valley",
      state: "Utah",
      countryCode: "US"
    }

  iex> invoice = %{
      invoiceNumber: "000000123",
      invoiceDate: "20140306191500"
    }

  iex> name = %{
      title: "Miss",
      firstName: "Road",
      surname: "Runner"
    }

  iex> opts = [ description: "Store Purchase 1437598192", merchantCustomerId: "234", customer_name: "John Doe", dob: "19490917", company: "asma", email: "johndoe@gmail.com", phone: "7765746563", order_id: "2323", invoice: invoice, billingAddress: billingAddress, shippingAddress: shippingAddress, name: name, skipAuthentication: "true" ]

  ```

  We'll be using these in the examples below.

  [example]: https://github.com/aviabird/gringotts_example
  """
  @base_url "https://api-sandbox.globalcollect.com/v1/"

  use Gringotts.Gateways.Base

  # The Adapter module provides the `validate_config/1`
  # Add the keys that must be present in the Application config in the
  # `required_config` list
  use Gringotts.Adapter, required_config: [:secret_api_key, :api_key_id, :merchant_id]

  import Poison, only: [decode: 1]

  alias Gringotts.{Money, CreditCard, Response}

  @brand_map %{
    visa: "1",
    american_express: "2",
    master: "3",
    discover: "128",
    jcb: "125",
    diners_club: "132"
  }

  @doc """
  Performs a (pre) Authorize operation.

  The authorization validates the `card` details with the banking network,
  places a hold on the transaction `amount` in the customer’s issuing bank and
  also triggers risk management. Funds are not transferred.

  GlobalCollect returns a payment id which can be further used to:
  * `capture/3` _an_ amount.
  * `refund/3` _an_amount
  * `void/2` a pre_authorization

  ## Example

  > The following session shows how one would (pre) authorize a payment of $100 on
  a sample `card`.
  ```
  iex> card = %CreditCard{
      number: "4567350000427977",
      month: 12,
      year: 18,
      first_name: "John",
      last_name: "Doe",
      verification_code: "123",
      brand: "visa"
  }

  iex> amount = %{value: Decimal.new(100), currency: "USD"}

  iex> {:ok, auth_result} = Gringotts.authorize(Gringotts.Gateways.GlobalCollect, amount, card, opts)
  ```
  """
  @spec authorize(Money.t(), CreditCard.t(), keyword) :: {:ok | :error, Response}
  def authorize(amount, card = %CreditCard{}, opts) do
    params = create_params_for_auth_or_purchase(amount, card, opts)
    commit(:post, "payments", params, opts)
  end

  @doc """
  Captures a pre-authorized `amount`.

  `amount` is transferred to the merchant account by GlobalCollect used in the
  pre-authorization referenced by `payment_id`.

  ## Note

  > Authorized payment with PENDING_APPROVAL status only allow a single capture whereas the one with PENDING_CAPTURE status is used for payments that allow multiple captures.
  > PENDING_APPROVAL is a common status only with card and direct debit transactions.

  ## Example

  The following session shows how one would (partially) capture a previously
  authorized a payment worth $100 by referencing the obtained authorization `id`.

  ```
  iex> card = %CreditCard{
      number: "4567350000427977",
      month: 12,
      year: 18,
      first_name: "John",
      last_name: "Doe",
      verification_code: "123",
      brand: "visa"
    }

  iex> amount = %{value: Decimal.new(100), currency: "USD"}

  iex> {:ok, capture_result} = Gringotts.capture(Gringotts.Gateways.GlobalCollect, amount, card, opts)

  ```

  """
  @spec capture(String.t(), Money.t(), keyword) :: {:ok | :error, Response}
  def capture(payment_id, amount, opts) do
    params = create_params_for_capture(amount, opts)
    commit(:post, "payments/#{payment_id}/approve", params, opts)
  end

  @doc """
  Transfers `amount` from the customer to the merchant.

  GlobalCollect attempts to process a purchase on behalf of the customer, by
  debiting `amount` from the customer's account by charging the customer's
  `card`.

  ## Example

  >  The following session shows how one would process a payment in one-shot,
  without (pre) authorization.

  ```
  iex> card = %CreditCard{
      number: "4567350000427977",
      month: 12,
      year: 18,
      first_name: "John",
      last_name: "Doe",
      verification_code: "123",
      brand: "visa"
    }

  iex> amount = %{value: Decimal.new(100), currency: "USD"}

  iex> {:ok, purchase_result} = Gringotts.purchase(Gringotts.Gateways.GlobalCollect, amount, card, opts)

  ```
  """
  @spec purchase(Money.t(), CreditCard.t(), keyword) :: {:ok | :error, Response}
  def purchase(amount, card = %CreditCard{}, opts) do
    case authorize(amount, card, opts) do
      {:ok, results} ->
        payment_id = results.raw["payment"]["id"]
        capture(payment_id, amount, opts)

      {:error, results} ->
        {:error, results}
    end
  end

  @doc """
  Voids the referenced payment.

  This makes it impossible to process the payment any further and will also try to reverse an authorization on a card.
  Reversing an authorization that you will not be utilizing will prevent you from having to pay a fee/penalty for unused authorization requests.

  ## Example

  > The following session shows how one would void a previous (pre)
  authorization. Remember that our `capture/3` example only did a complete
  capture.

  ```
  iex> {:ok, void_result} = Gringotts.void(Gringotts.Gateways.GlobalCollect, auth_result.payment.id, opts)

  ```
  """
  @spec void(String.t(), keyword) :: {:ok | :error, Response}
  def void(payment_id, opts) do
    params = nil
    commit(:post, "payments/#{payment_id}/cancel", params, opts)
  end

  @doc """
  Refunds the `amount` to the customer's account with reference to a prior transfer.

  > You can refund any transaction by just calling this API

  ## Note

  You always have the option to refund just a portion of the payment amount.
  It is also possible to submit multiple refund requests on one payment as long as the total amount to be refunded does not exceed the total amount that was paid.

  ## Example

  > The following session shows how one would refund a previous purchase (and
  similarily for captures).

  ```
  iex> amount = %{value: Decimal.new(100), currency: "USD"}

  iex> {:ok, refund_result} = Gringotts.refund(Gringotts.Gateways.GlobalCollect, auth_result.payment.id, amount)
  ```
  """
  @spec refund(Money.t(), String.t(), keyword) :: {:ok | :error, Response}
  def refund(amount, payment_id, opts) do
    params = create_params_for_refund(amount, opts)
    commit(:post, "payments/#{payment_id}/refund", params, opts)
  end

  ###############################################################################
  #                                PRIVATE METHODS                              #
  ###############################################################################

  # Makes the request to GlobalCollect's network.
  # For consistency with other gateway implementations, make your (final)
  # network request in here, and parse it using another private method called
  # `respond`.

  defp create_params_for_refund(amount, opts) do
    %{
      amountOfMoney: add_money(amount, opts),
      customer: add_customer(opts)
    }
  end

  defp create_params_for_auth_or_purchase(amount, payment, opts) do
    %{
      order: add_order(amount, opts),
      cardPaymentMethodSpecificInput: add_payment(payment, @brand_map, opts)
    }
  end

  defp create_params_for_capture(amount, opts) do
    %{
      order: add_order(amount, opts)
    }
  end

  defp add_order(money, options) do
    %{
      amountOfMoney: add_money(money, options),
      customer: add_customer(options),
      references: add_references(options)
    }
  end

  defp add_money(amount, options) do
    {currency, amount, _} = Money.to_integer(amount)

    %{
      amount: amount,
      currencyCode: currency
    }
  end

  defp add_customer(options) do
    %{
      merchantCustomerId: options[:merchantCustomerId],
      personalInformation: personal_info(options),
      dateOfBirth: options[:dob],
      companyInformation: company_info(options),
      billingAddress: options[:billingAddress],
      shippingAddress: options[:shippingAddress],
      contactDetails: contact(options)
    }
  end

  defp add_references(options) do
    %{
      descriptor: options[:description],
      invoiceData: options[:invoice]
    }
  end

  defp personal_info(options) do
    %{
      name: options[:name]
    }
  end

  defp company_info(options) do
    %{
      name: options[:company]
    }
  end

  defp contact(options) do
    %{
      emailAddress: options[:email],
      phoneNumber: options[:phone]
    }
  end

  def add_card(%CreditCard{} = payment) do
    %{
      cvv: payment.verification_code,
      cardNumber: payment.number,
      expiryDate: "#{payment.month}" <> "#{payment.year}",
      cardholderName: CreditCard.full_name(payment)
    }
  end

  defp add_payment(payment, brand_map, opts) do
    brand = payment.brand

    %{
      paymentProductId: Map.fetch!(brand_map, String.to_atom(brand)),
      skipAuthentication: opts[:skipAuthentication],
      card: add_card(payment)
    }
  end

  defp auth_digest(path, secret_api_key, time, opts) do
    data = "POST\napplication/json\n#{time}\n/v1/#{opts[:config][:merchant_id]}/#{path}\n"
    :crypto.hmac(:sha256, secret_api_key, data)
  end

  defp commit(method, path, params, opts) do
    headers = create_headers(path, opts)
    data = Poison.encode!(params)
    url = "#{@base_url}#{opts[:config][:merchant_id]}/#{path}"
    response = HTTPoison.request(method, url, data, headers)
    response |> respond
  end

  defp create_headers(path, opts) do
    time = date

    sha_signature =
      auth_digest(path, opts[:config][:secret_api_key], time, opts) |> Base.encode64()

    auth_token = "GCS v1HMAC:#{opts[:config][:api_key_id]}:#{sha_signature}"

    headers = [
      {"Content-Type", "application/json"},
      {"Authorization", auth_token},
      {"Date", time}
    ]
  end

  defp date() do
    use Timex
    datetime = Timex.now() |> Timex.local()
    strftime_str = Timex.format!(datetime, "%a, %d %b %Y %H:%M:%S ", :strftime)
    time_zone = Timex.timezone(:local, datetime)
    time = strftime_str <> "#{time_zone.abbreviation}"
  end

  # Parses GlobalCollect's response and returns a `Gringotts.Response` struct
  # in a `:ok`, `:error` tuple.
  @spec respond(term) :: {:ok | :error, Response}
  defp respond(global_collect_response)

  defp respond({:ok, %{status_code: code, body: body}}) when code in [200, 201] do
    case decode(body) do
      {:ok, results} -> {:ok, Response.success(raw: results, status_code: code)}
    end
  end

  defp respond({:ok, %{status_code: status_code, body: body}}) do
    {:ok, results} = decode(body)
    message = Enum.map(results["errors"], fn x -> x["message"] end)
    detail = List.to_string(message)
    {:error, Response.error(status_code: status_code, message: detail, raw: results)}
  end

  defp respond({:error, %HTTPoison.Error{} = error}) do
    {:error,
     Response.error(
       code: error.id,
       reason: :network_fail?,
       description: "HTTPoison says '#{error.reason}'"
     )}
  end
end
