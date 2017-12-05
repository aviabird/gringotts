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
  alias Kuber.Hex.{CreditCard, Address, Response}
  
  @base_url "https://test.monei-api.net"
  @default_headers ["Content-Type": "application/x-www-form-urlencoded",
                    "charset": "UTF-8"]
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
    "X" => {"absent", "absent"} # custom response code added by ananyab (this is never returned by MONEI
  }
  
  # MONEI supports payment by card, bank account and even something obscure: virtual account
  # opts has the auth keys.

  @spec authorize(Float, String.t, CreditCard, Map) :: Response
  def authorize(amount, currency \\ "EUR", card, opts) do # not just card, also bank!
    params = [paymentType: "PA",
              amount: :erlang.float_to_binary(amount, decimals: 2),
              currency: currency] ++ card_params(card)
    commit(:post, "payments", params, opts)
  end

  @spec capture(Float, String.t, String.t, Map) :: Response
  def capture(amount, currency \\ "EUR", <<paymentId::bytes-size(32)>>, opts) do
    params = [paymentType: "CP",
              amount: :erlang.float_to_binary(amount, decimals: 2),
              currency: currency]
    commit(:post, "payments/#{paymentId}", params, opts)
  end

  @spec purchase(Float, String.t, CreditCard, Map) :: Response
  def purchase(amount, currency \\ "EUR", card, opts) do
    params = [paymentType: "DB",
              amount: :erlang.float_to_binary(amount, decimals: 2),
              currency: currency] ++ card_params(card)
    commit(:post, "payments", params, opts)
  end

  defp card_params(card) do
    {expiration_year, expiration_month} = card.expiration
    ["card.number": card.number,
     "card.holder": card.name,
     "card.expiryMonth": expiration_month |> Integer.to_string |> String.pad_leading(2, "0"),
     "card.expiryYear": expiration_year |> Integer.to_string,
     "card.cvv": card.cvc,
     "paymentBrand": "VISA"] # DANGER!
  end

  def commit(method, endpoint, params, %{userId: userId,
                                         password: password,
                                         entityId: entityId}) do
    body = params ++ ["authentication.userId": userId,
                      "authentication.password": password,
                      "authentication.entityId": entityId]
    url = "#{@base_url}/#{@version}/#{endpoint}"
    IO.inspect body
    method
    |> HTTPoison.request(url, {:form, body}, @default_headers)
    |> respond
  end
  def commit(_method, _endpoint, _params, _opts) do
    Response.error(reason: "Authorization fields missing")
  end

  def respond({:ok, %{status_code: 200, body: body}}) do
    data = decode!(body)
    {code, description, _risk_score, cvc_result, avs_result} = verification_result(data)
    Response.success(authorization: data["id"],
      cvc_result: cvc_result,
      avs_result: avs_result,
      raw: {:json, data},
      code: code,
      reason: description)
  end

  @doc"""
  MONEI will respond with an HTML message if status code is not 200.
  """
  def respond({:ok, %{status_code: status_code, body: body}}) do
    Response.error(code: status_code, raw: {:html, body})
  end

  defp verification_result(%{"result" => result, "risk" => risk}) do
    IO.inspect result
    cvc_result = @cvc_code_translator[result["cvvResponse"]]
    {address, zip_code} = case result["avsResponse"] do
      nil -> @avs_code_translator["X"] # custom response code added by ananyab (this is never returned by MONEI
      avs -> @avs_code_translator[avs]
    end
    {result["code"],
     result["description"],
     risk["score"],
     cvc_result,
     %{address: address, zip_code: zip_code}}
  end

  defp verification_result(_), do: {nil, nil, nil, nil, nil}
      
end

"""
alias Kuber.Hex.Gateways.Monei
alias Kuber.Hex.{CreditCard, Address, Response}

cc = %CreditCard{
name: "Jo Doe",
number: "4200000000000000",
expiration: {2019, 12},
cvc:  "123"
}

bad_cc = %CreditCard{
name: "Jo Doe",
number: "4200000000000000",
expiration: {2011, 12},
cvc:  "123"
}

  opts = %{userId: "8a829417539edb400153c1eae83932ac", password: "6XqRtMGS2N", entityId: "8a829417539edb400153c1eae6de325e", default_currency: "EUR"}

url = "https://test.monei-api.net/v1/payments"
headers = ["Content-Type": "application/x-www-form-urlencoded"]
Monei.authorize(92, cc, opts)
"""
