defmodule Kuber.Hex.Gateways.AuthorizeNet do
  import XmlBuilder
  import XmlToMap

  use Kuber.Hex.Gateways.Base
  use Kuber.Hex.Adapter, required_config: [:name, :transactionKey, :default_currency]

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
    transaction_response: "createTransactionResponse"
  }
  @aut_net_namespace "AnetApi/xml/v1/schema/AnetApiSchema.xsd"

  alias Kuber.Hex.{
    CreditCard,
    Address,
    Response
  }

  # ---------------Interface functions to be used by developer for
  #----------------making requests to gateway

  @doc """
    function to authorize the merchant using merchant name
    and transactionKey
  """
  def authenticate(opts) do
    case Keyword.fetch(opts, :config) do
      {:ok, config} ->
        data = add_auth_request(config)
        response_data = commit(:post, data)
        respond(@response_type[:auth_response], response_data)
      {:error, _} -> {:error, "config not found"}
    end
  end
  
  @doc """
    Function to charge a user credit card for the specified amount,
    according to the payment method provided(e.g. credit card, apple pay etc.)
  """
  def purchase(amount, payment, opts) do
    request_data = add_auth_purchase(amount, payment, opts, @transaction_type[:purchase])
    response_data = commit(:post, request_data)
    respond(@response_type[:transaction_response], response_data)
  end

  @doc """
    Use this method to authorize a card payment. To actually charge funds, a follow up with 
    capture method needs to be done.
  """
  def authorize(amount, payment, opts) do
    request_data = add_auth_purchase(amount, payment, opts, @transaction_type[:authorize])
    response_data = commit(:post, request_data)
    respond(@response_type[:transaction_response], response_data)
  end

  @doc """
    Use this method to capture funds for transactions which have been authorized,
    requires transId of the authorize function response to be passed as id along with
    the amount to be captured.
  """
  def capture(amount, id, opts) do
    request_data = normal_capture(amount, id,  opts, @transaction_type[:capture])
    response_data = commit(:post, request_data)
    respond(@response_type[:transaction_response], response_data)
  end

  @doc """
    Use this method to refund a customer for a transaction that was already settled
  """
  def refund(amount, id, opts) do
    request_data = normal_refund(amount, id, opts, @transaction_type[:refund])
    response_data = commit(:post, request_data)
    respond(@response_type[:transaction_response], response_data)
  end

  @doc """
    Use this method to cancel either an original transaction that is not settled or 
    an entire order composed of more than one transaction. It can be submitted against
    any other transaction type. Requires the transId of a request passed as id.
  """
  def void(id, opts) do
    request_data = normal_void(id, opts, @transaction_type[:void])
    response_data = commit(:post, request_data)
    respond(@response_type[:transaction_response], response_data)
  end

  # method to make the api request with params
  defp commit(method, payload) do
    path = @test_url
    headers = @header
    HTTPoison.request(method, path, payload, headers)
  end

  # Function to return a response 
  defp respond(response_type, {:ok, %{body: body, status_code: 200}}) do
    raw_response  = naive_map(body)
    case response_type do
      "authenticateTestResponse" ->
        response_check(raw_response["authenticateTestResponse"], raw_response)
      "createTransactionResponse" -> 
        response_check(raw_response["createTransactionResponse"], raw_response)
    end
  end

  # Functions to send successful and error responses depending on message received 
  # from gateway.
  defp response_check( %{"messages" => %{"resultCode" => "Ok"}}, raw_response) do
        {:ok, Response.success(raw: raw_response)}
  end

  defp response_check( %{"messages" => %{"resultCode" => "Error"}}, raw_response) do
      {:ok, Response.error(raw: raw_response)}
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
      add_merchant_auth(opts)
    ])
    |> generate
  end
  
  #function to format the request for normal refund
  defp normal_refund(amount, id, opts, transaction_type) do
    element(:authenticateTestRequest, %{xmlns: @aut_net_namespace}, [
      add_merchant_auth(opts),
      add_order_id(opts),
      add_refund_transaction_request(amount, id, opts, transaction_type),
    ])
    |> generate
  end

  #function to format the request for normal void operation
  defp normal_void(id, opts, transaction_type) do
    element(:authenticateTestRequest, %{xmlns: @aut_net_namespace}, [
      add_merchant_auth(opts),
      add_order_id(opts),
      element(:transactionRequest, [
        add_transaction_type(transaction_type),
        add_ref_trans_id(id)
      ])
    ])
    |> generate
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
          element(:expirationDate, opts[:payment][:card][:expiration])
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
        element(:cardNumber, source[:number]),
        element(:expirationDate, source[:expiration]),
        element(:cardCode, source[:cvc])
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

end
