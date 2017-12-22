defmodule Gringotts.Gateways.Trexle do

  @moduledoc """
  Functions supported for working with Trexle payment gateway:
  *
  *
  """
  @base_url "https://core.trexle.com/api/v1/"
  @currency "USD"
  @email "john@trexle.com"
  @ip_address "66.249.79.118"
  @description "Store Purchase 1437598192"

  use Gringotts.Gateways.Base
  use Gringotts.Adapter, required_config: [:api_key, :default_currency]
  import Poison, only: [decode: 1]
  alias Gringotts.{Response}

  @spec authorize(float, map, list) :: map
  def authorize(amount, payment, opts \\ []) do
    params = create_params_for_auth_or_purchase(amount, payment, opts, false)
    commit(:post, "charges", params, opts)
  end

  @spec purchase(float, map, list) :: map
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
    params = [email: @email]++card_params(payment)
    commit(:post, "customers", params, opts)
  end

  defp create_params_for_auth_or_purchase(amount, payment, opts, capture \\ true) do
    [
      capture: capture,
      amount: amount,
      currency: @currency,
      email: @email,
      ip_address: @ip_address,
      description: @description
    ]++ card_params(payment)
  end

  defp card_params(%{} = card) do
    [
      "card[name]": card[:name],
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
    options = [hackney: [:insecure, basic_auth: {opts[:config][:api_key], "password"}]]
    url = "#{@base_url}#{path}"
    response = HTTPoison.request(method, url, data, headers, options)
  end

  @spec respond(term) ::
  {:ok, Response} |
  {:error, Response}
  defp respond(response)

  defp respond({:ok, %{status_code: code, body: body}}) when code in [200, 201] do
    case decode(body) do
      {:ok, results} -> {:ok, Response.success(raw: results, status_code: code)}
    end
  end

  defp respond({:ok, %{status_code: status_code, body: body}}) do
    {:error, Response.error(status_code: status_code, raw: body)}
  end

  defp respond({:error, %HTTPoison.Error{} = error}) do
    {:error, Response.error(code: error.id, reason: :network_fail?, description: "HTTPoison says '#{error.reason}'")}
  end

end
