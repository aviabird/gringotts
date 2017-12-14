defmodule Kuber.Hex.Gateways.Cams do
    @live_url  "https://secure.centralams.com/gw/api/transact.php"
    @supported_countries  "US"
    @default_currency  "USD"
    @supported_cardtypes  [:visa, :master, :american_express, :discover]
    @homepage_url  "https://www.centralams.com/"
    @display_name  "CAMS: Central Account Management System"
  
    # @stande_Error_Code_Mapping %{
    #     "200" => "card_declined",
    #     "201" => Standerd_Error_Code[:card_declined],
    #     "202" => Standerd_Error_Code[:card_declined],
    #     "203" => Standerd_Error_Code[:card_declined],
    #     "204" => Standerd_Error_Code[:card_declined],
    #     "220" => Standerd_Error_Code[:card_declined],
    #     "221" => Standerd_Error_Code[:card_declined],
    #     "222" => Standerd_Error_Code[:incorrect_number],
    #     "223" => Standerd_Error_Code[:expired_card],
    #     "224" => Standerd_Error_Code[:invalid_expiry_date],
    #     "225" => Standerd_Error_Code[:invalid_cvc],
    #     "240" => Standerd_Error_Code[:call_issuer],
    #     "250" => Standerd_Error_Code[:pickup_card],
    #     "251" => Standerd_Error_Code[:pickup_card],
    #     "252" => Standerd_Error_Code[:pickup_card],
    #     "253" => Standerd_Error_Code[:pickup_card],
    #     "260" => Standerd_Error_Code[:card_declined],
    #     "261" => Standerd_Error_Code[:card_declined],
    #     "262" => Standerd_Error_Code[:card_declined],
    #     "263" => Standerd_Error_Code[:processing_error],
    #     "264" => Standerd_Error_Code[:card_declined],
    #     "300" => Standerd_Error_Code[:card_declined],
    #     "400" => Standerd_Error_Code[:processing_error],
    #     "410" => Standerd_Error_Code[:processing_error],
    #     "411" => Standerd_Error_Code[:processing_error],
    #     "420" => Standerd_Error_Code[:processing_error],
    #     "421" => Standerd_Error_Code[:processing_error],
    #     "430" => Standerd_Error_Code[:processing_error],
    #     "440" => Standerd_Error_Code[:processing_error],
    #     "441" => Standerd_Error_Code[:processing_error],
    #     "460" => Standerd_Error_Code[:invalid_number],
    #     "461" => Standerd_Error_Code[:processing_error],
    #     "801" => Standerd_Error_Code[:processing_error],
    #     "811" => Standerd_Error_Code[:processing_error],
    #     "812" => Standerd_Error_Code[:processing_error],
    #     "813" => Standerd_Error_Code[:processing_error],
    #     "814" => Standerd_Error_Code[:processing_error],
    #     "815" => Standerd_Error_Code[:processing_error],
    #     "823" => Standerd_Error_Code[:processing_error],
    #     "824" => Standerd_Error_Code[:processing_error],
    #     "881" => Standerd_Error_Code[:processing_error],
    #     "882" => Standerd_Error_Code[:processing_error],
    #     "883" => Standerd_Error_Code[:processing_error],
    #     "884" => Standerd_Error_Code[:card_declined],
    #     "885" => Standerd_Error_Code[:card_declined],
    #     "886" => Standerd_Error_Code[:card_declined],
    #     "887" => Standerd_Error_Code[:processing_error],
    #     "888" => Standerd_Error_Code[:processing_error],
    #     "889" => Standerd_Error_Code[:processing_error],
    #     "890" => Standerd_Error_Code[:processing_error],
    #     "891" => Standerd_Error_Code[:incorrect_cvc],
    #     "892" => Standerd_Error_Code[:incorrect_cvc],
    #     "893" => Standerd_Error_Code[:processing_error],
    #     "894" => Standerd_Error_Code[:processing_error]
    # }
  
  
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
      IO.inspect(options)
      commit("auth", post, options)
    end
  
    def capture(money, authorization, options) do
        post = []
        post = post
                  |> extract_auth(authorization)
                  |> add_invoice(money,options)
      commit("capture", post, options)
    end
  
    def refund(money, authorization, options) do
      post = []
       post = post
                |> extract_auth(authorization)
                |> add_invoice(money, options)
      commit("refund" , post, options)
   end
    
    def void(authorization , options) do
      post = []
      post = extract_auth(post, authorization)
      commit("void" , post, options)
    end

    def verify(credit_card, options) do
      post = []
      post = post
            |> add_invoice( 0, options)
            |> add_payment(credit_card)
            |> add_address(credit_card, options)
      commit("verify", post, options)
    end
  
    # private methods
    
    defp add_invoice(post, money, options) do
      post = post |> Keyword.put(:amount, money) 
                  |> Keyword.put(:currency,(options[:currency] || @default_currency))
      post
    end
  
    defp add_payment(post, payment) do   
      exp_month = join_month(payment) 
      exp_year = payment.year |> to_string() |> String.slice(-2..-1)
      post = post 
            |> Keyword.put(:ccnumber, payment.number)
            |> Keyword.put(:ccexp, "#{exp_month}#{exp_year}")
            |> Keyword.put(:cvv, payment.verification_code)
      post
    end
  
    defp add_address(post, payment, options) do
      post = post|> Keyword.put(:firstname, payment.first_name)
                 |> Keyword.put(:lastname, payment.last_name)
  
      if(options[:billing_address]) do
        address = options[:billing_address]
        post = post |> Keyword.put(:address1 , address[:address1])
                    |> Keyword.put(:address2, address[:address2])
                    |> Keyword.put(:city, address[:city])
                    |> Keyword.put(:state, address[:state])
                    |> Keyword.put(:zip, address[:zip])
                    |> Keyword.put(:country, address[:country])
                    |> Keyword.put(:phone, address[:phone])      
        post            
      end
      post
    end
  
    # TODO: use case or when clasue instead of if 
    # elixir way of doing
    defp join_month(payment) do
      exp_month = payment.month |> to_string
      if(String.length(exp_month) <= 1) do
        exp_month = "0" <> exp_month
      end
      exp_month
    end
  
    # TODO: 
    # add new method called respond and do pattern matching based on response
    # e.g => { :ok, response } or { :error, error_response }
    defp commit(action, params, options) do 
      url = @live_url
      params = params|> Keyword.put(:type, action)
                     |> Keyword.put(:password, options[:config][:password])
                     |> Keyword.put(:username, options[:config][:username])
                     |> params_to_string
                    #  options[:config][:login]
      headers = [
        { "Content-Type", "application/x-www-form-urlencoded" }
      ]
      response = HTTPoison.post(url, params, headers)
      IO.inspect(response)
      {:ok, res} = response #pattern Match
      
      res.body
    end
  
    defp extract_auth(post,authorization) do
      response_body = URI.decode_query(authorization)
      post = Keyword.put([],:transactionid,String.to_integer(response_body["transactionid"]))
             |> Keyword.put(:authcode, String.to_integer(response_body["authcode"]))  
    end
  end
  