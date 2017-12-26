defmodule Gringotts.Gateways.Cams do
  @moduledoc ~S"""
    A module for working with the Cams payment gateway.
    
    You can test gateway operations in [CAMS API TEST MODE](https://secure.centralams.com).
    Test it using these crediantials **username:** `testintegrationc`, **password:** `password9`,
    as well as you can find api docs in this test account under **integration** link.

    The following features of CAMS are implemented:

    | Action                       | Method        |
    | ------                       | ------        |
    | Authorize                    | `authorize/3` |
    | Capture                      | `capture/3`   |
    | Purchase                     | `purchase/3`  |
    | Refund                       | `refund/3`    |
    | Cancel                       | `void/2`      |

  ## The `opts` argument

    Most `Gringotts` API calls accept an optional `Keyword` list `opts` to supply
    optional arguments for transactions with the Cams gateway. The following keys
    are supported:
  
    | Key                 | Remark | Status          |
    | ----                | ---    | ----            |
    | `billing_address`   |        | Not implemented |
    | `address`           |      	 | Not implemented |
    | `currency`          |        | **Implemented** |
    | `order_id`  				 |        | Not implemented |
    | `description`       |        | Not implemented |

    All these keys are being implemented, track progress in
    [issue #42](https://github.com/aviabird/gringotts/issues/42)!

  ## Configuration parameters for Cams:

    | Config parameter | Cams secret   |
    | -------          | ----          |
    | `:username`      | **Username**  |
    | `:password`      | **Password**  |
  
  > Your Application config **must include the `:username`, `:password`
  > fields** and would look something like this: 
   
      config :gringotts, Gringotts.Gateways.Cams,
      adapter: Gringotts.Gateways.Cams,
      username: "your_secret_user_name",
      password: "your_secret_password",
  

  ## Scope of this module, and _quirks_

  * Cams process money in cents.
  * Although Cams supports payments from electronic check & various cards this library only 
  accepts payments by cards like *visa*, *master*, *american_express* and *discover*.

  ## Following the examples
  1. First, set up a sample application and configure it to work with Cams.
      - You could do that from scratch by following our [Getting Started](#) guide.
      - To save you time, we recommend [cloning our example
  repo](https://github.com/aviabird/gringotts_example) that gives you a
  pre-configured sample app ready-to-go.
          + You could use the same config or update it the with your "secrets"
          that you get after registering with Cams.

  2. Run an `iex` session with `iex -S mix` and add some variable bindings and
  aliases to it (to save some time):
  ```
  iex> alias Gringotts.{Response, CreditCard, Gateways.Cams}
  iex> opts = [currency: "USD"] # The default currency is USD, and this is just for an example.
  iex> payment = %CreditCard{number: "4111111111111111", month: 11, year: 2018,
                            first_name: "Longbob", last_name: "Longsen",
                            verification_code: "123", brand: "visa"}
  ```

  We'll be using these in the examples below.

  ## TODO

  * Credit Card Operations
    - Credit

  * Electronic Check
    - Sale
    - Void
    - Refund
  """
  @live_url  "https://secure.centralams.com/gw/api/transact.php"
  @default_currency  "USD"
  @headers  [{"Content-Type", "application/x-www-form-urlencoded"}]
  use Gringotts.Gateways.Base
  use Gringotts.Adapter,
  required_config: [:username, :password, :default_currency]
  alias Gringotts.{CreditCard, Response}
  alias Gringotts.Gateways.Cams.ResponseHandler, as: ResponseParser

  import Poison, only: [decode!: 1]
  @doc """
    Transfers `amount` from the customer to the merchant.

    Function to charge a user credit card for the specified amount. It performs authorize
    and capture at the same time.Purchase transaction are submitted and immediately sent for settlement.
    
    After successful purchase it returns an `authorization` which can be used later to:
    * `refund/3` an amount.
    * `void/2` a transaction(*if Not settled*).

  ## Examples
      payment = %CreditCard{
        number: "4111111111111111", month: 11, year: 2018,
        first_name: "Longbob", last_name: "Longsen",
        verification_code: "123", brand: "visa"
      }

      options = [currency: "USD"]
      money   = 100
      
      iex> Gringotts.purchase(Gringotts.Gateways.Cams, money, payment, options)
  """
  @spec purchase(number, CreditCard.t, Keyword) :: Response
  def purchase(money, payment, options) do
    post = []
          |> add_invoice(money, options)
          |> add_payment(payment)
          |> add_address(payment, options)
    commit("sale", post, options)
  end

  @doc """
    Authorize a credit card transaction.

    The authorization validates the `card` details with the banking network, places a hold on the
    transaction amount in the customer’s issuing bank and also triggers risk management. 
    Funds are not transferred.It needs to be followed up with a capture transaction to transfer the funds 
    to merchant account.After successful capture, transaction will be sent for settlement.
    
    Cams returns an `authorization` which can be used later to:
    * `capture/3` an amount.
    * `void/2` a authorized transaction.


  ## Examples
      payment = %{
        number: "4111111111111111", month: 11, year: 2018,
        first_name: "Longbob", last_name: "Longsen",
        verification_code: "123", brand: "visa"
      }

      options = [currency: "USD"]
      money   = 100
      
      iex> Gringotts.authorize(Gringotts.Gateways.Cams, money, payment, options)
  """
  @spec authorize(number, CreditCard.t, Keyword) :: Response
  def authorize(money, payment, options) do
    post = []
      |> add_invoice(money, options)
      |> add_payment(payment)
      |> add_address(payment, options)
    commit("auth", post, options)
  end

  @doc """
    Captures a pre-authorized amount.

    It captures existing authorizations for settlement.Only authorizations can be captured.
    Captures can be submitted for an amount equal to or less than the original authorization.
    It allows partial captures like many other gateways and release the remaining amount back to 
    the payment source **[citation-needed]**.Multiple captures can not be done using same `authorization`.

  ## Examples

      authorization = "3904093075"
      options = [currency: "USD"]
      money   = 100
      
      iex> Gringotts.capture(Gringotts.Gateways.Cams, money, authorization, options)
  """
  @spec capture(number, String.t, Keyword) :: Response
  def capture(money, authorization, options) do
    post = [transactionid: authorization]
    add_invoice(post, money, options)
    commit("capture", post, options)
  end

  @doc """
    Refunds the `amount` to the customer's account with reference to a prior transfer.

    It will reverse a previously settled or pending settlement transaction.
    If the transaction has not been settled, a transaction `void/2` can also reverse it.
    It processes a full or partial refund worth `amount`, referencing a previous `purchase/3` or `capture/3`.
    Authorized transaction can not be reversed. 

  `authorization` can be used to perform multiple refund, till:
    * all the pre-authorized amount is captured or,
    * the remaining amount is explicitly "reversed" via `void/2`. **[citation-needed]**

  ## Examples

      authorization = "3904093078"
      options = [currency: "USD"]
      money   = 100
      
      iex> Gringotts.refund(Gringotts.Gateways.Cams, money, authorization, options)
  """
  @spec refund(number, String.t, Keyword) :: Response
  def refund(money, authorization, options) do
    post = [transactionid:  authorization]
    add_invoice(post, money, options)
    commit("refund", post, options)
  end

  @doc """
    Voids the referenced payment.
    
    Transaction voids will cancel an existing sale or captured authorization.
    In addition, non-captured authorizations can be voided to prevent any future capture.
    Voids can only occur if the transaction has not been settled.

  ## Examples

      authorization = "3904093075"
      options = []
      
      iex> Gringotts.void(Gringotts.Gateways.Cams, authorization, options)
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
      |> Keyword.put(:currency, (options[:config][:currency]) || @default_currency)
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
    post = post
      |> Keyword.put(:firstname, payment.first_name)
      |> Keyword.put(:lastname, payment.last_name)

    if options[:billing_address] do
      address = options[:billing_address]
      post = post
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
     |> String.pad_leading(2, "0")
  end

  defp commit(action, params, options) do
    url = @live_url
    params = params
      |> Keyword.put(:type, action)
      |> Keyword.put(:password, options[:config][:password])
      |> Keyword.put(:username, options[:config][:username])
      |> params_to_string
    
    url
      |> HTTPoison.post(params, @headers)
      |> ResponseParser.parse
  end

  defmodule ResponseHandler do
    @moduledoc false
    alias Gringotts.Response

    @doc false
    def parse({:ok, %HTTPoison.Response{body: body, status_code: 200}}) do
      body = URI.decode_query(body)
      []
      |> set_authorization(body)
      |> set_success(body)
      |> set_message(body)
      |> set_params(body)
      |> set_error_code(body)
      |> handle_opts()
    end

    defp set_authorization(opts, %{"transactionid" => id}) do
      opts ++ [authorization: id]
    end

    defp set_message(opts, %{"responsetext" => message}) do
      opts ++ [message: message]
    end

    defp set_params(opts, body) do
      opts ++ [params: body]
    end

    defp set_error_code(opts, %{"response_code" => response_code}) do
      opts ++ [error_code: response_code]
    end

    defp set_success(opts, %{"response_code" => response_code}) do
      opts ++ [success: response_code == "100"]
    end
    
    defp handle_opts(opts) do
      {:ok, Response.success(opts)}
    end

  end
end

