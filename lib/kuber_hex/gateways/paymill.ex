defmodule Kuber.Hex.Gateways.Paymill do
  use Kuber.Hex.Gateways.Base
  alias Kuber.Hex.{ CreditCard, Address, Response}

  @supported_countries ~w(AD AT BE BG CH CY CZ DE DK EE ES FI FO FR GB
                          GI GR HR HU IE IL IM IS IT LI LT LU LV MC MT
                          NL NO PL PT RO SE SI SK TR VA)

  @supported_cartypes [:visa, :master, :american_express, :diners_club, :discover, :union_pay, :jcb]

  @home_page "https://paymill.com"
  @money_format :cents
  @default_currency "EUR"
  @live_url "https://api.paymill.com/v2/"


  @private_key "8f16b021d4fb1f8d9263cbe346f32688"
  @public_key "72294854039fcf7fd55eaeeb594577e7"

  @credit_card %CreditCard{
    name: "Sagar Karwande",
    number: "4111111111111111",
    expiration: {12, 2018},
    cvc: 123
  }

  def save_card(card, options) do
    {:ok, %HTTPoison.Response{body: response}} =
    :get
    |> HTTPoison.request("https://test-token.paymill.com/","",get_headers(), [params: get_save_card_params()])

    response |> parse_card_response
  end

  def authorize(amount, card, options) do
    action_with_token(:authorize, amount, card, options)
  end

  def action_with_token(action, amount, card, options) do
    
  end

  defp set_username do
    [{"Authorization", "Basic #{Base.encode64(@private_key)}"}]
  end

  def get_headers() do
    [] ++ set_username
  end

  def get_save_card_params() do
    [ {"transaction.mode" , "CONNECTOR_TEST"},
      {"channel.id" , "72294854039fcf7fd55eaeeb594577e7"},
      {"jsonPFunction" , "jsonPFunction"},
      {"account.number" , "4111111111111111"},
      {"account.expiry.month" , "12"},
      {"account.expiry.year" , "2018"},
      {"account.verification" , "123"},
      {"account.holder" , "Sagar Karwande"},
      {"presentation.amount3D" , "120"},
      {"presentation.currency3D" , "EUR"}
    ]
  end

  def parse_card_response(response) do
    response
    |> String.replace(~r/jsonPFunction\(/,"")
    |> String.replace(~r/\)/, "")
    |> Poison.decode
  end

  def get_token(repsonse) do
    response |> Kernel.get_in(["transaction", "identification", "uniqueId"])
  end

  defp commit(method, action, parameters) do

  end

end
