defmodule Gringotts.Gateways.Trexle do
  
  @moduledoc """
  Functions supported for working with Trexle payment gateway:
  *
  *
  """
  @base_url "https://core.trexle.com/api/v1/"

  alias Gringotts.Gateways.Trexle.ResponseHandler, as: ResponseParser
  use Gringotts.Gateways.Base
  use Gringotts.Adapter, required_config: [:api_key,:default_currency]

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

  @spec capture(String.t, Float, List) :: Map
  def capture(charge_token, amount, opts \\ []) do
    params = [amount: amount]
    commit(:put, "charges/#{charge_token}/capture", params, opts)
  end
  
  @spec refund(Float, String.t, List) :: Map 
  def refund(amount, charge_token, opts \\ []) do
    params = [amount: amount]
    commit(:post, "charges/#{charge_token}/refunds", params, opts)
  end

  @spec store(Map, List) :: Map
  def store(payment, opts \\ []) do
    params = [email: opts[:email]]++card_params(payment)
    commit(:post, "customers", params, opts)
  end

  defp create_params_for_auth_or_purchase(amount, payment, opts, capture \\ true) do
    [
      capture: capture,
      amount: amount,
      currency: opts[:currency],
      email: opts[:email],
      ip_address: opts[:ip_address],
      description: opts[:description]
    ]++ card_params(payment)
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

  defp commit(method, path, params \\ [], opts \\ []) do
    auth_token = "Basic #{Base.encode64(opts[:config][:api_key])}"
    headers = [{"Content-Type", "application/x-www-form-urlencoded"}, {"Authorization", auth_token}]
    data = params_to_string(params)
    options = [hackney: [basic_auth: {opts[:config][:api_key], "password"}]]
    url = "#{@base_url}/#{path}"
    response = HTTPoison.request!(method, url, data, headers, options)
    format_response(response)
  end

  defp format_response(response) do
    case {:ok,response} do
      {:ok, %HTTPoison.Response{status_code: 201 }} -> {:ok,response}
      {:ok, %HTTPoison.Response{status_code: 200 }} -> {:ok,response}
      {:ok, %HTTPoison.Response{status_code: 400 }} -> {:error,response}
      {:ok, %HTTPoison.Response{status_code: 401 }} -> {:error,response}
      _ -> %{"error" => "something went wrong, please try again later"}
    end
  end

end