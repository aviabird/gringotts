defmodule Gringotts.Gateways.GlobalCollect do
  @moduledoc """
  [GlobalCollect][home] gateway implementation.

  For further details, please refer [GlobalCollect API documentation][docs].

  Following are the features that have been implemented for GlobalCollect:

  | Action                       | Method        |
  | ------                       | ------        |
  | Authorize                    | `authorize/3` |
  | Purchase                     | `purchase/3`  |
  | Capture                      | `capture/3`   |
  | Refund                       | `refund/3`    |
  | Void                         | `void/2`      |

  ## Optional parameters

  Most `Gringotts` API calls accept an optional `Keyword` list `opts` to supply
  optional arguments for transactions with the gateway.

  | Key                      | Remark          |
  | ----                     | ---             |
  | `merchantCustomerId`     |  Identifier for the consumer that can be used as a search criteria in the Global Collect Payment Console |
  | `description`            |  Descriptive text that is used towards to consumer, either during an online checkout at a third party and/or on the statement of the consumer |
  | `dob`                    |  The date of birth of the consumer Format: YYYYMMDD   |
  | `company`                |  Name of company, as a consumer                       |
  | `email`                  |  Email address of the consumer                        |
  | `phone`                  |  Phone number of the consumer                         |
  | `invoice`                |  Object containing additional invoice data            |
  | `billingAddress`         |  Object containing billing address details            |
  | `shippingAddress`        |  Object containing shipping address details           |
  | `name`                   |  Object containing the name details of the consumer   |
  | `skipAuthentication`     |  3D Secure Authentication will be skipped for this transaction if set to true |

  For more details of the required keys refer [this.][options]
  ## Registering your GlobalCollect account at `Gringotts`

  After creating your account successfully on [GlobalCollect][home] open the
  [dashboard][dashboard] to fetch the `secret_api_key`, `api_key_id` and
  `merchant_id` from the menu.

  Here's how the secrets map to the required configuration parameters for
  GlobalCollect:

  | Config parameter | GlobalCollect secret |
  | -------          | ----                 |
  | `:secret_api_key`| **SecretApiKey**     |
  | `:api_key_id`    | **ApiKeyId**         |
  | `:merchant_id`   | **MerchantId**       |

  Your Application config **must include the `:secret_api_key`, `:api_key_id`,
  `:merchant_id` field(s)** and would look something like this:

       config :gringotts, Gringotts.Gateways.GlobalCollect,
           secret_api_key: "your_secret_secret_api_key"
           api_key_id: "your_secret_api_key_id"
           merchant_id: "your_secret_merchant_id"

   ## Scope of this module

  * [All amount fields in globalCollect are in cents with each amount having 2 decimals.][amountReference]

  ## Supported currencies and countries

  The GlobalCollect platform supports payments in [over 150 currencies][currencies].

  ## Following the examples

  1. First, set up a sample application and configure it to work with GlobalCollect.
      - You could do that from scratch by following our [Getting Started][gs] guide.
      - To save you time, we recommend [cloning our example
      repo][example] that gives you a pre-configured sample app ready-to-go.
          + You could use the same config or update it the with your "secrets"
          as described [above](#module-registering-your-globalcollect-account-at-gringotts).

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

  iex> card = %CreditCard{
  number: "4567350000427977",
  month: 12,
  year: 43,
  first_name: "John",
  last_name: "Doe",
  verification_code: "123",
  brand: "VISA"
  }

  iex> opts = [
  description: "Store Purchase 1437598192",
  merchantCustomerId: "234", dob: "19490917",
  company: "asma", email: "johndoe@gmail.com",
  phone: "7765746563", invoice: invoice,
  billingAddress: billingAddress,
  shippingAddress: shippingAddress,
  name: name, skipAuthentication: "true"
  ]
  ```

  We'll be using these in the examples below.

  [home]: http://www.globalcollect.com/
  [docs]: https://epayments-api.developer-ingenico.com/s2sapi/v1/en_US/index.html
  [dashboard]: https://sandbox.account.ingenico.com/#/dashboard
  [gs]: #
  [options]: https://epayments-api.developer-ingenico.com/s2sapi/v1/en_US/java/payments/create.html#payments-create-payload
  [currencies]: https://epayments.developer-ingenico.com/best-practices/services/currency-conversion
  [example]: https://github.com/aviabird/gringotts_example
  [amountReference]: https://epayments-api.developer-ingenico.com/c2sapi/v1/en_US/swift/services/convertAmount.html
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
    VISA: "1",
    AMERICAN_EXPRESS: "2",
    MASTER: "3",
    DISCOVER: "128",
    JCB: "125",
    DINERS_CLUB: "132"
  }

  @doc """
  Performs a (pre) Authorize operation.

  The authorization validates the `card` details with the banking network,
  places a hold on the transaction `amount` in the customer’s issuing bank and
  also triggers risk management. Funds are not transferred.

  GlobalCollect returns a payment id which can be further used to:
  * `capture/3` an amount.
  * `refund/3` an amount
  * `void/2` a pre_authorization

  ## Example

  The following example shows how one would (pre) authorize a payment of $100 on
  a sample `card`.
  ```
  iex> card = %CreditCard{
      number: "4567350000427977",
      month: 12,
      year: 43,
      first_name: "John",
      last_name: "Doe",
      verification_code: "123",
      brand: "VISA"
  }

  iex> amount = Money.new(100, :USD)

  iex> {:ok, auth_result} = Gringotts.authorize(Gringotts.Gateways.GlobalCollect, amount, card, opts)
  ```
  """
  @spec authorize(Money.t(), CreditCard.t(), keyword) :: {:ok | :error, Response}
  def authorize(amount, %CreditCard{} = card, opts) do
    params = %{
      order: add_order(amount, opts),
      cardPaymentMethodSpecificInput: add_card(card, opts)
    }

    commit(:post, "payments", params, opts)
  end

  @doc """
  Captures a pre-authorized `amount`.

  `amount` used in the pre-authorization referenced by `payment_id` is
  transferred to the merchant account by GlobalCollect.

  ## Note

  Authorized payment with PENDING_APPROVAL status only allow a single capture whereas
  the one with PENDING_CAPTURE status is used for payments that allow multiple captures.

  ## Example

  The following example shows how one would (partially) capture a previously
  authorized a payment worth $100 by referencing the obtained authorization `id`.

  ```
  iex> amount = Money.new(100, :USD)

  iex> {:ok, capture_result} = Gringotts.capture(Gringotts.Gateways.GlobalCollect, auth_result.authorization, amount, opts)

  ```

  """
  @spec capture(String.t(), Money.t(), keyword) :: {:ok | :error, Response}
  def capture(payment_id, amount, opts) do
    params = %{
      order: add_order(amount, opts)
    }

    commit(:post, "payments/#{payment_id}/approve", params, opts)
  end

  @doc """
  Transfers `amount` from the customer to the merchant.

  GlobalCollect attempts to process a purchase on behalf of the customer, by
  debiting `amount` from the customer's account by charging the customer's
  `card`.

  ## Example

  The following example shows how one would process a payment in one-shot,
  without (pre) authorization.

  ```
  iex> card = %CreditCard{
      number: "4567350000427977",
      month: 12,
      year: 43,
      first_name: "John",
      last_name: "Doe",
      verification_code: "123",
      brand: "VISA"
    }

  iex> amount = Money.new(100, :USD)

  iex> {:ok, purchase_result} = Gringotts.purchase(Gringotts.Gateways.GlobalCollect, amount, card, opts)

  ```
  """
  @spec purchase(Money.t(), CreditCard.t(), keyword) :: {:ok | :error, Response}
  def purchase(amount, %CreditCard{} = card, opts) do
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

  This makes it impossible to process the payment any further and will also try
  to reverse an authorization on a card.
  Reversing an authorization that you will not be utilizing will prevent you
  from having to [pay a fee/penalty][void] for unused authorization requests.

  [void]: https://epayments-api.developer-ingenico.com/s2sapi/v1/en_US/java/payments/cancel.html#payments-cancel-request
  ## Example

  The following example shows how one would void a previous (pre)
  authorization. Remember that our `capture/3` example only did a complete
  capture.

  ```
  iex> {:ok, void_result} = Gringotts.void(Gringotts.Gateways.GlobalCollect, auth_result.authorization, opts)

  ```
  """
  @spec void(String.t(), keyword) :: {:ok | :error, Response}
  def void(payment_id, opts) do
    commit(:post, "payments/#{payment_id}/cancel", [], opts)
  end

  @doc """
  Refunds the `amount` to the customer's account with reference to a prior transfer.

  You always have the option to refund just a portion of the payment amount.
  It is also possible to submit multiple refund requests on one payment as long
  as the total amount to be refunded does not exceed the total amount that was paid.

  ## Example

  The following example shows how one would refund a previous purchase (and
  similarily for captures).

  ```
  iex> amount = Money.new(100, :USD)

  iex> {:ok, refund_result} = Gringotts.refund(Gringotts.Gateways.GlobalCollect, auth_result.authorization, amount)
  ```
  """
  @spec refund(Money.t(), String.t(), keyword) :: {:ok | :error, Response}
  def refund(amount, payment_id, opts) do
    params = %{
      amountOfMoney: add_money(amount),
      customer: add_customer(opts)
    }

    commit(:post, "payments/#{payment_id}/refund", params, opts)
  end

  ###############################################################################
  #                                PRIVATE METHODS                              #
  ###############################################################################

  defp add_order(money, options) do
    %{
      amountOfMoney: add_money(money),
      customer: add_customer(options),
      references: %{
        descriptor: options[:description],
        invoiceData: options[:invoice]
      }
    }
  end

  defp add_money(amount) do
    {currency, amount, _} = Money.to_integer(amount)

    %{
      amount: amount,
      currencyCode: currency
    }
  end

  defp add_customer(options) do
    %{
      merchantCustomerId: options[:merchantCustomerId],
      personalInformation: %{
        name: options[:name]
      },
      dateOfBirth: options[:dob],
      companyInformation: %{
        name: options[:company]
      },
      billingAddress: options[:billingAddress],
      shippingAddress: options[:shippingAddress],
      contactDetails: %{
        emailAddress: options[:email],
        phoneNumber: options[:phone]
      }
    }
  end

  defp add_card(card, opts) do
    %{
      paymentProductId: Map.fetch!(@brand_map, String.to_atom(card.brand)),
      skipAuthentication: opts[:skipAuthentication],
      card: %{
        cvv: card.verification_code,
        cardNumber: card.number,
        expiryDate: "#{card.month}#{card.year}",
        cardholderName: CreditCard.full_name(card)
      }
    }
  end

  defp commit(method, path, params, opts) do
    headers = create_headers(path, opts)
    data = Poison.encode!(params)
    merchant_id = opts[:config][:merchant_id]
    url = "#{@base_url}#{merchant_id}/#{path}"

    gateway_response = HTTPoison.request(method, url, data, headers)
    gateway_response |> respond
  end

  defp create_headers(path, opts) do
    datetime = Timex.now() |> Timex.local()

    date_string =
      "#{Timex.format!(datetime, "%a, %d %b %Y %H:%M:%S", :strftime)} #{datetime.zone_abbr}"

    api_key_id = opts[:config][:api_key_id]

    sha_signature = auth_digest(path, date_string, opts)

    auth_token = "GCS v1HMAC:#{api_key_id}:#{Base.encode64(sha_signature)}"
    [{"Content-Type", "application/json"}, {"Authorization", auth_token}, {"Date", date_string}]
  end

  defp auth_digest(path, date_string, opts) do
    secret_api_key = opts[:config][:secret_api_key]
    merchant_id = opts[:config][:merchant_id]

    data = "POST\napplication/json\n#{date_string}\n/v1/#{merchant_id}/#{path}\n"
    :crypto.hmac(:sha256, secret_api_key, data)
  end

  # Parses GlobalCollect's response and returns a `Gringotts.Response` struct
  # in a `:ok`, `:error` tuple.
  @spec respond(term) :: {:ok | :error, Response}
  defp respond(global_collect_response)

  defp respond({:ok, %{status_code: code, body: body}}) when code in [200, 201] do
    case decode(body) do
      {:ok, results} ->
        {
          :ok,
          Response.success(
            authorization: results["payment"]["id"],
            raw: results,
            status_code: code,
            avs_result:
              results["payment"]["paymentOutput"]["cardPaymentMethodSpecificOutput"][
                "fraudResults"
              ]["avsResult"],
            cvc_result:
              results["payment"]["paymentOutput"]["cardPaymentMethodSpecificOutput"][
                "fraudResults"
              ]["cvcResult"],
            message: results["payment"]["status"],
            fraud_review:
              results["payment"]["paymentOutput"]["cardPaymentMethodSpecificOutput"][
                "fraudResults"
              ]["fraudServiceResult"]
          )
        }

      {:error, _} ->
        {:error, Response.error(raw: body, message: "undefined response from GlobalCollect")}
    end
  end

  defp respond({:ok, %{status_code: status_code, body: body}}) do
    {:ok, results} = decode(body)
    message = Enum.map(results["errors"], fn x -> x["message"] end)
    detail = List.to_string(message)
    {:error, Response.error(status_code: status_code, message: detail, raw: results)}
  end

  defp respond({:error, %HTTPoison.Error{} = error}) do
    {
      :error,
      Response.error(
        code: error.id,
        reason: :network_fail?,
        description: "HTTPoison says '#{error.reason}'"
      )
    }
  end
end
