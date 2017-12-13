defmodule Kuber.Hex.Gateways.Stripe do
  @base_url "https://api.stripe.com/v1"

  use Kuber.Hex.Gateways.Base
  use Kuber.Hex.Adapter, required_config: [:api_key, :default_currency]

  alias Kuber.Hex.{
    CreditCard,
    Address,
    Response
  }

  def authorize(amount, payment, opts \\ %{}) do
    params = create_params_for_auth_or_purchase(amount, payment, opts, false)
    commit(:post, "charges", params)
  end

  def purchase(amount, payment, opts \\ %{}) do
    params = create_params_for_auth_or_purchase(amount, payment, opts)
    commit(:post, "charges", params)
  end

  def capture(id, amount, opts \\ %{}) do
    params = Enum.into(opts, [])
      ++ amount_params(amount)

    commit(:post, "charges/#{id}/capture", params)
  end

  def void(id, opts \\ %{}) do
    params = Enum.into(opts, [])
    commit(:post, "charges/#{id}/refund", params)
  end

  def refund(id, amount, opts \\ %{}) do
    params = Enum.into(opts, [])
      ++ amount_params(amount)

    commit(:post, "charges/#{id}/refund", params)
  end

  def store(card, opts \\ %{}) do
    params = Enum.into(opts,[])  
      ++ source_params(card)
    
    commit(:post, "customers", params)
  end

  def unstore(id), do: commit(:delete, "customers/#{id}")

  defp create_params_for_auth_or_purchase(amount, payment, opts, capture \\ true) do
    Enum.into(opts, [])
      ++ [capture: capture]
      ++ amount_params(amount)
      ++ source_params(payment)
      # ++ customer_params(payment)
  end

  defp amount_params(amount), do: [amount: money_to_cents(amount)]

  defp source_params(%{} = card) do
    params = [
      "card[number]": card.number,
      "card[exp_year]": card.exp_year,
      "card[exp_month]": card.exp_month,
      "card[cvc]": card.cvc
    ]

    {:ok, %HTTPoison.Response{body: body}} = create_card_token(params)
    body
      |> Poison.decode!
      |> Map.get("id")
      |> source_params
  end

  defp source_params(token), do: [source: token]

  # defp customer_params(customer_id), do: [customer: customer_id]

  defp address_params(%{} = address) do
    ["source[address_line1]": address.street1,
     "source[address_line2]": address.street2,
     "source[address_city]":  address.city,
     "source[address_state]": address.region,
     "source[address_zip]":   address.postal_code,
     "source[address_country]": address.country]
  end

  defp address_params(_), do: []

  defp create_card_token(params) do
    commit(:post, "tokens", params)
  end

  defp commit(method, path, params) do
    headers = [{"Content-Type", "application/x-www-form-urlencoded"}, {"Authorization", "Bearer sk_test_vIX41hayC0BKrPWQerLuOMld"}]
    data = params_to_string(params)

    HTTPoison.request(method, "#{@base_url}/#{path}", data, headers)
  end
  
end
