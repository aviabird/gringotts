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
  @live_url "https://api.paymill.com/v2.1/"


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
    :get |> HTTPoison.request(get_save_card_url(),"",get_headers(), [params: get_save_card_params()])

    response |> parse_card_response
  end

  defp get_save_card_url(), do: "https://test-token.paymill.com/"

  def authorize(amount, card, options) do
    action_with_token(:authorize, amount, card, options)
  end

  def purchase(amount, card, options) do
    action_with_token(:purchase, amount, card, options)
  end

  def capture(amount, authorization, options) do
    post = add_amount([], amount, options) ++ [{"token", authorization}]

    commit(:post, "transactions", post)
  end

  def void(authorization, options) do
    commit(:delete, "preauthorizations/#{authorization}", options)
  end

  defp action_with_token(action, amount, card, options) do
    Keyword.put(options, :money, amount)
    {:ok, response} = save_card(123, options)
    card_token = response |> get_token

    apply( __MODULE__, String.to_atom("#{action}_with_token"), [amount, card_token, options])
  end

  def authorize_with_token(money, card_token, options) do
    post =
    add_amount([], money, options)++[{"token", card_token}]

    commit(:post, "preauthorizations", post)
  end

  def purchase_with_token(money, card_token, options) do
    post =
    add_amount([], money, options)++[{"token", card_token}]

    commit(:post, "transactions", post)
  end

  defp add_amount(post, money, options) do
    post ++ [{"amount", money}, {"currency", @default_currency}]
  end

  defp set_username do
    [{"Authorization", "Basic #{Base.encode64(@private_key)}"}]
  end

  def get_headers() do
    [{"Content-Type", "application/x-www-form-urlencoded"}] ++ set_username
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

  def get_token(response) do
    response |> Kernel.get_in(["transaction", "identification", "uniqueId"])
  end

  defp commit(method, action, parameters \\ nil) do
    body = [{"amount", "120"},{"currency" , "EUR"}, {"token", "tok_26bce989967d20e7061ff37c8410"}]

    method
    |> HTTPoison.request(@live_url <> action, {:form, parameters }, get_headers, [])
  end

end
