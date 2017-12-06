import XmlBuilder
defmodule Kuber.Hex.Gateways.WireCard do
  @test_url "https://c3-test.wirecard.com/secure/ssl-gateway"
  @live_url "https://c3.wirecard.com/secure/ssl-gateway"
  @homepage_url "http://www.wirecard.com"
  @envelope_namespaces %{
    "xmlns:xsi" => "http://www.w3.org/1999/XMLSchema-instance",
    "xsi:noNamespaceSchemaLocation" => "wirecard.xsd"
  }

  @permited_transactions ~w[ PREAUTHORIZATION CAPTURE PURCHASE ]

  @return_codes ~w[ ACK NOK ]
  # Wirecard only allows phone numbers with a format like this: +xxx(yyy)zzz-zzzz-ppp, where:
  #   xxx = Country code
  #   yyy = Area or city code
  #   zzz-zzzz = Local number
  #   ppp = PBX extension
  # For example, a typical U.S. or Canadian number would be "+1(202)555-1234-739" indicating PBX extension 739 at phone
  # number 5551234 within area code 202 (country code 1).
  @valid_phone_format ~r/\+\d{1,3}(\(?\d{3}\)?)?\d{3}-\d{4}-\d{3}/

  @supported_cardtypes [ :visa, :master, :american_express, :diners_club, :jcb, :switch ]
  @supported_countries ~w(AD CY GI IM MT RO CH AT DK GR IT MC SM TR BE EE HU LV NL SK GB BG FI IS LI NO SI VA FR IL LT PL ES CZ DE IE LU PT SE)
  @display_name      "Wirecard"
  @default_currency  "EUR"
  @money_format      :cents

  use Kuber.Hex.Gateways.Base
  
  alias Kuber.Hex.{
    CreditCard,
    Address,
    Response
  }
  
  import Poison, only: [decode!: 1]

  # Authorization - the second parameter may be a CreditCard or
  # a String which represents a GuWID reference to an earlier
  # transaction.  If a GuWID is given, rather than a CreditCard,
  # then then the :recurring option will be forced to "Repeated"
  # ===========================================================
  # TODO: Mandatorily check for :login,:password, :signature in options
  # Note: payment_menthod for now is only credit_card and 
  # TODO: change it so it can also have GuWID
  # ================================================
  # E.g: => 
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
  # options = %{
  #   login: "00000031629CA9FA",
  #   password: "TestXAPTER",
  #   signature: "00000031629CAFD5",
  #   order_id: 1,
  #   billing_address: address,
  #   description: 'Wirecard remote test purchase',
  #   email: 'soleone@example.com',
  #   ip: '127.0.0.1'
  # }
  def authorize(money, payment_method, options \\ %{}) do
    options = options |> Map.put(:credit_card, payment_method)
    commit(:preauthorization, money, options)
  end

  # =================== Private Methods =================== 
  # Contact WireCard, make the XML request, and parse the
  # reply into a Response object
  defp commit(action, money, options) do
    #TODO: validate and setup address hash as per AM
    request = build_request(action, money, options)
    
    headers = %{ "Content-Type" => "text/xml",
    "Authorization" => encoded_credentials(options[:login], options[:password]) }
  end
  
  # Generates the complete xml-message, that gets sent to the gateway
  defp build_request(action, money, options) do
    options = options |> Map.put(:action, action)

    request = doc(element(:WIRECARD_BXML, [
        element(:W_REQUEST, [
          element(:W_JOB, [
            element(:JobID, ''),
            element(:BusinessCaseSignature, "12121212121212"),
            add_transaction_data(action, money, options)
          ])
        ])
      ]))
    File.write!("./xml_out.xml", request, [:write])
  end

  # Includes the whole transaction data (payment, creditcard, address)
  # TODO: Add order_id to options if not present, see AM
  # TOOD: Clean description before passing it to FunctionID, replace dummy
  def add_transaction_data(action, money, options) do
    element("FNC_CC_#{options[:action] |> atom_to_upcase_string}", [
      element(:FunctionID, "dummy_description"),
      element(:CC_TRANSACTION, [
        element(:TransactionID, options[:order_id]),
        element(:CommerceType, (if options[:commerce_type], do: options[:commerce_type]))      
      ] ++ add_action_data(action, money, options))
    ])
  end

  def add_action_data(action, money, options) do
    case options[:action] do
      # returns array of elements
      action when(action in [:preauthorization, :purchase, :authorization_check]) -> create_elems_for_preauth_or_purchase_or_auth_check(action, money, options)
    end
  end

  # Creates xml request elements if action is preauth, purchase ir auth_check 
  defp create_elems_for_preauth_or_purchase_or_auth_check(action, money, options) do
    # TODO: setup_recurring_flag
    [add_invoice(money, options) | element_for_credit_card_or_guwid(options)]
  end
  
  defp element_for_credit_card_or_guwid(options) do
    if options[:credit_card] do
      add_creditcard(options[:credit_card])
    else
      [element(:GuWID, options[:preauthorization])]
    end
  end
  
  # Includes the credit-card data to the transaction-xml
  # TODO: Format Credit Card month, ref AM
  defp add_creditcard(creditcard) do
    [element(:CREDIT_CARD_DATA, [
      element(:CreditCardNumber, creditcard.number),
      element(:CVC2, creditcard.verification_value),
      element(:ExpirationYear, creditcard.year),
      element(:ExpirationMonth, creditcard.month),
      element(:CardHolderName, join_string([creditcard.first_name, creditcard.last_name], " "))
    ])]
  end


  # Includes the payment (amount, currency, country) to the transaction-xml
  defp add_invoice(money, options) do
    [
      add_amount(money, options),
      element(:Currency, options[:currency] || @default_currency),
      element(:CountryCode, options[:billing_address][:country]),
      element(:RECURRING_TRANSACTION, [
        element(:Type, options[:recurring] || "Single")
      ])
    ]
  end
  
  # Include the amount in the transaction-xml
  # TODO: check for localized currency or currency
  # localized_amount(money, options[:currency] || currency(money))
  defp add_amount(money, options) do
    element(:Amount, money)
  end

  defp atom_to_upcase_string(atom) do
    String.upcase to_string atom
  end

  # Encode login and password in Base64 to supply as HTTP header
  # (for http basic authentication)
  defp encoded_credentials(login, password) do
    join_string([login, password], ":")
    |> Base.encode64 
    |> (&( "Basic "<> &1)).()
  end

  defp join_string(list_of_words, joiner) do
    Enum.join(list_of_words, joiner)
  end
end
