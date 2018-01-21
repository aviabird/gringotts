defmodule Gringotts.Gateways.AuthorizeNet do

  @moduledoc """
  A module for working with the Authorize.net payment gateway. 
  
  The module provides a set of functions to perform transactions via this gateway for a merchant. 

  [AuthorizeNet API reference](https://developer.authorize.net/api/reference/index.html)

  The following set of functions for Authorize.Net have been provided:

  | Action                                       | Method        |
  | ------                                       | ------        |
  | Authorize a Credit Card                      | `authorize/3` |
  | Capture a Previously Authorized Amount       | `capture/3`   |
  | Charge a Credit Card                         | `purchase/3`  |
  | Refund a transaction                         | `refund/3`    |
  | Void a Transaction                           | `void/2`      |
  | Create Customer Profile                      | `store/2`     |
  | Create Customer Payment Profile              | `store/2`     |
  | Delete Customer Profile                      | `unstore/2`   |

  Most `Gringotts` API calls accept an optional `Keyword` list `opts` to supply
  optional arguments for transactions with the Authorize.Net gateway. The following keys
  are supported:

  | Key                  | Remark | Status          |
  | ----                 | ---    | ----            |
  | `customer`           |        | implemented     |
  | `invoice`            |        | implemented     |
  | `bill_to`            |        | implemented     |
  | `ship_to`            |        | implemented     |
  | `customer_ip`        |        | implemented     |
  | `order`              |        | implemented     |
  | `lineitems`          |        | implemented     |  
  | `ref_id`             |        | implemented     |
  | `tax`                |        | implemented     |
  | `duty`               |        | implemented     |
  | `shipping`           |        | implemented     |
  | `po_number`          |        | implemented     |
  | `customer_type`      |        | implemented     |
  | `customer_profile_id`|        | implemented     |
  | `profile`            |        | implemented     |

  To know more about these keywords visit [Request](https://developer.authorize.net/api/reference/index.html#payment-transactions)
  and [Response](https://developer.authorize.net/api/reference/index.html#payment-transactions) key sections for each function.

  ## Notes
  Authorize net supports [multiple currencies](https://community.developer.authorize.net/t5/The-Authorize-Net-Developer-Blog/Authorize-Net-UK-Europe-Update/ba-p/35957)
  however, multiple currencies in one account are not supported. To support multiple currencies merchant needs
  multiple Authorize.Net accounts, one for every currency. Currently, `Gringotts` supports single Authorize.Net 
  account configuration.
  
  To use this module you need to create an account with the [Authorize.Net 
  gateway](https://www.authorize.net/solutions/merchantsolutions/onlinemerchantaccount/)
  which will provide you with a `name` and a `transactionKey`.

  ## Configuring your AuthorizeNet account at `Gringotts`

  Your Application config **must include the `name` and `transaction_key`
  fields** and would look something like this:
  
      config :gringotts, Gringotts.Gateways.AuthorizeNet,
        adapter: Gringotts.Gateways.AuthorizeNet,
        name: "name_provided_by_authorize_net",
        transaction_key: "transactionKey_provided_by_authorize_net"
  
  ## Scope of this module, and _quirks_
  * Although Authorize.Net supports payments from [various
  sources](https://www.authorize.net/solutions/merchantsolutions/onlinemerchantaccount/),
  this library currently accepts payments by (supported) credit cards only.

  ## Following the examples
  1. First, set up a sample application and configure it to work with Authorize.Net.
      - You could do that from scratch by following our [Getting Started](#) guide.
      - To save you time, we recommend [cloning our example
  repo](https://github.com/aviabird/gringotts_example) that gives you a
  pre-configured sample app ready-to-go.
          + You could use the same config or update it the with your "secrets"
          [above](#Configuring your AuthorizeNet account at `Gringotts`).
  2. Run an `iex` session with `iex -S mix` and add some variable bindings and
  aliases to it (to save some time):
  ```
    iex> alias Gringotts.{Response, CreditCard, Gateways.AuthorizeNet}
  ```
  """

  import XmlBuilder
  import XmlToMap

  use Gringotts.Gateways.Base
  use Gringotts.Adapter, required_config: [:name, :transaction_key]
  alias Gringotts.Gateways.AuthorizeNet.ResponseHandler

  @test_url "https://apitest.authorize.net/xml/v1/request.api"
  @production_url "https://api.authorize.net/xml/v1/request.api"
  @header [{"Content-Type", "text/xml"}]

  @transaction_type %{
    purchase: "authCaptureTransaction",
    authorize: "authOnlyTransaction",
    capture: "priorAuthCaptureTransaction",
    refund: "refundTransaction",
    void: "voidTransaction"
  }

  @aut_net_namespace "AnetApi/xml/v1/schema/AnetApiSchema.xsd"

  alias Gringotts.{
    CreditCard,
    Response,
    Money
  }

  # ---------------Interface functions to be used by developer for
  #----------------making requests to gateway

  @doc """
  Charge a credit card.

  Function to charge a user credit card for the specified `amount`. It performs `authorize`
  and `capture` at the [same time](https://developer.authorize.net/api/reference/index.html#payment-transactions-charge-a-credit-card). 
  For this transaction Authorize.Net returns `transId` which can be used to:
  
  * `refund/3` a settled transaction.
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
      iex> opts = [
        ref_id: "123456",
        order: %{invoice_number: "INV-12345", description: "Product Description"}, 
        lineitems: %{itemId: "1", name: "vase", description: "Cannes logo", quantity: "18", unit_price: "45.00"}
      ]
      iex> card = %CreditCard{number: "5424000000000015", year: 2020, month: 12, verification_code: "999"}
      iex> amount = %{amount: Decimal.new(20.0), currency: 'USD'}
      iex> result = Gringotts.purchase(Gringotts.Gateways.AuthorizeNet, amount, card, opts)
  """
  @spec purchase(Money.t, CreditCard.t, Keyword.t) :: {:ok | :error, Response.t}
  def purchase(amount, payment, opts) do
    request_data =
      add_auth_purchase(amount, payment, opts, @transaction_type[:purchase])
    response_data = commit(:post, request_data, opts)
    respond(response_data)
  end

  @doc """
  Authorize a credit card transaction.

  Function to authorize a transaction for the specified amount. It needs to be
  followed up with a `capture/3` transaction to transfer the funds to merchant account.
  
  For this transaction Authorize.Net returns a `transId` which can be use for:
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
      iex> opts = [
        ref_id: "123456",
        order: %{invoice_number: "INV-12345", description: "Product Description"}, 
        lineitems: %{itemId: "1", name: "vase", description: "Cannes logo", quantity: "18", unit_price: "45.00"}
      ]
      iex> card = %CreditCard{number: "5424000000000015", year: 2020, month: 12, verification_code: "999"}
      iex> amount = %{amount: Decimal.new(20.0), currency: 'USD'}
      iex> result = Gringotts.authorize(Gringotts.Gateways.AuthorizeNet, amount, card, opts)
  """
  @spec authorize(Money.t, CreditCard.t, Keyword.t) :: {:ok | :error, Response.t}
  def authorize(amount, payment, opts) do
    request_data =
      add_auth_purchase(amount, payment, opts, @transaction_type[:authorize])
    response_data = commit(:post, request_data, opts)
    respond(response_data)
  end

  @doc """
  Capture a transaction.
  
  Function to capture an `amount` for an authorized transaction.

  For this transaction Authorize.Net returns a `transId` which can be use to:
    * `refund/3` a settled transaction.
    * `void/2` a transaction.
  
  ## Notes
  * If a `capture` transaction needs to `void` then it should be done before it is settled. For AuthorieNet
    all the transactions are settled after 24 hours.
  
  * AuthorizeNet supports partical capture of the `authorized amount`. But it is advisable to use one 
    `authorization code`  only [once](https://support.authorize.net/authkb/index?page=content&id=A1720&actp=LIST).

  ## Optional Fields
      opts = [
        order: %{invoice_number: String, description: String},
        ref_id: String
      ]
  
  ## Example
      iex> opts = [
        ref_id: "123456"
      ]
      iex> amount = %{amount: Decimal.new(20.0), currency: 'USD'}
      iex> id = "123456"
      iex> result = Gringotts.capture(Gringotts.Gateways.AuthorizeNet, id, amount, opts)
  """
  @spec capture(String.t, Money.t, Keyword.t) :: {:ok | :error, Response.t}
  def capture(id, amount, opts) do
    request_data = normal_capture(amount, id, opts, @transaction_type[:capture])
    response_data = commit(:post, request_data, opts)
    respond(response_data)
  end

  @doc """
  Refund `amount` for a settled transaction referenced by `id`.

  Use this method to refund a customer for a transaction that was already settled, requires
  transId of the transaction. The `payment` field in the `opts` is used to set the mode of payment.
  The `card` field inside `payment` needs the information of the credit card to be passed in the specified fields 
  so as to `refund` to that particular card.
  ## Required fields
      opts = [
        payment: %{card: %{number: String, year: Integer, month: Integer}}
      ]
  ## Optional fields
      opts = [ref_id: String]

  ## Example
      iex> opts = [
        payment: %{card: %{number: "5424000000000015", year: 2020, month: 12}}
        ref_id: "123456"
      ]
      iex> id = "123456"
      iex> amount = %{amount: Decimal.new(20.0), currency: 'USD'}
      iex> result = Gringotts.refund(Gringotts.Gateways.AuthorizeNet, amount, id, opts)
  """
  @spec refund(Money.t, String.t, Keyword.t) :: {:ok | :error, Response.t}
  def refund(amount, id, opts) do
    request_data = normal_refund(amount, id, opts, @transaction_type[:refund])
    response_data = commit(:post, request_data, opts)
    respond(response_data)
  end

  @doc """
  To void a transaction

  Use this method to cancel either an original transaction that is not settled or 
  an entire order composed of more than one transaction. It can be submitted against 'purchase', `authorize`
  and `capture`. Requires the `transId` of a transaction.

  ## Optional fields
      opts = [ref_id: String]

  ## Example
      iex> opts = [
        ref_id: "123456"
      ]
      iex> id = "123456"
      iex> result = Gringotts.void(Gringotts.Gateways.AuthorizeNet, id, opts)
  """
  @spec void(String.t, Keyword.t) :: {:ok | :error, Response.t}
  def void(id, opts) do
    request_data = normal_void(id, opts, @transaction_type[:void])
    response_data = commit(:post, request_data, opts)
    respond(response_data)
  end

  @doc """
  Store a customer payment profile.

  Use this function to store the customer card information by creating a [customer profile](https://developer.authorize.net/api/reference/index.html#customer-profiles-create-customer-profile) which also 
  creates a `payment profile` if `card` inofrmation is provided, and in case the `customer profile` exists without a payment profile, the merchant 
  can create customer payment profile by passing the `customer_profile_id` in the `opts`.
  The gateway also provide a provision for a `validation mode`, there are two modes `liveMode`
  and `testMode`, to know more about modes [see](https://developer.authorize.net/api/reference/index.html#customer-profiles-create-customer-profile).
  By default `validation mode` is set to `testMode`.
  
  ## Notes
  * The current version of this library supports only `credit card` as the payment profile.
  * If a customer profile is created without the card info, then to create a payment profile
    `card` info needs to be passed alongwith `cutomer_profile_id` to create it.

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
      iex> card = %CreditCard{number: "5424000000000015", year: 2020, month: 12, verification_code: "999"}
      iex> result = Gringotts.store(Gringotts.Gateways.AuthorizeNet, card, opts)
  """
  @spec store(CreditCard.t, Keyword.t) :: {:ok | :error, Response.t}
  def store(card, opts) do
    request_data = if opts[:customer_profile_id] do
      card |> create_customer_payment_profile(opts) |> generate
    else
      card |> create_customer_profile(opts) |> generate
    end
    response_data = commit(:post, request_data, opts)
    respond(response_data)
  end

  @doc """
  Remove a customer profile from the payment gateway.

  Use this function to unstore the customer card information by deleting the customer profile
  present. Requires the customer profile id.
  
  ## Example
      iex> id = "123456"
      iex> opts = []
      iex> result = Gringotts.store(Gringotts.Gateways.AuthorizeNet, id, opts)
  """
  
  @spec unstore(String.t, Keyword.t) :: {:ok | :error, Response.t}
  def unstore(customer_profile_id, opts) do
    request_data = customer_profile_id |> delete_customer_profile(opts) |> generate
    response_data = commit(:post, request_data, opts)
    respond(response_data)
  end

  # method to make the api request with params
  defp commit(method, payload, opts) do
    path = base_url(opts)
    headers = @header
    HTTPoison.request(method, path, payload, headers)
  end

  # Function to return a response
  defp respond({:ok, %{body: body, status_code: 200}}) do
    raw_response  = naive_map(body)
    response_type = ResponseHandler.check_response_type(raw_response)
    response_check(raw_response[response_type], raw_response)
  end

  defp respond({:ok, %{body: body, status_code: code}}) do
    {:error, Response.error(params: body, error_code: code)}
  end

  defp respond({:error, %HTTPoison.Error{} = error}) do
    {:error, Response.error(error_code: error.id, message: "HTTPoison says '#{error.reason}'")}
  end

  # Functions to send successful and error responses depending on message received
  # from gateway.

  defp response_check(%{"messages" => %{"resultCode" => "Ok"}}, raw_response) do
    {:ok, ResponseHandler.parse_gateway_success(raw_response)}
  end

  defp response_check(%{"messages" => %{"resultCode" => "Error"}}, raw_response) do
    {:error, ResponseHandler.parse_gateway_error(raw_response)}
  end

  #------------------- Helper functions for the interface functions-------------------

  # function for formatting the request as an xml for purchase and authorize method
  defp add_auth_purchase(amount, payment, opts, transaction_type) do
    :createTransactionRequest
    |> element(%{xmlns: @aut_net_namespace}, [
       add_merchant_auth(opts[:config]),
       add_order_id(opts),
       add_purchase_transaction_request(amount, transaction_type, payment, opts),
       ])
    |> generate
  end

  # function for formatting the request for  normal capture
  defp normal_capture(amount, id, opts, transaction_type) do
    :createTransactionRequest
    |> element(%{xmlns: @aut_net_namespace}, [
       add_merchant_auth(opts[:config]),
       add_order_id(opts),
       add_capture_transaction_request(amount, id, transaction_type, opts),
      ])
    |> generate
  end

  #function to format the request for normal refund
  defp normal_refund(amount, id, opts, transaction_type) do
    :createTransactionRequest
    |> element(%{xmlns: @aut_net_namespace}, [
        add_merchant_auth(opts[:config]),
        add_order_id(opts),
        add_refund_transaction_request(amount, id, opts, transaction_type),
       ])
    |> generate
  end

  #function to format the request for normal void operation
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
    |> generate
  end

  defp create_customer_payment_profile(card, opts) do
    element(:createCustomerPaymentProfileRequest, %{xmlns: @aut_net_namespace}, [
      add_merchant_auth(opts[:config]),
      element(:customerProfileId, opts[:customer_profile_id]),
      element(:paymentProfile, [
        add_billing_info(opts),
        add_payment_source(card)
      ]),
      element(:validationMode, 
        (if opts[:validation_mode], do: opts[:validation_mode], else: "testMode")
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
          element(:customerType,
            (if opts[:customer_type], do: opts[:customer_type], else: "individual")
          ),
          add_billing_info(opts),
          add_payment_source(card)
        ]),
      ]),
      element(:validationMode, 
        (if opts[:validation_mode], do: opts[:validation_mode], else: "testMode")
      )      
    ])
  end

  defp delete_customer_profile(id, opts) do
    element(:deleteCustomerProfileRequest, %{xmlns: @aut_net_namespace}, [
      add_merchant_auth(opts[:config]),
      element(:customerProfileId, id)
    ])
  end

  #--------------- XMl Builder functions for helper functions to assist 
  #---------------in attaching different tags for request

  defp add_merchant_auth(opts) do
    element(:merchantAuthentication, [
      element(:name, opts[:name]),
      element(:transactionKey, opts[:transaction_key])
    ])
  end

  defp add_order_id(opts) do
    element(:refId, opts[:ref_id])
  end

  defp add_purchase_transaction_request(amount, transaction_type, payment, opts) do
    element(:transactionRequest, [
      add_transaction_type(transaction_type),
      add_amount(amount),
      add_payment_source(payment),
      add_invoice(transaction_type, opts),
      add_tax_fields(opts),
      add_duty_fields(opts),
      add_shipping_fields(opts),
      add_po_number(opts),
      add_customer_info(opts)
    ])
  end

  defp add_capture_transaction_request(amount, id, transaction_type, opts) do
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
          element(:expirationDate, 
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
      amount = amount |> Money.value |> Decimal.to_float
      element(:amount, amount)
    end
  end

  defp add_payment_source(source) do
    # have to implement for other sources like apple pay
    # token payment method and check currently only for credit card
    add_credit_card(source)
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

  defp add_invoice(transactionType, opts) do
    element(
      [element(:order, [
        element(:invoiceNumber, opts[:order][:invoice_number]),
        element(:description, opts[:order][:description]),
      ]),
      element(:lineItems, [
        element(:lineItem, [
          element(:itemId, opts[:lineitems][:item_id]),
          element(:name, opts[:lineitems][:name]),
          element(:description, opts[:lineitems][:description]),
          element(:quantity, opts[:lineitems][:quantity]),
          element(
            :unitPrice, 
            opts[:lineitems][:unit_price] |> Money.value |> Decimal.to_float
          )
        ])
      ])
    ])
  end

  defp add_tax_fields(opts) do
    element(:tax, [
      add_amount(opts[:tax][:amount]),
      element(:name, opts[:tax][:name]),
      element(:description, opts[:tax][:description]),
    ])
  end

  defp add_duty_fields(opts) do
    element(:duty, [
      add_amount(opts[:duty][:amount]),
      element(:name, opts[:duty][:name]),
      element(:description, opts[:duty][:description]),
    ])
  end

  defp add_shipping_fields(opts) do
    element(:shipping, [
      add_amount(opts[:shipping][:amount]),
      element(:name, opts[:shipping][:name]),
      element(:description, opts[:shipping][:description]),
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
      element(:id, opts[:customer][:id])
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

  defmodule ResponseHandler do
    @moduledoc false
    alias Gringotts.Response
    
    @response_type %{
      auth_response: "authenticateTestResponse",
      transaction_response: "createTransactionResponse",
      error_response: "ErrorResponse",
      customer_profile_response: "createCustomerProfileResponse",
      customer_payment_profile_response: "createCustomerPaymentProfileResponse",
      delete_customer_profile: "deleteCustomerProfileResponse"
    }

    def parse_gateway_success(raw_response) do
      response_type = check_response_type(raw_response)
      message = raw_response[response_type]["messages"]["message"]["text"]
      avs_result = raw_response[response_type]["transactionResponse"]["avsResultCode"]
      cvc_result = raw_response[response_type]["transactionResponse"]["cavvResultCode"]

      []
        |> status_code(200)
        |> set_message(message)
        |> set_avs_result(avs_result)
        |> set_cvc_result(cvc_result)
        |> set_params(raw_response)
        |> set_success(true)
        |> handle_opts
    end

    def parse_gateway_error(raw_response) do
      response_type = check_response_type(raw_response)
      
      {message, error_code} = if raw_response[response_type]["transactionResponse"]["errors"] do
        {raw_response[response_type]["messages"]["message"]["text"] <> " " <>
          raw_response[response_type]["transactionResponse"]["errors"]["error"]["errorText"],
        raw_response[response_type]["transactionResponse"]["errors"]["error"]["errorCode"]}
      else
        {raw_response[response_type]["messages"]["message"]["text"],
        raw_response[response_type]["messages"]["message"]["code"]}
      end

      []
        |> status_code(200)
        |> set_message(message)
        |> set_error_code(error_code)
        |> set_params(raw_response)
        |> set_success(false)
        |> handle_opts
    end

    def check_response_type(raw_response) do
      cond do
        raw_response[@response_type[:transaction_response]] -> "createTransactionResponse"
        raw_response[@response_type[:error_response]] -> "ErrorResponse"
        raw_response[@response_type[:customer_profile_response]] -> "createCustomerProfileResponse"
        raw_response[@response_type[:customer_payment_profile_response]] -> "createCustomerPaymentProfileResponse"
        raw_response[@response_type[:delete_customer_profile]] -> "deleteCustomerProfileResponse"
      end
    end
    
    defp set_success(opts, value), do: opts ++ [success: value] 
    defp status_code(opts, code), do: opts ++ [status_code: code]
    defp set_message(opts, message), do: opts ++ [message: message]
    defp set_avs_result(opts, result), do: opts ++ [avs_result: result]
    defp set_cvc_result(opts, result), do: opts ++ [cvc_result: result]
    defp set_params(opts, raw_response), do: opts ++ [params: raw_response]
    defp set_error_code(opts, code), do: opts ++ [error_code: code]
    
    defp handle_opts(opts) do
      case Keyword.fetch(opts, :success) do
        {:ok, true} -> Response.success(opts)
        {:ok, false} -> Response.error(opts)
      end
    end

  end
end
