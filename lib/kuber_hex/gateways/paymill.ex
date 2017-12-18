defmodule Kuber.Hex.Gateways.Paymill do
  use Kuber.Hex.Gateways.Base
  alias Kuber.Hex.{ CreditCard, Address, Response}

  use Kuber.Hex.Adapter, required_config: [:private_key, :public_key]

  @supported_countries ~w(AD AT BE BG CH CY CZ DE DK EE ES FI FO FR GB
                          GI GR HR HU IE IL IM IS IT LI LT LU LV MC MT
                          NL NO PL PT RO SE SI SK TR VA)

  @supported_cartypes [:visa, :master, :american_express, :diners_club, :discover, :union_pay, :jcb]

  @home_page "https://paymill.com"
  @money_format :cents
  @default_currency "EUR"
  @live_url "https://api.paymill.com/v2.1/"
  @headers [{"Content-Type", "application/x-www-form-urlencoded"}]

  def save_card(card, options) do
    {:ok, %HTTPoison.Response{body: response}} = HTTPoison.get(
        get_save_card_url(),
        get_headers(options),
        params: get_save_card_params(card, options))

     parse_card_response(response)
  end

  defp get_save_card_url(), do: "https://test-token.paymill.com/"

  def authorize(amount, card_or_token, options) do
    Keyword.put(options, :money, amount)
    action_with_token(:authorize, amount, card_or_token, options)
  end

  def purchase(amount, card, options) do
    Keyword.put(options, :money, amount)
    action_with_token(:purchase, amount, card, options)
  end

  def capture(amount, authorization, options) do
    post = add_amount([], amount, options) ++ [{"token", authorization}]

    commit(:post, "transactions", post, options)
  end

  def void(authorization, options) do
    commit(:delete, "preauthorizations/#{authorization}", [], options)
  end

  def save(card, options) do
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

  def authorize_with_token(money, card_token, options) do
    post = add_amount([], money, options) ++ [{"token", card_token}]

    commit(:post, "preauthorizations", post, options)
  end

  def purchase_with_token(money, card_token, options) do
    post = add_amount([], money, options) ++ [{"token", card_token}]

    commit(:post, "transactions", post, options)
  end

  defp add_amount(post, money, options) do
    post ++ [{"amount", money}, {"currency", @default_currency}]
  end

  defp set_username(options) do
    [{"Authorization", "Basic #{Base.encode64(get_config(:private_key, options))}"}]
  end

  def get_headers(options) do
    @headers ++ set_username(options)
  end

  def get_save_card_params(card, options) do
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

  defp parse_card_response(response) do
    response
    |> String.replace(~r/jsonPFunction\(/,"")
    |> String.replace(~r/\)/, "")
    |> Poison.decode
  end

  defp get_currency(options), do: options[:currency] || @default_currency

  defp get_amount(options), do: options[:money] || 100

  defp get_token(response) do
    get_in(response, ["transaction", "identification", "uniqueId"])
  end

  defp commit(method, action, parameters \\ nil, options) do
    HTTPoison.request(method, @live_url <> action, {:form, parameters }, get_headers(options), [])
  end

  defp get_config(key, options) do
    get_in(options, [:config, key])
  end

end
