defmodule Kuber.Hex.Gateways.Monei do
  @moduledoc """
  Issues:
  
  commerce_billing and kuber_hex have some issues with their deps. `mix deps.get` throws a million warnings.
  Can't use Kuber.Hex.Gateways.Base.http as it is specifically tailored for stripe!
  There's no validation for opts, ie some required keys might be missing.
    this will allow me to fail-fast, currently errors are caught in `commit` which is too late.
  Why don't we `use HTTPoison.Base`.
  Need a card brand field in CreditCard struct
  """
  
  use Kuber.Hex.Gateways.Base
  import Poison, only: [decode!: 1]
  alias Kuber.Hex.{CreditCard, Response}
  
  @base_url "https://test.monei-api.net"
  @default_headers ["Content-Type": "application/x-www-form-urlencoded",
                    "charset": "UTF-8"]
  @default_currency "EUR"
  
  @version "v1"

  @cvc_code_translator %{
    "M" => "pass",
    "N" => "fail",
    "P" => "not_processed",
    "U" => "issuer_unable",
    "S" => "issuer_unable"
  }

  @avs_code_translator %{
    "F" => {"pass", "pass"},
    "A" => {"pass", "fail"},
    "Z" => {"fail", "pass"},
    "N" => {"fail", "fail"},
    "U" => {"error", "error"},
    nil => {nil, nil}
  }
  
  # MONEI supports payment by card, bank account and even something obscure: virtual account
  # opts has the auth keys.

  @spec authorize(number, CreditCard, Keyword) :: Response
  def authorize(amount, card = %CreditCard{}, opts) when is_integer(amount) do
    authorize(amount / 1, card, opts)
  end
  
  def authorize(amount, card = %CreditCard{}, opts) when is_float(amount) do
    params = [paymentType: "PA",
              amount: :erlang.float_to_binary(amount, decimals: 2),
              currency: currency(opts)] ++ card_params(card)
    auth_info = Keyword.fetch!(opts, :config)
    commit(:post, "payments", params, auth_info)
  end

  @spec capture(number, String.t, Keyword) :: Response
  def capture(amount, <<paymentId::bytes-size(32)>>, opts) when is_integer(amount) do
    capture(amount / 1, paymentId, opts)
  end
  
  def capture(amount, <<paymentId::bytes-size(32)>>, opts) when is_float(amount) do
    params = [paymentType: "CP",
              amount: :erlang.float_to_binary(amount, decimals: 2),
              currency: currency(opts)]
    auth_info = Keyword.fetch!(opts, :config)
    commit(:post, "payments/#{paymentId}", params, auth_info)
  end

  @spec purchase(number, CreditCard, Keyword) :: Response
  def purchase(amount, card = %CreditCard{}, opts) when is_integer(amount) do
    purchase(amount / 1, card, opts)
  end
  
  def purchase(amount, card = %CreditCard{}, opts) when is_float(amount) do
    params = [paymentType: "DB",
              amount: :erlang.float_to_binary(amount, decimals: 2),
              currency: currency(opts)] ++ card_params(card)
    auth_info = Keyword.fetch!(opts, :config)
    commit(:post, "payments", params, auth_info)
  end

  defp card_params(card) do
    {expiration_year, expiration_month} = card.expiration
    ["card.number": card.number,
     "card.holder": card.name,
     "card.expiryMonth": expiration_month |> Integer.to_string |> String.pad_leading(2, "0"),
     "card.expiryYear": expiration_year |> Integer.to_string,
     "card.cvv": card.cvc,
     "paymentBrand": card.brand]
  end

  def commit(method, endpoint, params, opts = %{userId: userId,
                                                password: password,
                                                entityId: entityId}) do
    body = params ++ ["authentication.userId": userId,
                      "authentication.password": password,
                      "authentication.entityId": entityId]
    url = "#{base_url(opts)}/#{version(opts)}/#{endpoint}"
    method
    |> HTTPoison.request(url, {:form, body}, @default_headers)
    |> respond
  end

  @doc """
  This needs to be deprecated, and we should throw a nice BadConfig error instead of this clause.
  """
  def commit(_method, _endpoint, _params, _opts) do
    {:error, Response.error(reason: "Authorization fields missing", description: "Check if the application is correctly configured")}
  end

  def respond({:ok, %{status_code: 200, body: body}}) do
    data = decode!(body)
    # IO.inspect data
    case verification_result(data) do
      {:ok, results} -> {:ok, [{:id, data["id"]} | results] |> Response.success}
      {:error, errors} -> {:error, [{:id, data["id"]} | errors] |> Response.error}
    end
  end

  @doc"""
  MONEI will respond with an HTML message if status code is not 200.
  """
  def respond({:ok, %{status_code: status_code, body: body}}) do
    {:error, Response.error(code: status_code, raw: {:html, body})}
  end

  def respond({:error, %HTTPoison.Error{} = error}) do
    {:error, Response.error(code: error.id, reason: :network_fail?, description: "HTTPoison says '#{error.reason}'")}
  end

  defp verification_result(data = %{"result" => result}) do
    {address, zip_code} = @avs_code_translator[result["avsResponse"]]
    code = result["code"]
    results = [code: code,
               description: result["description"],
               risk: data["risk"]["score"],
               cvc_result: @cvc_code_translator[result["cvvResponse"]],
               avs_result: [address: address, zip_code: zip_code],
               raw: data]

    cond do
      String.match?(code, ~r{^(000\.000\.|000\.100\.1|000\.[36])}) -> {:ok, results}
      true -> {:error, [{:reason, result["description"]} | results]}
      # String.match?(code, ~r{^(000\.400\.0|000\.400\.100)}) -> :review
      # String.match?(code, ~r{^(000\.200)}) -> :session_active
      # String.match?(code, ~r{^(800\.400\.5|100\.400\.500)}) -> :pending
      # String.match?(code, ~r{^(000\.400\.[1][0-9][1-9]|000\.400\.2)}) -> :reject # risk check
      # String.match?(code, ~r{^(800\.[17]00|800\.800\.[123]}) -> :reject # bank or external
      # String.match?(code, ~r{^(900\.[1234]00}) -> :reject # comms failed
      # String.match?(code, ~r{^(800\.5|999\.|600\.1|800\.800\.8}) -> :reject # sys error
      # String.match?(code, ~r{^(800\.1[123456]0}) -> :reject # risk validation
      # String.match?(code, ~r{^(100\.400|100\.38|100\.370\.100|100\.370\.11}) -> :fail # external risk sys
      # String.match?(code, ~r{^(800\.400\.1}) -> :fail # avs
      # String.match?(code, ~r{^(800\.400\.2|100\.380\.4|100\.390}) -> :fail # 3ds
      # String.match?(code, ~r{^(100\.100\.701|800\.[32]}) -> :fail # blacklisted (possibly temporary)
      # String.match?(code, ~r{^(600\.[23]|500\.[12]|800\.121}) -> :invalid_config
      # String.match?(code, ~r{^(100\.[13]50}) -> :invalid # registration
      # String.match?(code, ~r{^(100\.[13]50}) -> :reject # job related
      # String.match?(code, ~r{^(700\.[1345][05]0}) -> :reject # refference related
      # String.match?(code, ~r{^(200\.[123]|100\.[53][07]|800\.900|100\.[69]00\.500}) -> :reject # bad format
      # String.match?(code, ~r{^(100\.800}) -> :reject # address validation
      # String.match?(code, ~r{^(100\.[97]00}) -> :reject # contact validation
      # String.match?(code, ~r{^(100\.100|100.2[01]}) -> :reject # account validation
      # String.match?(code, ~r{^(100\.55}) -> :reject # amount validation
      # String.match?(code, ~r{^(000\.100\.2}) -> :reject # chargebacks!!
    end
  end

  defp base_url(opts), do: opts[:test_url] || @base_url
  defp currency(opts), do: opts[:currency] || @default_currency
  defp version(opts), do: opts[:api_version] || @version
end

"""
alias Kuber.Hex.Gateways.Monei
alias Kuber.Hex.{CreditCard, Address, Response}

cc = %CreditCard{
name: "Jo Doe",
number: "4200000000000000",
expiration: {2019, 12},
cvc:  "123",
brand: "VISA"
}

bad_cc = %CreditCard{
name: "Jo Doe",
number: "4200000000000000",
expiration: {2011, 12},
cvc:  "123",
brand: "VISA"
}

opts = [config: %{userId: "8a829417539edb400153c1eae83932ac", password: "6XqRtMGS2N", entityId: "8a829417539edb400153c1eae6de325e", default_currency: "EUR"}]

url = "https://test.monei-api.net/v1/payments"
headers = ["Content-Type": "application/x-www-form-urlencoded"]
{:ok, res} = Monei.authorize(92.0, cc, opts)
Monei.capture(12.0, res.id, opts)
Monei.purchase(92.0, cc, opts)
"""
