defmodule Kuber.Hex.Gateways.Trexle do

	@base_url "https://core.trexle.com/api/v1/"
  @currency "USD"
  @email "john@trexle.com"
  @ip_address "66.249.79.118"
  @description "Store Purchase 1437598192"

  use Kuber.Hex.Gateways.Base
  use Kuber.Hex.Adapter, required_config: [:api_key,:default_currency]

  alias Kuber.Hex.{
    CreditCard,
    Address
  }

  @spec authorize(Float, Map, List) :: Map
  def authorize(amount, payment, opts \\ []) do
    params = create_params_for_auth_or_purchase(amount, payment, opts, false)
    commit(:post, "charges", params, opts)
  end

  @spec purchase(Float, Map, List) :: Map
  def purchase(amount, payment, opts \\ []) do
    params = create_params_for_auth_or_purchase(amount, payment, opts)
    commit(:post, "charges", params, opts)
  end

  defp create_params_for_auth_or_purchase(amount, payment, opts, capture \\ true) do
      [] 
      ++ [capture: capture]
      ++ [amount: amount]
      ++ [currency: @currency]
      ++ [email: @email]
      ++ [ip_address: @ip_address]
      ++ [description: @description]
      ++ card_params(payment)
  end

  defp card_params(%{} = card) do
    [ "card[name]": card[:name],
      "card[number]": card[:number],
      "card[expiry_year]": card[:expiry_year],
      "card[expiry_month]": card[:expiry_month],
      "card[cvc]": card[:cvc],
      "card[address_line1]": card[:address_line1],
      "card[address_city]": card[:address_city],
      "card[address_postcode]": card[:address_postcode],
      "card[address_state]": card[:address_state],
      "card[address_country]": card[:address_country]
    ]   
  end

  # TODO: change the hardcoded api key to dynamic
  defp commit(method, path, params \\ [], opts \\ []) do

    auth_token = "Basic #{Base.encode64(opts[:config][:api_key])}"
    headers = [{"Content-Type", "application/x-www-form-urlencoded"}, {"Authorization", auth_token}]
    data = params_to_string(params)
    options = [hackney: [basic_auth: {opts[:config][:api_key], "password"}]]
    url = "#{@base_url}/#{path}"
    response = HTTPoison.request(method, url, data, headers, options)
    format_response(response)
  end

  defp format_response(response) do
    case response do
      {:ok, %HTTPoison.Response{body: body}} -> body |> Poison.decode!
      _ -> %{"error" => "something went wrong, please try again later"}
    end
  end


end