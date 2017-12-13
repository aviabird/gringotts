defmodule Kuber.Hex.Gateways.Stripe do
  @base_url "https://api.stripe.com/v1"

  use Kuber.Hex.Gateways.Base
  use Kuber.Hex.Adapter, required_config: [:api_key, :default_currency]

  alias Kuber.Hex.{
    CreditCard,
    Address,
    Response
  }

  def authorize(amount, payment, opts \\ []) do
    params = create_params_for_auth_or_purchase(amount, payment, opts, false)
    commit(:post, "charges", params)
  end

  def purchase(amount, payment, opts \\ []) do
    params = create_params_for_auth_or_purchase(amount, payment, opts)
    commit(:post, "charges", params)
  end

  def capture(id, amount, opts \\ []) do
    params = opts ++ amount_params(amount)

    commit(:post, "charges/#{id}/capture", params)
  end

  def void(id, opts \\ []) do
    params = opts
    commit(:post, "charges/#{id}/refund", params)
  end

  def refund(amount, id, opts \\ []) do
    params = opts ++ amount_params(amount)

    commit(:post, "charges/#{id}/refund", params)
  end

  def store(card, opts \\ []) do
    params = opts ++ source_params(card)
    
    commit(:post, "customers", params)
  end

  def unstore(id), do: commit(:delete, "customers/#{id}")

  defp create_params_for_auth_or_purchase(amount, payment, opts, capture \\ true) do
    opts ++ [capture: capture]
      ++ amount_params(amount)
      ++ source_params(payment)
      # ++ customer_params(payment)
  end

  defp create_card_token(params) do
    commit(:post, "tokens", params)
  end

  defp amount_params(amount), do: [amount: money_to_cents(amount)]

  defp source_params(%{} = payment) do
    params = 
      card_params(payment) ++ 
      address_params(payment)

    {:ok, %HTTPoison.Response{body: body}} = create_card_token(params)
    body
      |> Poison.decode!
      |> Map.get("id")
      |> source_params
  end

  defp source_params(token), do: [source: token]

  # defp customer_params(customer_id), do: [customer: customer_id]

  defp card_params(%{} = card) do
    {exp_year, exp_month} = card[:expiration]

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

  defp commit(method, path, params \\ []) do
    headers = [{"Content-Type", "application/x-www-form-urlencoded"}, {"Authorization", "Bearer sk_test_vIX41hayC0BKrPWQerLuOMld"}]
    data = params_to_string(params)
    HTTPoison.request(method, "#{@base_url}/#{path}", data, headers)
  end

end
