defmodule Kuber.Hex.Gateways.Cams do
    @live_url  "https://secure.centralams.com/gw/api/transact.php"
    @supported_countries  ["US"]
    @default_currency  "USD"
    @supported_cardtypes  [:visa, :master, :american_express, :discover]
    @homepage_url  "https://www.centralams.com/"
    @display_name  "CAMS: Central Account Management System"
    @headers = [{"Content-Type", "application/x-www-form-urlencoded"}]
  

    use Kuber.Hex.Gateways.Base
    use Kuber.Hex.Adapter, required_config: [:username, :password, :default_currency]
    alias Kuber.Hex.{
      CreditCard,
      Address,
      Response
    }
      @doc """
          payment = %CreditCard{
          number: "4111111111111111",
          month: 11,
          year: 2018,
          first_name: "Longbob",
          last_name: "Longsen",
          verification_code: "123",
          brand: "visa"
        }
        credit_card = %CreditCard{
          number: "4242424242424242",
          month: 11,
          year: 2018,
          first_name: "Longbob",
          last_name: "Longsen",
          verification_code: "123",
          brand: "visa"
        }
        address = %{
          name:     "Jim Smith",
          address1: "456 My Street",
          address2: "Apt 1",
          company:  "Widgets Inc",
          city:     "Ottawa",
          state:    "ON",
          zip:      "K1C2N6",
          country:  "CA",
          phone:    "(555)555-5555",
          fax:      "(555)555-6666"
        }
        options = [
          config: %{
                    username: "testintegrationc",
                    password: "password9"
                  },
          order_id: 1,
          billing_address: address,
          description: "Store Purchase",
        ]
    """
    import Poison, only: [decode!: 1]
  
    def purchase(money, payment, options) do
      #consider this as creditcard payment only for now.
      post = []
            |> add_invoice(money, options)
            |> add_payment(payment)
            |> add_address(payment, options)
      commit("sale", post, options)
    end
  
    def authorize(money, payment, options) do
      post = []
        |> add_invoice(money, options)
        |> add_payment(payment)
        |> add_address(payment, options)
      commit("auth", post, options)
    end
  
    def capture(money, authorization, options) do
      post = []
             |> extract_auth(authorization)
             |> add_invoice(money,options)
      commit("capture", post, options)
    end
  
    def refund(money, authorization, options) do
      post = []
             |> extract_auth(authorization)
             |> add_invoice(money, options)
      commit("refund", post, options)
    end
    
    def void(authorization , options) do  
      post = extract_auth([], authorization)
      commit("void", post, options)
    end

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
  