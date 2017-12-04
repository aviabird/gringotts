defmodule Kuber.Hex.Gateways.Monei do
  @moduledoc """
  Issues:
  
  commerce_billing and kuber_hex have some issues with their deps. `mix deps.get` throws a million warnings.
  Can't use Kuber.Hex.Gateways.Base.http as it is specifically tailored for stripe!
  There's no validation for opts, ie some required keys might be missing.
  Why don't we `use HTTPoison.Base`.
  Need a card brand field in CreditCard struct
  """
  
  use Kuber.Hex.Gateways.Base
  import Poison, only: [decode!: 1]
  import HTTPoison
  alias Kuber.Hex.{CreditCard, Address, Response}
  
  @base_url "https://test.monei-api.net"
  @default_headers ["Content-Type": "application/x-www-form-urlencoded",
                    "charset": "UTF-8"]
  @version "v1"

  @cvc_code_translator %{
    "M" => "pass",
    "N" => "fail",
    "P" => "unchecked"
  }

  @avs_code_translator %{
    "Y" => {"pass", "pass"},
    "A" => {"pass", "fail"},
    "B" => {"pass", "unchecked"},
    "Z" => {"fail", "pass"},
    "N" => {"fail", "fail"},
    "P" => {"unchecked", "pass"},
    "I" => {"unchecked", "unchecked"}
  }
  
  # MONEI supports payment by card, bank account and even something obscure: virtual account
  # opts has the auth keys.
  def authorize(amount, card, opts) do # not just card, also bank!
    params = [paymentType: "PA",
              amount: "92.00",
              currency: Map.fetch!(opts, :default_currency)] ++ card_params(card)
    commit(:post, "payments", params, opts)
  end

  def capture(amount, paymentId, opts) do
    

  defp card_params(card) do
    {expiration_year, expiration_month} = card.expiration
    ["card.number": card.number,
     "card.holder": card.name,
     "card.expiryMonth": expiration_month |> Integer.to_string |> String.pad_leading(2, "0"),
     "card.expiryYear": expiration_year |> Integer.to_string,
     "card.cvv": card.cvc,
     "paymentBrand": "VISA"] # DANGER!
  end

  def commit(method, endpoint, params, opts = %{userId: userId,
                                                password: password,
                                                entityId: entityId}) do
    body = params ++ ["authentication.userId": userId,
                      "authentication.password": password,
                      "authentication.entityId": entityId]
    url = "#{@base_url}/#{@version}/#{endpoint}"
    method
    |> HTTPoison.request(url, {:form, body}, @default_headers)
    # |> respond
  end

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

  opts = %{userId: "8a829417539edb400153c1eae83932ac", password: "6XqRtMGS2N", entityId: "8a829417539edb400153c1eae6de325e", default_currency: "EUR"}

url = "https://test.monei-api.net/v1/payments"
headers = ["Content-Type": "application/x-www-form-urlencoded"]
Monei.authorize(92, cc, opts)
"""
