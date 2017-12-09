defmodule Kuber.Hex.Gateways.Stripe do
  @base_url "https://api.stripe.com/v1"

  @cvc_code_translator %{
    "pass" => "M",
    "fail" => "N",
    "unchecked" => "P"
  }

  @avs_code_translator %{
    {"pass", "pass"} => "Y",
    {"pass", "fail"} => "A",
    {"pass", "unchecked"} => "B",
    {"fail", "pass"} => "Z",
    {"fail", "fail"} => "N",
    {"unchecked", "pass"} => "P",
    {"unchecked", "unchecked"} => "I"
  }

  @supported_countries ~w(AT AU BE BR CA CH DE DK ES FI FR GB HK IE IT JP LU MX NL NO NZ PT SE SG US)
  @default_currency "USD"
  @money_format :cents
  @supported_cardtypes ~w(visa, master, american_express, discover, jcb, diners_club, maestro)a

  @homepage_url 'https://stripe.com/'
  @display_name 'Stripe'

  @standard_error_code_mapping %{
    "incorrect_number" => "incorrect_number",
    "invalid_number" => "invalid_number",
    "invalid_expiry_month" => "invalid_expiry_date",
    "invalid_expiry_year" => "invalid_expiry_date",
    "invalid_cvc" => "invalid_cvc",
    "expired_card" => "expired_card",
    "incorrect_cvc" => "incorrect_cvc",
    "incorrect_zip" => "incorrect_zip",
    "card_declined" => "card_declined",
    "call_issuer" => "call_issuer",
    "processing_error" => "processing_error",
    "incorrect_pin" => "incorrect_pin",
    "test_mode_live_card" => "test_mode_live_card"
  }

  @bank_account_holder_type_mapping %{
    "personal" => "individual",
    "business" => "company",
  }

  @minimum_authorize_amounts %{
    "USD" => 100,
    "CAD" => 100,
    "GBP" => 60,
    "EUR" => 100,
    "DKK" => 500,
    "NOK" => 600,
    "SEK" => 600,
    "CHF" => 100,
    "AUD" => 100,
    "JPY" => 100,
    "MXN" => 2000,
    "SGD" => 100,
    "HKD" => 800
  }

  use Kuber.Hex.Gateways.Base

  alias Kuber.Hex.{
    CreditCard,
    Address,
    Response
  }

  def authorize(amount, payment, opts) do
    params = create_params_for_auth_or_purchase(amount, payment, opts, false)
    commit(:post, "charges", params)
  end

  def purchase(amount, payment, opts) do
    params = create_params_for_auth_or_purchase(amount, payment, opts)
    commit(:post, "charges", params)
  end

  defp create_params_for_auth_or_purchase(amount, payment, opts, capture \\ true) do
    Enum.into(opts, [])
      ++ [capture: capture]
      ++ amount_params(amount)
      ++ source_params(payment)
  end

  defp amount_params(amount), do: [amount: money_to_cents(amount)]

  defp source_params(%{} = card) do
    params = [
      "card[number]": card.number,
      "card[exp_year]": card.exp_year,
      "card[exp_month]": card.exp_month,
      "card[cvc]": card.cvc,
      "card[name]": card.name
    ]

    {:ok, %HTTPoison.Response{body: body}} = create_card_token(params)
    body
      |> Poison.decode!
      |> Map.get("id")
      |> source_params
  end

  defp source_params(token), do: [source: token]

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

  # def capture(id, opts) do
  #   params = opts
  #     |> Keyword.get(:amount)
  #     |> amount_params

  #   commit(:post, "charges/#{id}/capture", params, opts)
  # end

  # def void(id, opts),
  #   do: commit(:post, "charges/#{id}/refund", [], opts)

  # def refund(amount, id, opts) do
  #   params = amount_params(amount)

  #   commit(:post, "charges/#{id}/refund", params, opts)
  # end

  # def store(card=%CreditCard{}, opts) do
  #   customer_id = Keyword.get(opts, :customer_id)
  #   params = card_params(card)

  #   path = if customer_id, do: "customers/#{customer_id}/card", else: "customers"

  #   commit(:post, path, params, opts)
  # end

  # def unstore(customer_id, nil, opts),
  #   do: commit(:delete, "customers/#{customer_id}", [], opts)

  # def unstore(customer_id, card_id, opts),
  #   do: commit(:delete, "customers/#{customer_id}/#{card_id}", [], opts)

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
