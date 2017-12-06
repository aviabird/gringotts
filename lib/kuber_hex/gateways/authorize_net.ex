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

  def authenticate(opts) do
    case Keyword.fetch(opts, :config) do
      {:ok, config} -> 
        data = add_auth_request(config)
        commit(:post, data)
      {:error, _} -> {:error, "config not found"}
    end
  end
  
  def purchase(amount, payment, opts) do
    request_data = add_auth_purchase(amount, payment, opts)
    commit(:post, request_data)
  end

  defp commit(method, payload) do
    path = @test_url
    headers = [{"Content-Type", "text/xml"}]
    HTTPoison.request(method, path, payload, headers)
  end

  def add_auth_purchase(amount, payment, opts) do
    element(:createTransactionRequest,  %{xmlns: @aut_net_namespace}, [
      add_merchant_auth(opts[:config]),
      add_order_id(opts),
      add_transaction_request(amount, @transaction_type[:purchase], payment, opts),
    ])
    |> generate

  end

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
      add_invoice(@transaction_type[:purchase], opts)      
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
end
