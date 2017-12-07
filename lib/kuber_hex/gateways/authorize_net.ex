defmodule Kuber.Hex.Gateway.AuthorizeNet do
  import XmlBuilder
  
  @test_url "https://apitest.authorize.net/xml/v1/request.api"
  @production_url "https://api.authorize.net/xml/v1/request.api"
  @transaction_type %{
    purchase: "authCaptureTransaction"
  }
  @aut_net_namespace "AnetApi/xml/v1/schema/AnetApiSchema.xsd"

  alias Kuber.Hex.{
    CreditCard,
    Address,
    Response
  }
  @doc """
    function to authorize the merchant using merchant name 
    and transactionKey
  """
  def authenticate(opts) do
    case Keyword.fetch(opts, :config) do
      {:ok, config} ->
        data = add_auth_request(config)
        commit(:post, data)
      {:error, _} -> {:error, "config not found"}
    end
  end
  
  @doc """
    function to charge a user credit card for the specified amount,
    according to the payment method provided(e.g. credit card, apple pay etc.)
  """
  def purchase(amount, payment, opts) do
    request_data = add_auth_purchase(amount, payment, opts)
    commit(:post, request_data)
  end

  # method to make the api request with params
  defp commit(method, payload) do
    path = @test_url
    headers = [{"Content-Type", "text/xml"}]
    HTTPoison.request(method, path, payload, headers)
  end

  # function for formatting the request as an xml for purchase method
  defp add_auth_purchase(amount, payment, opts) do
    element(:createTransactionRequest,  %{xmlns: @aut_net_namespace}, [
      add_merchant_auth(opts[:config]),
      add_order_id(opts),
      add_transaction_request(amount, @transaction_type[:purchase], payment, opts),
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

  defp add_merchant_auth(opts) do
    element(:merchantAuthentication, [
      element(:name, opts[:name]),
      element(:transactionKey, opts[:transactionKey])
    ])
  end

  defp add_order_id(opts) do
    element(:refId, opts[:refId])
  end

  defp add_transaction_request(amount, transaction_type ,payment, opts) do
    element(:transactionRequest, [
      add_transaction_type(transaction_type),
      add_amount(amount),
      add_payment_source(payment),
      add_invoice(@transaction_type[:purchase], opts),
      add_tax_fields(opts),
      add_duty_fields(opts),
      add_shipping_fields(opts),
      add_po_number(opts),
      add_customer_info(opts)
    ])
  end

  defp add_transaction_type(transaction_type) do 
    element(:transactionType, transaction_type)
  end

  defp add_amount(amount) do
    element(:amount, amount)
  end

  defp add_payment_source(source) do
    # have to implement for other sources like apple pay
    # token payment method and check currently only for credit card
    add_credit_card(source)
  end

  defp add_credit_card(source) do
    element(:payment, [
      element(:creditCard, [
        element(:number, source[:number]),
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
      element(:amount, opts[:tax][:amount]),
      element(:name, opts[:tax][:amount]),
      element(:description, opts[:tax][:description]),
    ])
  end

  defp add_duty_fields(opts) do
    element(:duty, [
      element(:amount, opts[:duty][:amount]),
      element(:name, opts[:duty][:amount]),
      element(:description, opts[:duty][:description]),
    ])
  end

  defp add_shipping_fields(opts) do
    element(:shipping, [
      element(:amount, opts[:shipping][:amount]),
      element(:name, opts[:shipping][:amount]),
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
