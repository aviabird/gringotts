defmodule Gringotts.Gateways.AuthorizeNet do

  @moduledoc """
  A module for working with the Authorize.net payment gateway. 
  
  The module provides a set of functions to perform transactions via this gateway for a merchant. 
  To use this module you need to create an account with the Authorize.net gateway which will provide you with a
  `name` and a `transactionKey`. You will need to configure these keys to use the module
  functions.

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
  | Create Customer Payment Profile              |  `store/2`    |
  | Delete Customer Profile                      | `unstore/2`   |
  """

  import XmlBuilder
  import XmlToMap

  use Gringotts.Gateways.Base
  use Gringotts.Adapter, required_config: [:name, :transactionKey, :default_currency]

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

  @response_type %{
    auth_response: "authenticateTestResponse",
    transaction_response: "createTransactionResponse",
    error_response: "ErrorResponse",
    customer_profile_response: "createCustomerProfileResponse",
    customer_payment_profile_response: "createCustomerPaymentProfileResponse",
    delete_customer_profile: "deleteCustomerProfileResponse"
  }

  @aut_net_namespace "AnetApi/xml/v1/schema/AnetApiSchema.xsd"

  alias Gringotts.{
    CreditCard,
    Address,
    Response
  }

  # ---------------Interface functions to be used by developer for
  #----------------making requests to gateway

  @doc """
  Charge a credit card.

  Function to charge a user credit card for the specified amount. It performs authorize
  and capture at the same time. 
  For this transaction Authorize.Net returns `transId` which can be used to:
  
  * `refund/3` a settled transaction.   
  * `void/2` a transaction.

  ## Optional Fields
      opts = [
        order: %{ invoiceNumber: String, description: String },
        refId: String,
        lineitems: %{
          itemId: String, name: String, description: String, 
          quantity: Integer, unitPrice: Float
        },
        tax: %{ amount: Float, name: String, description: String },
        duty: %{ amount: String, name: String, description: String },
        shipping: %{ amount: String, name: String, description: String },
        poNumber: String,
        customer: %{ id: String },
        billTo: %{ 
          firstName: String, lastName: String, company: String,
          address: String, city: String, state: String, zip: String, 
          country: String 
        },
        shipTo: %{
          firstName: String, lastName: String, company: String, address: String,
          city: String, state: String, zip: String, country: String
        },
        customerIP: String
      ]

  ## Example
      opts = [config: %{name: "your_name", transactionKey: "your_key"}, 
        refId: "123456", 
        order: %{invoiceNumber: "INV-12345", description: "Product Description"}, 
        lineItem: %{itemId: "1", name: "vase", description: "Cannes logo", quantity: "18", unitPrice: "45.00" }
      ]
      card = %CreditCard{number: "5424000000000015", year: 2020, month: 12, verification_code: "999"} 
      amount = 5
  """
  @spec purchase(Float, CreditCard.t, Keyword) :: Tuple
  def purchase(amount, payment, opts) do
    request_data = add_auth_purchase(amount, payment, opts, @transaction_type[:purchase])
    response_data = commit(:post, request_data, opts)
    respond(response_data)
  end

  @doc """
  Authorize a credit card transaction.

  Function to authorize a transaction for the specified amount. It needs to be 
  followed up with a capture transaction to transfer the funds to merchant account.
  
  For this transaction Authorize.Net returns a `transId` which can be use for:
  * `capture/3` an authorized transaction.
  * `refund/3` a settled transaction.   
  * `void/2` a transaction.

  ## Optional Fields
      opts = [
        order: %{ invoiceNumber: String, description: String },
        refId: String,
        lineitems: %{
          itemId: String, name: String, description: String,
          quantity: Integer, unitPrice: Float
        },
        tax: %{ amount: Float, name: String, description: String },
        duty: %{ amount: String, name: String, description: String },
        shipping: %{ amount: String, name: String, description: String },
        poNumber: String,
        customer: %{ id: String },
        billTo: %{ 
          firstName: String, lastName: String, company: String,
          address: String, city: String, state: String, zip: String, 
          country: String 
        },
        shipTo: %{
          firstName: String, lastName: String, company: String, address: String,
          city: String, state: String, zip: String, country: String
        },
        customerIP: String
      ]

  ## Example
      opts = [config: %{name: "your_name", transactionKey: "your_key"}, 
        refId: "123456", 
        order: %{invoiceNumber: "INV-12345", description: "Product Description"}, 
        lineItem: %{itemId: "1", name: "vase", description: "Cannes logo", quantity: "18", unitPrice: "45.00" }
      ]
      card = %CreditCard{number: "5424000000000015", year: 2020, month: 12, verification_code: "999"} 
      amount = 5
  """
  @spec authorize(Float, CreditCard.t, Keyword) :: Tuple
  def authorize(amount, payment, opts) do
    request_data = add_auth_purchase(amount, payment, opts, @transaction_type[:authorize])
    response_data = commit(:post, request_data, opts)
    respond(response_data)
  end

  @doc """
  Capture a transaction.
  
  Function to capture an `amount` for an authorized transaction.

  For this transaction Authorize.Net returns a `transId` which can be use for:
  * `refund/3` a settled transaction.
  * `void/2` a transaction.

  ## Optional Fields
      opts = [
        order: %{ invoiceNumber: String, description: String},
        refId: String 
      ]
  
  ## Example
      opts = [config: %{name: "your_name", transactionKey: "your_key"}, 
        refId: "123456",
        order: %{invoiceNumber: "INV-12345", description: "Product Description"}
      ]
      id = "transId of the authorize response"
      amount = 5
  """
  @spec capture(String.t, Float, Keyword) :: Tuple
  def capture(id, amount, opts) do
    request_data = normal_capture(amount, id, opts, @transaction_type[:capture])
    response_data = commit(:post, request_data, opts)
    respond(response_data)
  end

  @doc """
  Refund `amount` for a settled transaction referenced by `id`.

  Use this method to refund a customer for a transaction that was already settled, requires
  transId of the transaction.
  ## Required fields
      opts = [
        payment: %{ card: %{ number: String, year: Integer, month: Integer } }
      ]
  ## Optional fields
      opts = [refId: String]

  ## Example
      opts = [config: %{name: "your_name", transactionKey: "your_key"},
        payment: %{card: %{number: "5424000000000015", year: 2020, month: 12}}
        refId: "123456",
      ]
      id = "trans id of the transaction to be refunded"
      amount = 5
  """
  @spec refund(Float, String.t, Keyword) :: Tuple
  def refund(amount, id, opts) do
    request_data = normal_refund(amount, id, opts, @transaction_type[:refund])
    response_data = commit(:post, request_data, opts)
    respond(response_data)
  end

  @doc """
  To void a transaction

  Use this method to cancel either an original transaction that is not settled or 
  an entire order composed of more than one transaction. It can be submitted against
  any other transaction type. Requires the `transId` of a transaction passed as `id`.

  ## Optional fields
      opts = [refId: String]

  ## Example
      opts = [config: %{name: "your_name", transactionKey: "your_key"},
        refId: "123456",
      ]
      id = "trans id of the transaction to be void"
  """
  @spec void(String.t, Keyword) :: Tuple
  def void(id, opts) do
    request_data = normal_void(id, opts, @transaction_type[:void])
    response_data = commit(:post, request_data, opts)
    respond(response_data)
  end

  @doc """
  Store a customer payment profile.

  Use this function to store the customer card information by creating a customer profile,
  and in case the customer_profile_exists with gateway then by creating customer payment profile 
  which requires `customerProfileId`.

  ## Required Fields
      opts = [
        profile: %{ merchantCustomerId: String, description: String,email: String }
      ]
  ## Optional Fields
      opts = [
        validationMode: String,
        billTo: %{
          firstName: String, lastName: String, company: String, address: String,
          city: String, state: String, zip: String, country: String
        },
        customerType: String,
        customerProfileId: String
      ]
  ## Example
      opts = [config: %{ name: "your_name", transactionKey: "your_key" },
        profile: %{merchantCustomerId: 123456 ,description: "test store",email: "test@gmail.com"},
        validationMode: 'testMode'
      ]
      card = %CreditCard{number: "5424000000000015", year: 2020, month: 12, verification_code: "999"}
  """
  @spec store(CreditCard.t, Keyword) :: Tuple
  def store(card, opts) do
    request_data = cond  do
      opts[:customer_profile_id] -> create_customer_payment_profile(card, opts) |> generate 
      true -> create_customer_profile(card, opts) |> generate
    end
    response_data = commit(:post, request_data, opts)
    respond(response_data)
  end

  @doc """
  Remove a customer profile from the payment gateway.

  Use this function to unstore the customer card information by deleting the customer profile
  present. Requires the customer profile id.

  ## Required Fields
      opts = [
        customerProfileId: String
      ]
  """
  @spec unstore(String.t, Keyword) :: Tuple
  def unstore(customer_profile_id, opts) do
    request_data = delete_customer_profile(customer_profile_id, opts) |> generate
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
    cond do
      raw_response[@response_type[:auth_response]] ->
        response_check(raw_response[@response_type[:auth_response]], raw_response)
      raw_response[@response_type[:transaction_response]] ->
        response_check(raw_response[@response_type[:transaction_response]], raw_response)
      raw_response[@response_type[:error_response]] ->
        response_check(raw_response[@response_type[:error_response]], raw_response)
      raw_response[@response_type[:customer_profile_response]] ->
        response_check(raw_response[@response_type[:customer_profile_response]], raw_response)
      raw_response[@response_type[:customer_payment_profile_response]] ->
        response_check(raw_response[@response_type[:customer_payment_profile_response]], raw_response)
      raw_response[@response_type[:delete_customer_profile]] ->
        response_check(raw_response[@response_type[:delete_customer_profile]], raw_response)  
    end
  end

  defp respond({:error, %{body: body, status_code: code}}) do
    {:error, Response.error(raw: body, code: code)}
  end
 
  # Functions to send successful and error responses depending on message received
  # from gateway.

  defp response_check( %{"messages" => %{"resultCode" => "Ok"}}, raw_response) do
    {:ok, Response.success(raw: raw_response)}
  end

  defp response_check( %{"messages" => %{"resultCode" => "Error"}}, raw_response) do
    {:error, Response.error(raw: raw_response)}
  end

  #------------------- Helper functions for the interface functions-------------------

  # function for formatting the request as an xml for purchase and authorize method
  defp add_auth_purchase(amount, payment, opts, transaction_type) do
    element(:createTransactionRequest,  %{xmlns: @aut_net_namespace}, [
      add_merchant_auth(opts[:config]),
      add_order_id(opts),
      add_purchase_transaction_request(amount, transaction_type, payment, opts),
    ])
    |> generate
  end
  
  # function for formatting the request for  normal capture
  defp normal_capture(amount, id, opts, transaction_type) do
    element(:createTransactionRequest,  %{xmlns: @aut_net_namespace}, [
      add_merchant_auth(opts[:config]),
      add_order_id(opts),
      add_capture_transaction_request(amount, id, transaction_type, opts),
    ])
    |> generate
  end

  # function to format the request as an xml for the authenticate method
  defp add_auth_request(opts) do
    element(:authenticateTestRequest, %{xmlns: @aut_net_namespace}, [
      add_merchant_auth(opts[:config])
    ])
    |> generate
  end
  
  #function to format the request for normal refund
  defp normal_refund(amount, id, opts, transaction_type) do
    element(:createTransactionRequest, %{xmlns: @aut_net_namespace}, [
      add_merchant_auth(opts[:config]),
      add_order_id(opts),
      add_refund_transaction_request(amount, id, opts, transaction_type),
    ])
    |> generate
  end

  #function to format the request for normal void operation
  defp normal_void(id, opts, transaction_type) do
    element(:createTransactionRequest, %{xmlns: @aut_net_namespace}, [
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
    element(:createCustomerPaymentProfileRequest, %{xmlns: @aut_net_namespace},[
      add_merchant_auth(opts[:config]),
      element(:customerProfileId, opts[:customerProfileId]),
      element(:paymentProfile, [
        add_billing_info(opts),
        add_payment_source(card)
      ]),
      element(:validationMode, opts[:validation_mode])
    ])
  end

  defp create_customer_profile(card, opts) do
    element(:createCustomerProfileRequest, %{xmlns: @aut_net_namespace}, [
      add_merchant_auth(opts[:config]),
      element(:profile, [
        element(:merchantCustomerId, opts[:profile][:merchantCustomerId]),
        element(:description, opts[:profile][:description]),
        element(:email, opts[:profile][:description]),
        element(:paymentProfiles, [
          element(:customerType, (if opts[:customerType], do: opts[:customerType], else: "individual")),
          add_payment_source(card)
        ])
      ])
    ])
  end

  defp delete_customer_profile(id, opts) do
    element(:deleteCustomerProfileRequest, %{xmlns: @aut_net_namespace},[
      add_merchant_auth(opts[:config]),
      element(:customerProfileId, id)
    ])
  end

  #--------------- XMl Builder functions for helper functions to assist 
  #---------------in attaching different tags for request

  defp add_merchant_auth(opts) do
    element(:merchantAuthentication, [
      element(:name, opts[:name]),
      element(:transactionKey, opts[:transactionKey])
    ])
  end

  defp add_order_id(opts) do
    element(:refId, opts[:refId])
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
          element(:expirationDate, join_string([opts[:payment][:card][:year], opts[:payment][:card][:month]], "-"))
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
    cond do
      is_integer(amount) -> element(:amount, amount)
      is_float(amount) -> element(:amount, amount)
      true -> element(:amount, 0)
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
        element(:invoiceNumber, opts[:order][:invoiceNumber]),
        element(:description, opts[:order][:description]),
      ]),
      element(:lineItems, [
        element(:lineItem, [
          element(:itemId, opts[:lineItem][:itemId]),
          element(:name, opts[:lineItem][:name]),
          element(:description, opts[:lineItem][:description]),
          element(:quantity, opts[:lineItem][:quantity]),
          element(:unitPrice, opts[:lineItem][:unitPrice])
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
    element(:poNumber, opts[:poNumber])
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
      element(:firstName, opts[:billTo][:firstName]),
      element(:lastName, opts[:billTo][:lastName]),
      element(:company, opts[:billTo][:company]),
      element(:address, opts[:billTo][:address]),
      element(:city, opts[:billTo][:city]),
      element(:state, opts[:billTo][:state]),
      element(:zip, opts[:billTo][:zip]),
      element(:country, opts[:billTo][:country])
    ])
  end

  defp add_shipping_info(opts) do
    element(:shipTo, [
      element(:firstName, opts[:shipTo][:firstName]),
      element(:lastName, opts[:shipTo][:lastName]),
      element(:company, opts[:shipTo][:company]),
      element(:address, opts[:shipTo][:address]),
      element(:city, opts[:shipTo][:city]),
      element(:state, opts[:shipTo][:state]),
      element(:zip, opts[:shipTo][:zip]),
      element(:country, opts[:shipTo][:country]) 
    ])
  end

  defp add_customer_ip(opts) do
    element(:customerIP, opts[:customerIP])
  end

  defp join_string(list, symbol) do
    Enum.join(list, symbol)
  end
  
  defp base_url(opts) do
    cond do
      opts[:config][:mode] == :prod -> @production_url
      opts[:config][:mode] == :test -> @test_url
      true -> @test_url
    end  
  end

end
