defmodule Gringotts.Gateways.Cams do
  @moduledoc ~S"""
    An API client for the [CAMS](https://www.centralams.com/) gateway.
    For referance you can test gateway operations [CAMS API SANDBOX] (https://secure.centralams.com).

    Test it using test crediantials username:***testintegrationc***, password:***password9***

    The following features of CAMS are implemented:

    * **Purchase**  In  `purchase/3`

    * **Authorize** In  `authorize/3`

    * **Capture**   In  `capture/3`

    * **Refund**    In  `refund/3`

    * **Void**      In  `void/2`
  """
  @live_url  "https://secure.centralams.com/gw/api/transact.php"
  @default_currency  "USD"
  @headers  [{"Content-Type", "application/x-www-form-urlencoded"}]
  
  use Gringotts.Gateways.Base
  use Gringotts.Adapter, required_config: [:username, :password, :default_currency]
  alias Gringotts.{
  CreditCard,
  Address,
  Response
  }
      
  import Poison, only: [decode!: 1]
   
  @doc """
    Use this method for performing purchase(sale) operation. 

    It perform operation by taking `money`, `payment`(credit card details) & `options` as parameters.
    Here `money` is required field which contains amount to be deducted. 
    Required fields in credit card are `Credit Card Number` & `Expiration Date`.
    Whereas `options` contains other information like billing address,order information etc. 
    After successful transaction it returns response containing **transactionid**.

  ## Examples
      payment = %{
        number: "4111111111111111", month: 11, year: 2018,
        first_name: "Longbob", last_name: "Longsen",
        verification_code: "123", brand: "visa"
      }

      options = [currency: "USD"]
      money   = 100
      
      iex> Gringotts.purchase(:payment_worker, Gringotts.Gateways.Cams, money, payment, options)
  """
  @spec purchase(number, CreditCard, Keyword) :: Response
  def purchase(money, payment, options) do
    post = []
          |> add_invoice(money, options)
          |> add_payment(payment)
          |> add_address(payment, options)
          
    response = commit("sale", post, options)
    {:ok, response} = response
    extract_auth([], response)  
  end

  @doc """
    Use this method for authorizing the credit card for particular transaction. 

    `authorize/3` method only authorize the transaction,it does not transfer the funds.
    After authorized a transaction, we need to call `capture/3` method to complete the transaction.
    After successful authorization it returns response containing **transactionid**.
    We required **transactionid** and **money** for capturing transaction later on.
    It perform operation by taking `money`, `payment` (credit card details) & `options` as parameters.
    Here `money` is required field which contains amount to be deducted. 
    Required fields in credit card are `Credit Card Number` & `Expiration Date`.
    Whereas `options` contains other information like billing address,order information etc. 
    
  ## Examples
      payment = %{
        number: "4111111111111111", month: 11, year: 2018,
        first_name: "Longbob", last_name: "Longsen",
        verification_code: "123", brand: "visa"
      }

      options = [currency: "USD"]
      money   = 100
      
      iex> Gringotts.authorize(:payment_worker, Gringotts.Gateways.Cams, money, payment, options)
  """
  @spec authorize(number, CreditCard, Keyword) :: Response
  def authorize(money, payment, options) do
    post = []
      |> add_invoice(money, options)
      |> add_payment(payment)
      |> add_address(payment, options)

     response = commit("auth", post, options)
     {:ok, response} = response
     extract_auth([], response)    
  end
 
  @doc """
    Use this method for capture the amount of the authorized transaction which is previously authorized by `authorize/3` method.

    It takes `money`, `authorization` and `options` as parameters.
    Where `money` is a amount to be captured and `authorization` is a response returned by `authorize/3` method.
    From response it takes `transactionid` for further processing. 
    Both `money` and `authorization` are required fields, whereas `options` are as same as `authorize/3` and `purchase/3` methods.
  
  
  ## Examples

      authorization = "3904093075"
      options = [currency: "USD"]
      money   = 100
      
      iex> Gringotts.capture(:payment_worker, Gringotts.Gateways.Cams, money, authorization, options)
  """
  @spec capture(number, String.t, Keyword) :: Response
  def capture(money, authorization, options) do
    post = [transactionid: authorization] 
    add_invoice(post, money,options)
    commit("capture", post, options)
  end
 
  @doc """
    Use this method for refund the amount for particular transaction. 

    Successful transaction can be refunded after settlement or any time.
    It requires *transactionid* for refund the specified amount back to authorized payment source. 
    Only purchased(sale) transactions can be refund based on thier `transactionid`.
    It takes `money`, `authorization` and `options` as parameters.
    Where `money` is a amount to be refund and `authorization` is a response returned by `purchase/3` method.
    From response it takes `transactionid` for further processing. 
    Both `money` and `authorization` are required fields, whereas `options` are as same as `authorize/3`, `purchase/3` and `capture/3` methods.

  ## Examples

      authorization = "3904093078"
      options = [currency: "USD"]
      money   = 100
      
      iex> Gringotts.refund(:payment_worker, Gringotts.Gateways.Cams, money, authorization, options)
  """
  @spec refund(number, String.t, Keyword) :: Response
  def refund(money, authorization, options) do
    post = [transactionid: authorization] 
    add_invoice(post, money,options)
    commit("refund", post, options)
  end

  @doc """
    Use this method for cancel the transaction.
    
    It is use to cancel the purchase(sale) transaction before settlement.
    Authorised transaction can be canceled, but once it captured, it can not be canceled.
    It requires `transactionid` to cancle transaction.Amount is returned to the authorized payment source.
  ## Examples

      authorization = "3904093075"
      options = []
      
      iex> Gringotts.void(:payment_worker, Gringotts.Gateways.Cams, authorization, options)
  """
  @spec void(String.t, Keyword) :: Response
  def void(authorization , options) do  
    post = [transactionid: authorization] 
    commit("void", post, options)
  end

  # private methods
  
  defp add_invoice(post, money, options) do
    post  
    |> Keyword.put(:amount, money) 
    |> Keyword.put(:currency,(options[:currency] || @default_currency))
  end

  defp add_payment(post, payment) do   
    exp_month = join_month(payment) 
    exp_year = payment.year 
               |> to_string() 
               |> String.slice(-2..-1)
    post 
    |> Keyword.put(:ccnumber, payment.number)
    |> Keyword.put(:ccexp, "#{exp_month}#{exp_year}")
    |> Keyword.put(:cvv, payment.verification_code)
  end

  defp add_address(post, payment, options) do
    post
    |> Keyword.put(:firstname, payment.first_name)
    |> Keyword.put(:lastname, payment.last_name)

    if(options[:billing_address]) do
      address = options[:billing_address]
      post
      |> Keyword.put(:address1 , address[:address1])
      |> Keyword.put(:address2, address[:address2])
      |> Keyword.put(:city, address[:city])
      |> Keyword.put(:state, address[:state])
      |> Keyword.put(:zip, address[:zip])
      |> Keyword.put(:country, address[:country])
      |> Keyword.put(:phone, address[:phone])      
    end
  end

  defp join_month(payment) do
     payment.month 
     |> to_string
     |> String.pad_leading(2,"0")
  end

  defp commit(action, params, options) do 
    url = @live_url
    params = params
             |> Keyword.put(:type, action)
             |> Keyword.put(:password, options[:config][:password])
             |> Keyword.put(:username, options[:config][:username])
             |> params_to_string
                 
    HTTPoison.post(url, params, @headers)
    |>respond
  end

  defp respond({:ok, %{body: body, status_code: 200}}) do
    {:ok, body}
  end

  defp respond({:error, %HTTPoison.Error{reason: reason}}) do
      { :error, "Some error has been occurred" }
  end

  defp extract_auth(post, response) do
    response_body = URI.decode_query(response)
    response_body["transactionid"]
  end
end
