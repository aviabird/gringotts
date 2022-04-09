defmodule Gringotts.Gateways.AuthorizeNet do
  @moduledoc """
  A module for working with the Authorize.Net payment gateway.

  Refer the official Authorize.Net [API docs][docs].

  The following set of functions for Authorize.Net have been implemented:

  | Action                                       | Method        |
  | ------                                       | ------        |
  | Authorize a Credit Card                      | `authorize/3` |
  | Capture a previously authorized amount       | `capture/3`   |
  | Charge a Credit Card                         | `purchase/3`  |
  | Refund a transaction                         | `refund/3`    |
  | Void a transaction                           | `void/2`      |
  | Create Customer Profile                      | `store/2`     |
  | Create Customer Payment Profile              | `store/2`     |
  | Delete Customer Profile                      | `unstore/2`   |

  Most `Gringotts` API calls accept an optional `Keyword` list `opts` to supply
  optional arguments for transactions with the Authorize.Net gateway. The
  following keys are supported:

  | Key                   |
  | ----                  |
  | `customer`            |
  | `invoice`             |
  | `bill_to`             |
  | `ship_to`             |
  | `customer_ip`         |
  | `order`               |
  | `lineitems`           |
  | `ref_id`              |
  | `tax`                 |
  | `duty`                |
  | `shipping`            |
  | `po_number`           |
  | `customer_type`       |
  | `customer_profile_id` |
  | `profile`             |

  To know more about these keywords check the [Request and Response][req-resp] tabs for each
  API method.

  [docs]: https://developer.authorize.net/api/reference/index.html
  [req-resp]: https://developer.authorize.net/api/reference/index.html#payment-transactions

  ## Notes

  1. Though Authorize.Net supports [multiple currencies][currencies] however,
     multiple currencies in one account is not supported. A merchant would need
     multiple Authorize.Net accounts, one for each chosen currency. Please refer
     the section on "Supported acquirers and currencies" [here][currencies].
  2. _You, the merchant needs to be PCI-DSS Compliant if you wish to use this
     module. Your server will recieve sensitive card and customer information._
  3. The responses of this module include a non-standard field: `:cavv_result`.
     - `:cavv_result` is the "cardholder authentication verification response
       code". In case of Mastercard transactions, this field will always be
       `nil`. Please refer the "Response Format" section in the [docs][docs] for
       more details.

  [currencies]: https://community.developer.authorize.net/t5/The-Authorize-Net-Developer-Blog/Authorize-Net-UK-Europe-Update/ba-p/35957

  ## Configuring your AuthorizeNet account at `Gringotts`

  To use this module you need to [create an account][dashboard] with the
  Authorize.Net gateway and obtain your login secrets: `name` and
  `transactionKey`.

  Your Application config **must include the `name` and `transaction_key`
  fields** and would look something like this:

      config :gringotts, Gringotts.Gateways.AuthorizeNet,
        name: "name_provided_by_authorize_net",
        transaction_key: "transactionKey_provided_by_authorize_net"

  ## Scope of this module

  Although Authorize.Net supports payments from various sources (check your
  [dashboard][dashboard]), this library currently accepts payments by
  (supported) credit cards only.

  [dashboard]: https://www.authorize.net/solutions/merchantsolutions/onlinemerchantaccount/

  ## Following the examples

  1. First, set up a sample application and configure it to work with Authorize.Net.
      - You could do that from scratch by following our [Getting Started][gs]
        guide.
      - To save you time, we recommend [cloning our example repo][example-repo]
      that gives you a pre-configured sample app ready-to-go.
        + You could use the same config or update it the with your "secrets"
          [above](#module-configuring-your-authorizenet-account-at-gringotts).

  2. To save a lot of time, create a [`.iex.exs`][iex-docs] file as shown in
     [this gist][authorize_net.iex.exs] to introduce a set of handy bindings and
     aliases.

  We'll be using these bindings in the examples below.

  [example-repo]: https://github.com/aviabird/gringotts_example
  [iex-docs]: https://hexdocs.pm/iex/IEx.html#module-the-iex-exs-file
  [authorize_net.iex.exs]: https://gist.github.com/oyeb/b1030058bda1fa9a3d81f1cf30723695
  [gs]: https://github.com/aviabird/gringotts/wiki
  """

  import XmlBuilder

  use Gringotts.Gateways.Base
  use Gringotts.Adapter, required_config: [:name, :transaction_key]
  alias Gringotts.Gateways.AuthorizeNet.ResponseHandler

  @test_url "https://apitest.authorize.net/xml/v1/request.api"
  @production_url "https://api.authorize.net/xml/v1/request.api"
  @headers [{"Content-Type", "text/xml"}]

  @transaction_type %{
    purchase: "authCaptureTransaction",
    authorize: "authOnlyTransaction",
    capture: "priorAuthCaptureTransaction",
    refund: "refundTransaction",
    void: "voidTransaction"
  }

  @aut_net_namespace "AnetApi/xml/v1/schema/AnetApiSchema.xsd"

  alias Gringotts.{CreditCard, Money, Response}

  @doc """
  Transfers `amount` from the customer to the merchant.

  Charges a credit `card` for the specified `amount`. It performs `authorize`
  and `capture` at the [same time][auth-cap-same-time].

  Authorize.Net returns `transId` (available in the `Response.id` field) which
  can be used to:

  * `refund/3` a settled transaction.
  * `void/2` a transaction.

  [auth-cap-same-time]: https://developer.authorize.net/api/reference/index.html#payment-transactions-charge-a-credit-card

  ## Optional Fields
      opts = [
        order: %{invoice_number: String, description: String},
        ref_id: String,
        lineitems: %{
          item_id: String, name: String, description: String,
          quantity: Integer, unit_price: Gringotts.Money.t()
        },
        tax: %{amount: Gringotts.Money.t(), name: String, description: String},
        duty: %{amount: Gringotts.Money.t(), name: String, description: String},
        shipping: %{amount: Gringotts.Money.t(), name: String, description: String},
        po_number: String,
        customer: %{id: String},
        bill_to: %{
          first_name: String, last_name: String, company: String,
          address: String, city: String, state: String, zip: String,
          country: String
        },
        ship_to: %{
          first_name: String, last_name: String, company: String, address: String,
          city: String, state: String, zip: String, country: String
        },
        customer_ip: String
      ]

  ## Example
      iex> amount = Money.new(20, :USD)
      iex> opts = [
        ref_id: "123456",
        order: %{invoice_number: "INV-12345", description: "Product Description"},
        lineitems: %{item_id: "1", name: "vase", description: "Cannes logo", quantity: 1, unit_price: amount},
        tax: %{name: "VAT", amount: Money.new("0.1", :EUR), description: "Value Added Tax"},
        shipping: %{name: "SAME-DAY-DELIVERY", amount: Money.new("0.56", :EUR), description: "Zen Logistics"},
        duty: %{name: "import_duty", amount: Money.new("0.25", :EUR), description: "Upon import of goods"}
      ]
      iex> card = %CreditCard{number: "5424000000000015", year: 2099, month: 12, verification_code: "999"}
      iex> result = Gringotts.purchase(Gringotts.Gateways.AuthorizeNet, amount, card, opts)
  """
  @spec purchase(Money.t(), CreditCard.t() | Keyword.t(), Keyword.t()) :: {:ok | :error, Response.t()}
  def purchase(amount, payment, opts) do
    request_data = add_auth_purchase(amount, payment, opts, @transaction_type[:purchase])
    commit(request_data, opts)
  end

  @doc """
  Authorize a credit card transaction.

  The authorization validates the `card` details with the banking network,
  places a hold on the transaction `amount` in the customer’s issuing bank and
  also triggers risk management. Funds are not transferred.

  To transfer the funds to merchant's account follow this up with a `capture/3`.

  Authorize.Net returns a `transId` (available in the `Response.id` field) which
  can be used for:

  * `capture/3` an authorized transaction.
  * `void/2` a transaction.

  ## Optional Fields
      opts = [
        order: %{invoice_number: String, description: String},
        ref_id: String,
        lineitems: %{
          item_id: String, name: String, description: String,
          quantity: Integer, unit_price: Gringotts.Money.t()
        },
        tax: %{amount: Gringotts.Money.t(), name: String, description: String},
        duty: %{amount: Gringotts.Money.t(), name: String, description: String},
        shipping: %{amount: Gringotts.Money.t(), name: String, description: String},
        po_number: String,
        customer: %{id: String},
        bill_to: %{
          first_name: String, last_name: String, company: String,
          address: String, city: String, state: String, zip: String,
          country: String
        },
        ship_to: %{
          first_name: String, last_name: String, company: String, address: String,
          city: String, state: String, zip: String, country: String
        },
        customer_ip: String
      ]

  ## Example
      iex> amount = Money.new(20, :USD)
      iex> opts = [
        ref_id: "123456",
        order: %{invoice_number: "INV-12345", description: "Product Description"},
        lineitems: %{item_id: "1", name: "vase", description: "Cannes logo", quantity: 1, unit_price: amount},
        tax: %{name: "VAT", amount: Money.new("0.1", :EUR), description: "Value Added Tax"},
        shipping: %{name: "SAME-DAY-DELIVERY", amount: Money.new("0.56", :EUR), description: "Zen Logistics"},
        duty: %{name: "import_duty", amount: Money.new("0.25", :EUR), description: "Upon import of goods"}
      ]
      iex> card = %CreditCard{number: "5424000000000015", year: 2099, month: 12, verification_code: "999"}
      iex> result = Gringotts.authorize(Gringotts.Gateways.AuthorizeNet, amount, card, opts)
  """
  @spec authorize(Money.t(), CreditCard.t(), Keyword.t()) :: {:ok | :error, Response.t()}
  def authorize(amount, payment, opts) do
    request_data = add_auth_purchase(amount, payment, opts, @transaction_type[:authorize])
    commit(request_data, opts)
  end

  @doc """
  Captures a pre-authorized `amount`.

  `amount` is transferred to the merchant account by Authorize.Net when it is smaller or
  equal to the amount used in the pre-authorization referenced by `id`.

  Authorize.Net returns a `transId` (available in the `Response.id` field) which
  can be used to:

  * `refund/3` a settled transaction.
  * `void/2` a transaction.

  ## Notes

  * Authorize.Net automatically settles authorized transactions after 24
    hours. Hence, unnecessary authorizations must be `void/2`ed within this
    period!
  * Though Authorize.Net supports partial capture of the authorized `amount`, it
    is [advised][sound-advice] not to do so.

  [sound-advice]: https://support.authorize.net/authkb/index?page=content&id=A1720&actp=LIST

  ## Optional Fields
      opts = [
        order: %{invoice_number: String, description: String},
        ref_id: String
      ]

  ## Example
      iex> opts = [
        ref_id: "123456"
      ]
      iex> amount = Money.new(20, :USD)
      iex> id = "123456"
      iex> result = Gringotts.capture(Gringotts.Gateways.AuthorizeNet, id, amount, opts)
  """
  @spec capture(String.t(), Money.t(), Keyword.t()) :: {:ok | :error, Response.t()}
  def capture(id, amount, opts) do
    request_data = normal_capture(amount, id, opts, @transaction_type[:capture])
    commit(request_data, opts)
  end

  @doc """
  Refund `amount` for a settled transaction referenced by `id`.

  The `payment` field in the `opts` is used to set the instrument/mode of
  payment, which could be different from the original one.  Currently, we
  support only refunds to cards, so put the `card` details in the `payment`.

  ## Required fields
      opts = [
        payment: %{card: %{number: String, year: Integer, month: Integer}}
      ]
  ## Optional fields
      opts = [ref_id: String]

  ## Example
      iex> opts = [
        payment: %{card: %{number: "5424000000000015", year: 2099, month: 12}}
        ref_id: "123456"
      ]
      iex> id = "123456"
      iex> amount = Money.new(20, :USD)
      iex> result = Gringotts.refund(Gringotts.Gateways.AuthorizeNet, amount, id, opts)
  """
  @spec refund(Money.t(), String.t(), Keyword.t()) :: {:ok | :error, Response.t()}
  def refund(amount, id, opts) do
    request_data = normal_refund(amount, id, opts, @transaction_type[:refund])
    commit(request_data, opts)
  end

  @doc """
  Voids the referenced payment.

  This method attempts a reversal of the either a previous `purchase/3` or
  `authorize/3` referenced by `id`.

  It can cancel either an original transaction that may not be settled or an
  entire order composed of more than one transaction.

  ## Optional fields
      opts = [ref_id: String]

  ## Example
      iex> opts = [
        ref_id: "123456"
      ]
      iex> id = "123456"
      iex> result = Gringotts.void(Gringotts.Gateways.AuthorizeNet, id, opts)
  """
  @spec void(String.t(), Keyword.t()) :: {:ok | :error, Response.t()}
  def void(id, opts) do
    request_data = normal_void(id, opts, @transaction_type[:void])
    commit(request_data, opts)
  end

  @doc """
  Store a customer's profile and optionally associate it with a payment profile.

  Authorize.Net separates a [customer's profile][cust-profile] from their payment
  profile. Thus a customer can have multiple payment profiles.

  ## Create both profiles

  Add `:customer` details in `opts` and also provide `card` details. The response
  will contain a `:customer_profile_id`.

  ## Associate payment profile with existing customer profile

  Simply pass the `:customer_profile_id` in the `opts`. This will add the `card`
  details to the profile referenced by the supplied `:customer_profile_id`.

  ## Notes

  * Currently only supports `credit card` in the payment profile.
  * The supplied `card` details can be validated by supplying a
  [`:validation_mode`][cust-profile], available options are `testMode` and
  `liveMode`, the deafult is `testMode`.

  [cust-profile]: https://developer.authorize.net/api/reference/index.html#customer-profiles-create-customer-profile

  ## Required Fields
      opts = [
        profile: %{merchant_customer_id: String, description: String, email: String}
      ]
  ## Optional Fields
      opts = [
        validation_mode: String,
        bill_to: %{
          first_name: String, last_name: String, company: String, address: String,
          city: String, state: String, zip: String, country: String
        },
        customer_type: String,
        customer_profile_id: String
      ]
  ## Example
      iex> opts = [
        profile: %{merchant_customer_id: 123456, description: "test store", email: "test@gmail.com"},
        validation_mode: "testMode"
      ]
      iex> card = %CreditCard{number: "5424000000000015", year: 2099, month: 12, verification_code: "999"}
      iex> result = Gringotts.store(Gringotts.Gateways.AuthorizeNet, card, opts)
  """
  @spec store(CreditCard.t(), Keyword.t()) :: {:ok | :error, Response.t()}
  def store(card, opts) do
    request_data =
      if opts[:customer_profile_id] do
        card |> create_customer_payment_profile(opts) |> generate(format: :none)
      else
        card |> create_customer_profile(opts) |> generate(format: :none)
      end

    commit(request_data, opts)
  end

  @doc """
  Remove a customer profile from the payment gateway.

  Use this function to unstore the customer card information by deleting the customer profile
  present. Requires the customer profile id.

  ## Example
      iex> id = "123456"
      iex> result = Gringotts.store(Gringotts.Gateways.AuthorizeNet, id)
  """

  @spec unstore(String.t(), Keyword.t()) :: {:ok | :error, Response.t()}
  def unstore(customer_profile_id, opts) do
    request_data = customer_profile_id |> delete_customer_profile(opts) |> generate(format: :none)
    commit(request_data, opts)
  end

  # method to make the API request with params
  defp commit(payload, opts) do
    opts
    |> base_url()
    |> HTTPoison.post(payload, @headers)
    |> respond()
  end

  defp respond({:ok, %{body: body, status_code: 200}}), do: ResponseHandler.respond(body)

  defp respond({:ok, %{body: body, status_code: code}}) do
    {:error, %Response{raw: body, status_code: code}}
  end

  defp respond({:error, %HTTPoison.Error{} = error}) do
    {
      :error,
      %Response{
        reason: "network related failure",
        message: "HTTPoison says '#{error.reason}' [ID: #{error.id || "nil"}]"
      }
    }
  end

  ##############################################################################
  #                                 HELPER METHODS                             #
  ##############################################################################

  # function for formatting the request as an xml for purchase and authorize method
  defp add_auth_purchase(amount, payment, opts, transaction_type) do
    :createTransactionRequest
    |> element(%{xmlns: @aut_net_namespace}, [
      add_merchant_auth(opts[:config]),
      add_order_id(opts),
      add_purchase_transaction_request(amount, transaction_type, payment, opts)
    ])
    |> generate(format: :none)
  end

  # function for formatting the request for  normal capture
  defp normal_capture(amount, id, opts, transaction_type) do
    :createTransactionRequest
    |> element(%{xmlns: @aut_net_namespace}, [
      add_merchant_auth(opts[:config]),
      add_order_id(opts),
      add_capture_transaction_request(amount, id, transaction_type)
    ])
    |> generate(format: :none)
  end

  # function to format the request for normal refund
  defp normal_refund(amount, id, opts, transaction_type) do
    :createTransactionRequest
    |> element(%{xmlns: @aut_net_namespace}, [
      add_merchant_auth(opts[:config]),
      add_order_id(opts),
      add_refund_transaction_request(amount, id, opts, transaction_type)
    ])
    |> generate(format: :none)
  end

  # function to format the request for normal void operation
  defp normal_void(id, opts, transaction_type) do
    :createTransactionRequest
    |> element(%{xmlns: @aut_net_namespace}, [
      add_merchant_auth(opts[:config]),
      add_order_id(opts),
      element(:transactionRequest, [
        add_transaction_type(transaction_type),
        add_ref_trans_id(id)
      ])
    ])
    |> generate(format: :none)
  end

  defp create_customer_payment_profile(card, opts) do
    element(:createCustomerPaymentProfileRequest, %{xmlns: @aut_net_namespace}, [
      add_merchant_auth(opts[:config]),
      element(:customerProfileId, opts[:customer_profile_id]),
      element(:paymentProfile, [
        add_billing_info(opts),
        add_payment_source(card)
      ]),
      element(
        :validationMode,
        if(opts[:validation_mode], do: opts[:validation_mode], else: "testMode")
      )
    ])
  end

  defp create_customer_profile(card, opts) do
    element(:createCustomerProfileRequest, %{xmlns: @aut_net_namespace}, [
      add_merchant_auth(opts[:config]),
      element(:profile, [
        element(:merchantCustomerId, opts[:profile][:merchant_customer_id]),
        element(:description, opts[:profile][:description]),
        element(:email, opts[:profile][:description]),
        element(:paymentProfiles, [
          element(
            :customerType,
            if(opts[:customer_type], do: opts[:customer_type], else: "individual")
          ),
          add_billing_info(opts),
          add_payment_source(card)
        ])
      ]),
      element(
        :validationMode,
        if(opts[:validation_mode], do: opts[:validation_mode], else: "testMode")
      )
    ])
  end

  defp delete_customer_profile(id, opts) do
    element(:deleteCustomerProfileRequest, %{xmlns: @aut_net_namespace}, [
      add_merchant_auth(opts[:config]),
      element(:customerProfileId, id)
    ])
  end

  ##############################################################################
  #                    HELPERS TO ASSIST IN BUILDING AND                       #
  #                   COMPOSING DIFFERENT XmlBuilder TAGS                      #
  ##############################################################################

  defp add_merchant_auth(opts) do
    element(:merchantAuthentication, [
      element(:name, opts[:name]),
      element(:transactionKey, opts[:transaction_key])
    ])
  end

  defp add_order_id(opts) do
    element(:refId, opts[:ref_id])
  end

  defp add_purchase_transaction_request(amount, transaction_type, payment = %CreditCard{}, opts) do
    element(:transactionRequest, [
      add_transaction_type(transaction_type),
      add_amount(amount),
      add_payment_source(payment),
      add_invoice(opts),
      add_tax_fields(opts),
      add_duty_fields(opts),
      add_shipping_fields(opts),
      add_po_number(opts),
      add_billing_info(opts),
      add_customer_info(opts)
    ])
  end

  defp add_purchase_transaction_request(amount, transaction_type, payment, opts) do
    element(:transactionRequest, [
      add_transaction_type(transaction_type),
      add_amount(amount),
      add_payment_source(payment),
      add_invoice(opts),
      add_customer_id(opts),
      add_shipping_info(opts)
    ])
  end

  defp add_capture_transaction_request(amount, id, transaction_type) do
    element(:transactionRequest, [
      add_transaction_type(transaction_type),
      add_amount(amount),
      add_ref_trans_id(id)
    ])
  end

  defp add_refund_transaction_request(amount, id, opts, transaction_type) do
    element(:transactionRequest, [
      add_transaction_type(transaction_type),
      add_amount(amount),
      element(:payment, [
        element(:creditCard, [
          element(:cardNumber, opts[:payment][:card][:number]),
          element(
            :expirationDate,
            join_string([opts[:payment][:card][:year], opts[:payment][:card][:month]], "-")
          )
        ])
      ]),
      add_ref_trans_id(id)
    ])
  end

  defp add_ref_trans_id(id) do
    element(:refTransId, id)
  end

  defp add_transaction_type(transaction_type) do
    element(:transactionType, transaction_type)
  end

  defp add_amount(amount) do
    if amount do
      {_, value} = amount |> Money.to_string()
      element(:amount, value)
    end
  end

  defp add_payment_source(source = %CreditCard{}) do
    add_credit_card(source)
  end

  defp add_payment_source(source) do
    add_customer_payment_profile_info(source)
  end

  defp add_credit_card(source) do
    element(:payment, [
      element(:creditCard, [
        element(:cardNumber, source.number),
        element(:expirationDate, join_string([source.year, source.month], "-")),
        element(:cardCode, source.verification_code)
      ])
    ])
  end

  defp add_customer_payment_profile_info(source) do
    element(:profile, [
      element(:customerProfileId, source[:customer_profile_id]),
      element(:paymentProfile, [
        element(:paymentProfileId, source[:customer_payment_profile_id])
      ])
    ])
  end

  defp add_invoice(opts) do
    element([
      element(:order, [
        element(:invoiceNumber, opts[:order][:invoice_number]),
        element(:description, opts[:order][:description])
      ]),
      element(:lineItems, [
        element(:lineItem, [
          element(:itemId, opts[:lineitems][:item_id]),
          element(:name, opts[:lineitems][:name]),
          element(:description, opts[:lineitems][:description]),
          element(:quantity, opts[:lineitems][:quantity]),
          element(
            :unitPrice,
            opts[:lineitems][:unit_price] |> Money.value() |> Decimal.to_string(:normal)
          )
        ])
      ])
    ])
  end

  defp add_tax_fields(opts) do
    element(:tax, [
      add_amount(opts[:tax][:amount]),
      element(:name, opts[:tax][:name]),
      element(:description, opts[:tax][:description])
    ])
  end

  defp add_duty_fields(opts) do
    element(:duty, [
      add_amount(opts[:duty][:amount]),
      element(:name, opts[:duty][:name]),
      element(:description, opts[:duty][:description])
    ])
  end

  defp add_shipping_fields(opts) do
    element(:shipping, [
      add_amount(opts[:shipping][:amount]),
      element(:name, opts[:shipping][:name]),
      element(:description, opts[:shipping][:description])
    ])
  end

  defp add_po_number(opts) do
    element(:poNumber, opts[:po_number])
  end

  defp add_customer_info(opts) do
    element([
      add_customer_id(opts),
      add_billing_info(opts),
      add_shipping_info(opts),
      add_customer_ip(opts)
    ])
  end

  defp add_customer_id(opts) do
    element(:customer, [
      element(:id, opts[:customer][:id]),
      element(:email, opts[:customer][:email])
    ])
  end

  defp add_billing_info(opts) do
    element(:billTo, [
      element(:firstName, opts[:bill_to][:first_name]),
      element(:lastName, opts[:bill_to][:last_name]),
      element(:company, opts[:bill_to][:company]),
      element(:address, opts[:bill_to][:address]),
      element(:city, opts[:bill_to][:city]),
      element(:state, opts[:bill_to][:state]),
      element(:zip, opts[:bill_to][:zip]),
      element(:country, opts[:bill_to][:country])
    ])
  end

  defp add_shipping_info(opts) do
    element(:shipTo, [
      element(:firstName, opts[:ship_to][:first_name]),
      element(:lastName, opts[:ship_to][:last_name]),
      element(:company, opts[:ship_to][:company]),
      element(:address, opts[:ship_to][:address]),
      element(:city, opts[:ship_to][:city]),
      element(:state, opts[:ship_to][:state]),
      element(:zip, opts[:ship_to][:zip]),
      element(:country, opts[:ship_to][:country])
    ])
  end

  defp add_customer_ip(opts) do
    element(:customerIP, opts[:customer_ip])
  end

  defp join_string(list, symbol) do
    Enum.join(list, symbol)
  end

  defp base_url(opts) do
    if opts[:config][:mode] == :prod do
      @production_url
    else
      @test_url
    end
  end

  ##################################################################################
  #                               RESPONSE_HANDLER MODULE                          #
  #                                                                                #
  ##################################################################################

  defmodule ResponseHandler do
    @moduledoc false
    alias Gringotts.Response

    @supported_response_types [
      "authenticateTestResponse",
      "createTransactionResponse",
      "ErrorResponse",
      "createCustomerProfileResponse",
      "createCustomerPaymentProfileResponse",
      "deleteCustomerProfileResponse"
    ]

    @avs_code_translator %{
      # The street address matched, but the postal code did not.
      "A" => {"pass", "fail"},
      # No address information was provided.
      "B" => {nil, nil},
      # The AVS check returned an error.
      "E" => {"fail", nil},
      # The card was issued by a bank outside the U.S. and does not support AVS.
      "G" => {nil, nil},
      # Neither the street address nor postal code matched.
      "N" => {"fail", "fail"},
      # AVS is not applicable for this transaction.
      "P" => {nil, nil},
      # Retry — AVS was unavailable or timed out.
      "R" => {nil, nil},
      # AVS is not supported by card issuer.
      "S" => {nil, nil},
      # Address information is unavailable.
      "U" => {nil, nil},
      # The US ZIP+4 code matches, but the street address does not.
      "W" => {"fail", "pass"},
      # Both the street address and the US ZIP+4 code matched.
      "X" => {"pass", "pass"},
      # The street address and postal code matched.
      "Y" => {"pass", "pass"},
      # The postal code matched, but the street address did not.
      "Z" => {"fail", "pass"},
      # fallback in-case of absence
      "" => {nil, nil},
      # fallback in-case of absence
      nil => {nil, nil}
    }

    @cvc_code_translator %{
      "M" => "CVV matched.",
      "N" => "CVV did not match.",
      "P" => "CVV was not processed.",
      "S" => "CVV should have been present but was not indicated.",
      "U" => "The issuer was unable to process the CVV check.",
      # fallback in-case of absence
      nil => nil
    }

    @cavv_code_translator %{
      "" => "CAVV not validated.",
      "0" => "CAVV was not validated because erroneous data was submitted.",
      "1" => "CAVV failed validation.",
      "2" => "CAVV passed validation.",
      "3" => "CAVV validation could not be performed; issuer attempt incomplete.",
      "4" => "CAVV validation could not be performed; issuer system error.",
      "5" => "Reserved for future use.",
      "6" => "Reserved for future use.",
      "7" =>
        "CAVV failed validation, but the issuer is available. Valid for U.S.-issued card submitted to non-U.S acquirer.",
      "8" =>
        "CAVV passed validation and the issuer is available. Valid for U.S.-issued card submitted to non-U.S. acquirer.",
      "9" =>
        "CAVV failed validation and the issuer is unavailable. Valid for U.S.-issued card submitted to non-U.S acquirer.",
      "A" =>
        "CAVV passed validation but the issuer unavailable. Valid for U.S.-issued card submitted to non-U.S acquirer.",
      "B" => "CAVV passed validation, information only, no liability shift.",
      # fallback in-case of absence
      nil => nil
    }

    def respond(body) do
      response_map = XmlToMap.naive_map(body)

      case extract_gateway_response(response_map) do
        :undefined_response ->
          {
            :error,
            %Response{
              reason: "Undefined response from AunthorizeNet",
              raw: body,
              message: "You might wish to open an issue with Gringotts."
            }
          }

        result ->
          build_response(result, %Response{raw: body, status_code: 200})
      end
    end

    def extract_gateway_response(response_map) do
      # The type of the response should be supported
      # Find the first non-nil from the above, if all are `nil`...
      # We are in trouble!
      @supported_response_types
      |> Stream.map(&Map.get(response_map, &1, nil))
      |> Enum.find(:undefined_response, & &1)
    end

    defp build_response(%{"messages" => %{"resultCode" => "Ok"}, "transactionResponse" => %{"errors" => _}} = result, base_response) do
      {:error, ResponseHandler.parse_gateway_error(result, base_response)}
    end

    defp build_response(%{"messages" => %{"resultCode" => "Ok"}} = result, base_response) do
      {:ok, ResponseHandler.parse_gateway_success(result, base_response)}
    end

    defp build_response(%{"messages" => %{"resultCode" => "Error"}} = result, base_response) do
      {:error, ResponseHandler.parse_gateway_error(result, base_response)}
    end

    def parse_gateway_success(result, base_response) do
      id = result["transactionResponse"]["transId"]
      message = result["messages"]["message"]["text"]
      avs_result = result["transactionResponse"]["avsResultCode"]
      cvc_result = result["transactionResponse"]["cvvResultCode"]
      cavv_result = result["transactionResponse"]["cavvResultCode"]
      gateway_code = result["messages"]["message"]["code"]

      base_response
      |> set_id(id)
      |> set_message(message)
      |> set_gateway_code(gateway_code)
      |> set_avs_result(avs_result)
      |> set_cvc_result(cvc_result)
      |> set_cavv_result(cavv_result)
    end

    def parse_gateway_error(result, base_response) do
      message = result["messages"]["message"]["text"]
      gateway_code = result["messages"]["message"]["code"]

      error_text = result["transactionResponse"]["errors"]["error"]["errorText"]
      error_code = result["transactionResponse"]["errors"]["error"]["errorCode"]
      reason = "#{error_text} [Error code (#{error_code})]"

      base_response
      |> set_message(message)
      |> set_gateway_code(gateway_code)
      |> set_reason(reason)
    end

    ############################################################################
    #                                   HELPERS                                #
    ############################################################################

    defp set_id(response, id), do: %{response | id: id}
    defp set_message(response, message), do: %{response | message: message}
    defp set_gateway_code(response, code), do: %{response | gateway_code: code}
    defp set_reason(response, body), do: %{response | reason: body}

    defp set_avs_result(response, avs_code) do
      {street, zip_code} = @avs_code_translator[avs_code]
      %{response | avs_result: %{street: street, zip_code: zip_code}}
    end

    defp set_cvc_result(response, cvv_code) do
      %{response | cvc_result: @cvc_code_translator[cvv_code]}
    end

    defp set_cavv_result(response, cavv_code) do
      Map.put(response, :cavv_result, @cavv_code_translator[cavv_code])
    end
  end
end
