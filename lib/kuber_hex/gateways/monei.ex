defmodule Kuber.Hex.Gateways.Monei do
  @moduledoc ~S"""
  An API client for the [MONEI](https://www.monei.net) gateway.

  For reference see [MONEI's API (v1) documentation](https://docs.monei.net).

  The following features of MONEI are implemented:
  
  * `PA` **Pre-Authorize**\
  In `authorize/3`.

  * `CP` **Capture**\
  In `capture/3`.

  * `RF` **Refund**\
  In `refund/3` and ~~also `void/2`~~.

  * `RV` **Reversal**\
  In `void/2`.

  * `DB` **Debit**\
  In `purchase/3`.
  
  * **Tokenization** and **Registrations**\
  In `store/2` ~~and `unstore/2`~~.

  ## Caveats

  Although MONEI supports payments from [various cards](https://support.monei.net/charges-and-refunds/accepted-credit-cards-payment-methods), banks and virtual accounts (like some wallets), this library only accepts payments by (supported) cards.

  ## TODO

  * [Backoffice operations](https://docs.monei.net/tutorials/manage-payments/backoffice)
    - Credit
    - Rebill
  * [Recurring payments](https://docs.monei.net/recurring)
  * [Reporting](https://docs.monei.net/tutorials/reporting)
  
  """
  
  use Kuber.Hex.Adapter, required_config: [:userId, :entityId, :password, :worker_process_name]
  import Poison, only: [decode: 1]
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

  @spec authorize(Integer | Float, CreditCard, Keyword) :: Response
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

  @spec capture(Integer | Float, String.t, Keyword) :: Response
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

  @spec purchase(Integer | Float, CreditCard, Keyword) :: Response
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

  @spec void(String.t, Keyword) :: Response
  def void(<<paymentId::bytes-size(32)>>, opts) do
    params = [paymentType: "RV"]
    auth_info = Keyword.fetch!(opts, :config)
    commit(:post, "payments/#{paymentId}", params, auth_info)
  end

  @spec refund(Integer | Float, String.t, Keyword) :: Response
  def refund(amount, <<paymentId::bytes-size(32)>>, opts) do
    params = [paymentType: "RF",
              amount: :erlang.float_to_binary(amount, decimals: 2),
              currency: currency(opts)]
    auth_info = Keyword.fetch!(opts, :config)
    commit(:post, "payments/#{paymentId}", params, auth_info)
  end

  @spec store(CreditCard, Keyword) :: Response
  def store(card = %CreditCard{}, opts) do
    params = card_params(card)
    auth_info = Keyword.fetch!(opts, :config)
    commit(:post, "registrations", params, auth_info)
  end

  @doc """
  WIP

  MONEI unstore does not seem to work. MONEI always returns a `403`
  """
  @spec unstore(String.t, Keyword) :: Response
  def unstore(<<registrationId::bytes-size(32)>>, opts) do
    auth_info = Keyword.fetch!(opts, :config)
    commit(:delete, "registrations/#{registrationId}", [], auth_info)
  end


  
  defp card_params(card) do
    {expiration_year, expiration_month} = card.expiration
    ["card.number": card.number,
     "card.holder": "#{card.first_name} #{card.last_name}",
     "card.expiryMonth": expiration_month |> Integer.to_string |> String.pad_leading(2, "0"),
     "card.expiryYear": expiration_year |> Integer.to_string,
     "card.cvv": card.verification_code,
     "paymentBrand": card.brand]
  end

  def commit(method, endpoint, params, opts = %{userId: userId,
                                                password: password,
                                                entityId: entityId}) do
    auth_params = ["authentication.userId": userId,
                   "authentication.password": password,
                   "authentication.entityId": entityId]
    body = params ++ auth_params
    url = "#{base_url(opts)}/#{version(opts)}/#{endpoint}"
    case method do
      :post -> HTTPoison.post(url, {:form, body}, @default_headers) |> respond
      :delete -> HTTPoison.delete(url  <> "?" <> URI.encode_query(auth_params)) |> respond
    end
  end

  def commit(_method, _endpoint, _params, _opts) do
    {:error, Response.error(reason: "Authorization fields missing", description: "Check if the application is correctly configured")}
  end

  def respond({:ok, %{status_code: 200, body: body}}) do
    case decode(body) do
      {:ok, decoded_json} -> case verification_result(decoded_json) do
                               {:ok, results} -> {:ok, Response.success([{:id, decoded_json["id"]} | results])}
                               {:error, errors} -> {:ok, Response.error([{:id, decoded_json["id"]} | errors])}
                             end
      {:error, _} -> {:error, Response.error(raw: body, code: :undefined_response_from_monei)}
    end
  end

  def respond({:ok, %{status_code: status_code, body: body}}) do
    {:error, Response.error(code: status_code, raw: body)}
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


