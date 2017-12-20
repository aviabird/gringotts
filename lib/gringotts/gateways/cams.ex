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
  
    * **Verify**    In  `verify/2`
  """
  @live_url  "https://secure.centralams.com/gw/api/transact.php"
  @supported_countries  ["US"]
  @default_currency  "USD"
  @supported_cardtypes  [:visa, :master, :american_express, :discover]
  @homepage_url  "https://www.centralams.com/"
  @display_name  "CAMS: Central Account Management System"
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
    After successful transaction it returns response containing **authcode** & **transactionid**.
  """
  @spec purchase(number, CreditCard, Keyword) :: Response
  def purchase(money, payment, options) do
    post = []
          |> add_invoice(money, options)
          |> add_payment(payment)
          |> add_address(payment, options)
    commit("sale", post, options)
  end

  @doc """
    Use this method for authorising the credit card for particular transaction. 


    `authorize/3` method only authorise the transaction,it does not transfer the funds.
    After authorised a transaction, we need to call `capture/3` method to complete the transaction.
    After successful authorisation it returns response containing **authcode** and **transactionid**.
    We required **authcode**,**transactionid** and **money** for capturing transaction later on.
    It perform operation by taking `money`, `payment` (credit card details) & `options` as parameters.
    Here `money` is required field which contains amount to be deducted. 
    Required fields in credit card are `Credit Card Number` & `Expiration Date`.
    Whereas `options` contains other information like billing address,order information etc. 
  """
  @spec authorize(number, CreditCard, Keyword) :: Response
  def authorize(money, payment, options) do
    post = []
      |> add_invoice(money, options)
      |> add_payment(payment)
      |> add_address(payment, options)
    commit("auth", post, options)
  end
 
  @doc """
    Use this method for capture the amount of the authorised transaction which is previously authorised by `authorize/3` method.


    It take `money`, `authorization` and `options` as parameters.
    Where `money` is a amount to be captured and `authorization` is a response returned by `authorize/3` method.
    From response it takes `authcode` and `transactionid` for further processing. 
    Both *money* and *authorization* are required fields, whereas `options` are as same as `authorize/3` and `purchase/3` methods.
  """
  @spec capture(number, String.t, Keyword) :: Response
  def capture(money, authorization, options) do
    post = []
           |> extract_auth(authorization)
           |> add_invoice(money,options)
    commit("capture", post, options)
  end
 
  @doc """
    Use this method for refund the amount for particular transaction. 

    
    Successful transaction can be refunded after settlement or any time.
    It requires *transactionid* for refund the specified amount back to authorized payment source. 
    Only purchased(sale) transactions can be refund based on thier `transactionid`.
    It take `money`, `authorization` and `options` as parameters.
    Where `money` is a amount to be refund and `authorization` is a response returned by `purchase/3` method.
    From response it takes `authcode` and `transactionid` for further processing. 
    Both *money* and *authorization* are required fields, whereas `options` are as same as `authorize/3`, `purchase/3` and `capture/3` methods.
  """
  @spec refund(number, String.t, Keyword) :: Response
  def refund(money, authorization, options) do
    post = []
           |> extract_auth(authorization)
           |> add_invoice(money, options)
    commit("refund", post, options)
  end

  @doc """
    Use this method for cancel the transaction.
    
    
    It is use to cancel the purchase(sale) transaction before settlement.
    Authorised transaction can be canceled, but once it captured, it can not be canceled.
    It requires *transactionid* to cancle transaction.Amount returned to the authorized payment source.
  """
  @spec void(String.t, Keyword) :: Response
  def void(authorization , options) do  
    post = extract_auth([], authorization)
    commit("void", post, options)
  end

  @doc """
  This mehthod is for only verification purpose for credit card.
  Here we need to provide CreditCard info. 
  """
  @spec verify(CreditCard, Keyword) :: Response
  def verify(credit_card, options) do
    post = []
          |> add_invoice( 0, options)
          |> add_payment(credit_card)
          |> add_address(credit_card, options)
    commit("verify", post, options)
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

  defp extract_auth(post,authorization) do
    response_body = URI.decode_query(authorization)
    Keyword.put([],:transactionid,String.to_integer(response_body["transactionid"]))
    |> Keyword.put(:authcode, String.to_integer(response_body["authcode"]))  
  end
end
# payment = %CreditCard{
#   number: "4111111111111111",
#   month: 11,
#   year: 2018,
#   first_name: "Longbob",
#   last_name: "Longsen",
#   verification_code: "123",
#   brand: "visa"
# }
# credit_card = %CreditCard{
#   number: "4242424242424242",
#   month: 11,
#   year: 2018,
#   first_name: "Longbob",
#   last_name: "Longsen",
#   verification_code: "123",
#   brand: "visa"
# }
# address = %{
#   name:     "Jim Smith",
#   address1: "456 My Street",
#   address2: "Apt 1",
#   company:  "Widgets Inc",
#   city:     "Ottawa",
#   state:    "ON",
#   zip:      "K1C2N6",
#   country:  "CA",
#   phone:    "(555)555-5555",
#   fax:      "(555)555-6666"
# }
# options = [
#   config: %{
#             username: "testintegrationc",
#             password: "password9"
#           },
#   order_id: 1,
#   billing_address: address,
#   description: "Store Purchase",
# ] 