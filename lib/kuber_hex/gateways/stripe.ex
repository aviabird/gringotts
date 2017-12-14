defmodule Kuber.Hex.Gateways.Stripe do

  @moduledoc """
  Functions for working with Stripe payment gateway. Through this API you can:

  * Authorize payment source and use it later for payment.
  * Purchase with payment source.
  * Capture a payment for already authorized payment source.
  * Void the payment for payment source.
  * Refund amount to payment source.
  * Store payment source for making purchases later.
  * Unstore payment source.
  
  Stripe API reference: https://stripe.com/docs/api
  """

  @base_url "https://api.stripe.com/v1"

  use Kuber.Hex.Gateways.Base
  use Kuber.Hex.Adapter, required_config: [:api_key, :default_currency]

  alias Kuber.Hex.{
    CreditCard,
    Address
  }

  @doc """
  Authorize payment source.

  Authorize the payment source for a customer or card using amount and opts.
  opts must include the default currency.

  ## Examples

    payment = %{
      expiration: {2018, 12}, number: "4242424242424242", cvc:  "123", name: "John Doe",
      street1: "123 Main", street2: "Suite 100", city: "New York", region: "NY", country: "US",
      postal_code: "11111"
    }
  
    opts = [currency: "usd"]
    amount = 5

    Kuber.Hex.Gateways.Stripe.authorize(amount, payment, opts)
  """
  @spec authorize(Float, Map, List) :: Map
  def authorize(amount, payment, opts \\ []) do
    params = create_params_for_auth_or_purchase(amount, payment, opts, false)
    commit(:post, "charges", params, opts) |> format_response
  end

  @doc """
  Purchase with payment source.

  Purchase with the payment source using amount and opts.
  opts must include the default currency.

  ## Examples

    payemnt = %{
      expiration: {2018, 12}, number: "4242424242424242", cvc:  "123", name: "John Doe",
      street1: "123 Main", street2: "Suite 100", city: "New York", region: "NY", country: "US",
      postal_code: "11111"
    }
  
    opts = [currency: "usd"]
    amount = 5

    Kuber.Hex.Gateways.Stripe.purchase(amount, payment, opts)
  """
  @spec purchase(Float, Map, List) :: Map
  def purchase(amount, payment, opts \\ []) do
    params = create_params_for_auth_or_purchase(amount, payment, opts)
    commit(:post, "charges", params, opts)
  end

  @doc """
  Captures a payment.

  Captures a payment with already authorized payment source.
  Once the charge is captured, it cannot be captured again.
  Amount less than or equal to authorized amount can be captured
  but not more than that.
  If less amount is captured than the authorized amount, then
  remaining amount will be refunded back to the authorized 
  paymet source.

  ## Examples  
    
    id = "ch_1BYvGkBImdnrXiZwet3aKkQE"
    amount = 5
    opts = []

    Kuber.Hex.Gateways.Stripe.capture(id, amount, opts)
  """
  @spec capture(String.t, Float, List) :: Map
  def capture(id, amount, opts \\ []) do
    params = optional_params(opts) ++ amount_params(amount)
    commit(:post, "charges/#{id}/capture", params, opts)
  end

  @doc """
  Voids the payment.

  Returns the captured amount to the authorized payment source.

  ## Examples  
    
    id = "ch_1BYvGkBImdnrXiZwet3aKkQE"
    opts = []

    Kuber.Hex.Gateways.Stripe.void(id, opts)
  """
  @spec void(String.t, List) :: Map
  def void(id, opts \\ []) do
    params = optional_params(opts)
    commit(:post, "charges/#{id}/refund", params, opts)
  end

  @doc """
  Refunds the amount.

  Returns the captured amount to the authorized payment source.
  Less than or equal to the captured amount can be refunded.
  If the refunded amount is less than the captured amount, then
  remaining amount can be refunded again.

  ## Examples  
    
    amount = 5
    id = "ch_1BYvGkBImdnrXiZwet3aKkQE"
    opts = []

    Kuber.Hex.Gateways.Stripe.refund(amount, id, opts)
  """
  @spec refund(Float, String.t, List) :: Map
  def refund(amount, id, opts \\ []) do
    params = optional_params(opts) ++ amount_params(amount)
    commit(:post, "charges/#{id}/refund", params, opts)
  end

  @doc """
  Stores the payment source.

  Store the payment source, so that it can be used
  for capturing the amount at later stages.

  ## Examples  
    
    payment = %{
      expiration: {2018, 12}, number: "4242424242424242", cvc:  "123", name: "John Doe",
      street1: "123 Main", street2: "Suite 100", city: "New York", region: "NY", country: "US",
      postal_code: "11111"
    }

    opts = []

    Kuber.Hex.Gateways.Stripe.store(payment, opts)
  """
  @spec store(Map, List) :: Map
  def store(payment, opts \\ []) do
    params = optional_params(opts) ++ source_params(payment)
    commit(:post, "customers", params, opts)
  end

  @doc """
  Unstore the stored payment source.

  Unstore the already stored payment source,
  so that it cannot be used again for capturing
  payments.

  ## Examples  
    
    id = "cus_BwpLX2x4ecEUgD"

    Kuber.Hex.Gateways.Stripe.unstore(id)
  """
  @spec unstore(String.t) :: Map
  def unstore(id, opts \\ []), do: commit(:delete, "customers/#{id}", [], opts)

  # Private methods

  defp create_params_for_auth_or_purchase(amount, payment, opts, capture \\ true) do
    optional_params(opts) 
      ++ [capture: capture]
      ++ amount_params(amount)
      ++ source_params(payment, opts)
  end

  defp create_card_token(params, opts) do
    commit(:post, "tokens", params, opts) |> format_response
  end

  defp amount_params(amount), do: [amount: money_to_cents(amount)]

  defp source_params(%{} = payment, opts) do
    params = 
      card_params(payment) ++ 
      address_params(payment)

    response = create_card_token(params, opts)

    case Map.has_key?(response, "error") do
      true -> []
      false -> response
        |> Map.get("id")
        |> source_params
    end
  end

  defp source_params(token_or_customer) do
    [head, _] = String.split(token_or_customer, "_")
    case head do
      "tok" -> [source: token_or_customer]
      "cus" -> [customer: token_or_customer]
    end
  end

  defp card_params(%{} = card) do
    {exp_year, exp_month} = case Map.has_key?(card, :expiration) do
      true ->  card[:expiration]
      false -> {nil, nil}
    end

    [ "card[name]": card[:name],
      "card[number]": card[:number],
      "card[exp_year]": exp_year,
      "card[exp_month]": exp_month,
      "card[cvc]": card[:cvc]
    ]   
  end

  defp card_params(_), do: []

  defp address_params(%{} = address) do
    [ "card[address_line1]": address[:street1],
      "card[address_line2]": address[:street2],
      "card[address_city]":  address[:city],
      "card[address_state]": address[:region],
      "card[address_zip]":   address[:postal_code],
      "card[address_country]": address[:country]
    ]
  end

  defp address_params(_), do: []

  defp commit(method, path, params \\ [], opts \\ []) do
    auth_token = "Bearer " <> opts[:config][:api_key]

    headers = [{"Content-Type", "application/x-www-form-urlencoded"}, {"Authorization", auth_token}]
    data = params_to_string(params)
    HTTPoison.request(method, "#{@base_url}/#{path}", data, headers)
  end

  defp optional_params(opts) do
    Keyword.delete(opts, :config)
  end

  defp format_response(response) do
    case response do
      {:ok, %HTTPoison.Response{body: body}} -> body |> Poison.decode!
      _ -> %{"error" => "something went wrong, please try again later"}
    end
  end

end
