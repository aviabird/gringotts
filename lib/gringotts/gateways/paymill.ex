defmodule Gringotts.Gateways.Paymill do
  @moduledoc """
  An Api Client for the [PAYMILL](https://www.paymill.com/) gateway.

  For refernce see [PAYMILL's API (v2.1) documentation](https://developers.paymill.com/API/index)

  The following features of PAYMILL are implemented:

  | Action                       | Method        |
  | ------                       | ------        |
  | Authorize                    | `authorize/3` |
  | Capture                      | `capture/3`   |
  | Purchase                     | `purchase/3`  |
  | Void                         | `void/2`      |

  Following fields are required for config

  | Config Parameter | PAYMILL secret       |
  | private_key      | **your_private_key** |
  | public_key       | **your_public_key**  |

  Your application config must include 'private_key', 'public_key'

      config :gringotts, Gringotts.Gateways.Paymill,
        adapter: Gringotts.Gateways.Paymill,
        private_key: "your_privat_key",
        public_key: "your_public_key"
  """
  use Gringotts.Gateways.Base
  alias Gringotts.{ CreditCard, Address, Response}
  alias Gringotts.Gateways.Paymill.ResponseHandler, as: ResponseParser

  use Gringotts.Adapter, required_config: [:private_key, :public_key]

  @home_page "https://paymill.com"
  @money_format :cents
  @default_currency "EUR"
  @live_url "https://api.paymill.com/v2.1/"
  @headers [{"Content-Type", "application/x-www-form-urlencoded"}]

  @doc """
  Authorize a card with particular amount and return a token in response

  ### Example
      amount = 100

      card = %CreditCard{
        first_name: "Sagar",
        last_name: "Karwande",
        number: "4111111111111111",
        month: 12,
        year: 2018,
        verification_code: 123
      }

      options = []

      iex> Gringotts.authorize(:payment_worker, Gringotts.Gateways.Paymill, amount, card, options)
  """
  @spec authorize(number, String.t | CreditCard, Keyword) :: {:ok | :error, Response}
  def authorize(amount, card_or_token, options) do
    Keyword.put(options, :money, amount)
    action_with_token(:authorize, amount, card_or_token, options)
  end

  @doc """
  Purchase with a card

  ### Example
      amount = 100

      card = %CreditCard{
        first_name: "Sagar",
        last_name: "Karwande",
        number: "4111111111111111",
        month: 12,
        year: 2018,
        verification_code: 123
      }

      options = []

      iex> Gringotts.purchase(:payment_worker, Gringotts.Gateways.Paymill, amount, card, options)
  """
  @spec purchase(number, CreditCard, Keyword) :: {:ok | :error, Response}
  def purchase(amount, card, options) do
    Keyword.put(options, :money, amount)
    action_with_token(:purchase, amount, card, options)
  end

  @doc """
  Capture a particular amount with authorization token

  ### Example
      amount = 100

      token = "preauth_14c7c5268eb155a599f0"

      options = []

      iex> Gringotts.capture(:payment_worker, Gringotts.Gateways.Paymill, token, amount, options)
  """
  @spec capture(String.t, number, Keyword) :: {:ok | :error, Response}
  def capture(authorization, amount, options) do
    post = add_amount([], amount, options) ++ [{"preauthorization", authorization}]

    commit(:post, "transactions", post, options)
  end

  @doc """
  Voids a particular authorized amount

  ### Example
      token = "preauth_14c7c5268eb155a599f0"

      options = []

      iex> Gringotts.void(:payment_worker, Gringotts.Gateways.Paymill, token, options)
  """
  @spec void(String.t, Keyword) :: {:ok | :error, Response}
  def void(authorization, options) do
    commit(:delete, "preauthorizations/#{authorization}", [], options)
  end

  @doc false
  @spec authorize_with_token(number, String.t, Keyword) :: term
  def authorize_with_token(money, card_token, options) do
    post = add_amount([], money, options) ++ [{"token", card_token}]

    commit(:post, "preauthorizations", post, options)
  end

  @doc false
  @spec purchase_with_token(number, String.t, Keyword) :: term
  def purchase_with_token(money, card_token, options) do
    post = add_amount([], money, options) ++ [{"token", card_token}]

    commit(:post, "transactions", post, options)
  end

  @spec save_card(CreditCard, Keyword) :: Response
  defp save_card(card, options) do
    {:ok, %HTTPoison.Response{body: response}} = HTTPoison.get(
        get_save_card_url(),
        get_headers(options),
        params: get_save_card_params(card, options))

     parse_card_response(response)
  end

  @spec save(CreditCard, Keyword) :: Response
  defp save(card, options) do
    save_card(card, options)
  end

  defp action_with_token(action, amount, "tok_" <> id = card_token, options) do
    apply(__MODULE__, String.to_atom("#{action}_with_token"), [amount, card_token , options])
  end

  defp action_with_token(action, amount, %CreditCard{} = card, options) do
    {:ok, response} = save_card(card, options)
    card_token = get_token(response)

    apply(__MODULE__, String.to_atom("#{action}_with_token"), [amount, card_token , options])
  end

  defp get_save_card_params(card, options) do
    [ {"transaction.mode" , "CONNECTOR_TEST"},
      {"channel.id" , get_config(:public_key, options)},
      {"jsonPFunction" , "jsonPFunction"},
      {"account.number" , card.number},
      {"account.expiry.month" , card.month},
      {"account.expiry.year" , card.year},
      {"account.verification" , card.verification_code},
      {"account.holder" , "#{card.first_name} #{card.last_name}"},
      {"presentation.amount3D" , get_amount(options)},
      {"presentation.currency3D" , get_currency(options)}
    ]
  end

  defp get_headers(options) do
    @headers ++ set_username(options)
  end

  defp add_amount(post, money, options) do
    post ++ [{"amount", money}, {"currency", @default_currency}]
  end

  defp set_username(options) do
    [{"Authorization", "Basic #{Base.encode64(get_config(:private_key, options))}"}]
  end

  defp get_save_card_url(), do: "https://test-token.paymill.com/"

  defp parse_card_response(response) do
    response
    |> String.replace(~r/jsonPFunction\(/,"")
    |> String.replace(~r/\)/, "")
    |> Poison.decode
  end

  defp get_currency(options), do: options[:currency] || @default_currency

  defp get_amount(options), do: options[:money]

  defp get_token(response) do
    get_in(response, ["transaction", "identification", "uniqueId"])
  end

  defp commit(method, action, parameters \\ nil, options) do
    HTTPoison.request(method, @live_url <> action, {:form, parameters }, get_headers(options), [])
    |> ResponseParser.parse
  end

  defp get_config(key, options) do
    get_in(options, [:config, key])
  end

  defmodule ResponseHandler do
    alias Gringotts.Response

    @response_code %{
        10001 => "Undefined response",
        10002 => "Waiting for something",
        11000 => "Retry request at a later time",

        20000 => "Operation successful",
        20100 => "Funds held by acquirer",
        20101 => "Funds held by acquirer because merchant is new",
        20200 => "Transaction reversed",
        20201 => "Reversed due to chargeback",
        20202 => "Reversed due to money-back guarantee",
        20203 => "Reversed due to complaint by buyer",
        20204 => "Payment has been refunded",
        20300 => "Reversal has been canceled",
        22000 => "Initiation of transaction successful",

        30000 => "Transaction still in progress",
        30100 => "Transaction has been accepted",
        31000 => "Transaction pending",
        31100 => "Pending due to address",
        31101 => "Pending due to uncleared eCheck",
        31102 => "Pending due to risk review",
        31103 => "Pending due regulatory review",
        31104 => "Pending due to unregistered/unconfirmed receiver",
        31200 => "Pending due to unverified account",
        31201 => "Pending due to non-captured funds",
        31202 => "Pending due to international account (accept manually)",
        31203 => "Pending due to currency conflict (accept manually)",
        31204 => "Pending due to fraud filters (accept manually)",

        40000 => "Problem with transaction data",
        40001 => "Problem with payment data",
        40002 => "Invalid checksum",
        40100 => "Problem with credit card data",
        40101 => "Problem with CVV",
        40102 => "Card expired or not yet valid",
        40103 => "Card limit exceeded",
        40104 => "Card is not valid",
        40105 => "Expiry date not valid",
        40106 => "Credit card brand required",
        40200 => "Problem with bank account data",
        40201 => "Bank account data combination mismatch",
        40202 => "User authentication failed",
        40300 => "Problem with 3-D Secure data",
        40301 => "Currency/amount mismatch",
        40400 => "Problem with input data",
        40401 => "Amount too low or zero",
        40402 => "Usage field too long",
        40403 => "Currency not allowed",
        40410 => "Problem with shopping cart data",
        40420 => "Problem with address data",
        40500 => "Permission error with acquirer API",
        40510 => "Rate limit reached for acquirer API",
        42000 => "Initiation of transaction failed",
        42410 => "Initiation of transaction expired",

        50000 => "Problem with back end",
        50001 => "Country blacklisted",
        50002 => "IP address blacklisted",
        50004 => "Live mode not allowed",
        50005 => "Insufficient permissions (API key)",
        50100 => "Technical error with credit card",
        50101 => "Error limit exceeded",
        50102 => "Card declined",
        50103 => "Manipulation or stolen card",
        50104 => "Card restricted",
        50105 => "Invalid configuration data",
        50200 => "Technical error with bank account",
        50201 => "Account blacklisted",
        50300 => "Technical error with 3-D Secure",
        50400 => "Declined because of risk issues",
        50401 => "Checksum was wrong",
        50402 => "Bank account number was invalid (formal check)",
        50403 => "Technical error with risk check",
        50404 => "Unknown error with risk check",
        50405 => "Unknown bank code",
        50406 => "Open chargeback",
        50407 => "Historical chargeback",
        50408 => "Institution / public bank account (NCA)",
        50409 => "KUNO/Fraud",
        50410 => "Personal Account Protection (PAP)",
        50420 => "Rejected due to acquirer fraud settings",
        50430 => "Rejected due to acquirer risk settings",
        50440 => "Failed due to restrictions with acquirer account",
        50450 => "Failed due to restrictions with user account",
        50500 => "General timeout",
        50501 => "Timeout on side of the acquirer",
        50502 => "Risk management transaction timeout",
        50600 => "Duplicate operation",
        50700 => "Cancelled by user",
        50710 => "Failed due to funding source",
        50711 => "Payment method not usable, use other payment method",
        50712 => "Limit of funding source was exceeded",
        50713 => "Means of payment not reusable (canceled by user)",
        50714 => "Means of payment not reusable (expired)",
        50720 => "Rejected by acquirer",
        50730 => "Transaction denied by merchant",
        50800 => "Preauthorisation failed",
        50810 => "Authorisation has been voided",
        50820 => "Authorisation period expired"
      }

    def parse({:ok, %HTTPoison.Response{body: body, status_code: 200}}) do
      body = Poison.decode!(body)
      parse_body(body)
    end
    def parse({:ok, %HTTPoison.Response{body: body, status_code: 400}}) do
      body = Poison.decode!(body)
      []
      |> set_params(body)
    end
    def parse({:ok, %HTTPoison.Response{body: body, status_code: 404}}) do
      body = Poison.decode!(body)
      []
      |> set_success(body)
      |> set_params(body)
      |> handle_opts()
    end

    defp set_success(opts, %{"error" => error}) do
      opts ++ [message: error, success: false]
    end
    defp set_success(opts, %{"transaction" => %{ "response_code" => 20000}}) do
      opts ++ [success: true]
    end

    defp parse_body(%{"data" => data}) do
      []
      |> set_success(data)
      |> parse_authorization(data)
      |> parse_status_code(data)
      |> set_params(data)
      |> handle_opts()
    end

    defp handle_opts(opts) do
      case Keyword.fetch(opts, :success) do
        {:ok, true} -> {:ok, Response.success(opts)}
        {:ok, false} -> {:error, Response.error(opts)}
      end
    end

    #Status code
    defp parse_status_code(opts, %{"status" => "failed"} = body) do
      response_code = get_in(body, ["transaction", "response_code"])
      response_msg = Map.get(@response_code, response_code, -1)
      opts ++ [message: response_msg]
    end
    defp parse_status_code(opts, %{ "transaction" => transaction}) do
      response_code = Map.get(transaction, "response_code", -1)
      response_msg = Map.get(@response_code, response_code, -1)
      opts ++ [status_code: response_code, message: response_msg]
    end
    defp parse_status_code(opts, %{"response_code" => code}) do
      response_msg = Map.get(@response_code, code, -1)
      opts ++ [status_code: code, message: response_msg]
    end

    #Authorization
    defp parse_authorization(opts, %{"status" => "failed"}) do
      opts ++ [success: false]
    end
    defp parse_authorization(opts, %{ "id" => id} = auth) do
      opts ++ [authorization: id]
    end

    defp set_params(opts, body), do: opts ++ [params: body]
  end

end
