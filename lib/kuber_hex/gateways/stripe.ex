defmodule Kuber.Hex.Gateways.Stripe do
  @base_url "https://api.stripe.com/v1"

  @default_currency "USD"

  @homepage_url 'https://stripe.com/'
  @display_name 'Stripe'

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

  # defp respond({:ok, %{status_code: 200, body: body}}) do
  #   data = decode!(body)
  #   {cvc_result, avs_result} = verification_result(data)

  #   {:ok, Response.success(authorization: data["id"], raw: data, cvc_result: cvc_result, avs_result: avs_result)}
  # end

  # defp respond({:ok, %{body: body, status_code: status_code}}) do
  #   data = decode!(body)
  #   {code, reason} = error(status_code, data["error"])
  #   {cvc_result, avs_result} = verification_result(data)

  #   {:error, Response.error(code: code, reason: reason, raw: data, cvc_result: cvc_result, avs_result: avs_result)}
  # end

  # defp verification_result(%{"card" => card}) do
  #   cvc_result = @cvc_code_translator[card["cvc_check"]]
  #   avs_result = @avs_code_translator[{card["address_line1_check"], card["address_zip_check"]}]

  #   {cvc_result, avs_result}
  # end

  # defp verification_result(_), do: {"N","N"}

  # defp error(status, _) when status >= 500,            do: {:server_error, nil}
  # defp error(_, %{"type" => "invalid_request_error"}), do: {:invalid_request, nil}
  # defp error(_, %{"code" => "incorrect_number"}),      do: {:declined, :invalid_number}
  # defp error(_, %{"code" => "invalid_expiry_year"}),   do: {:declined, :invalid_expiration}
  # defp error(_, %{"code" => "invalid_expiry_month"}),  do: {:declined, :invalid_expiration}
  # defp error(_, %{"code" => "invalid_cvc"}),           do: {:declined, :invalid_cvc}
  # defp error(_, %{"code" => "rate_limit"}),            do: {:rate_limit, nil}
  # defp error(_, _), do: {:declined, :unknown}
end
