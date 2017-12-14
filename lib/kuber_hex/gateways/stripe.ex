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

  use Kuber.Hex.Gateways.Base
  use Kuber.Hex.Adapter, required_config: [:api_key, :default_currency]

  alias Kuber.Hex.{
    CreditCard,
    Address,
    Response
  }

  import Poison, only: [decode!: 1]

  def purchase(amount, card_or_id, opts),
    do: authorize(amount, card_or_id, [{:capture, true} | opts])


  def authorize(amount, card_or_id, opts) do
    config      = Keyword.fetch!(opts, :config)
    # TODO: Verify if params passed in requests are merged to config 
    # for description, address, customer_id, capture
    description = Keyword.get(opts, :description)
    address     = Keyword.get(opts, :billing_address)
    customer_id = Keyword.get(opts, :customer_id)
    capture     = Keyword.get(opts, :capture, false)
    # Picking from adapter config 
    currency    = config[:default_currency]

    params = [capture: capture, description: description,
              currency: currency, customer: customer_id] ++
             amount_params(amount) ++
             card_params(card_or_id) ++
             address_params(address) ++
             connect_params(opts)

    commit(:post, "charges", params, opts)
  end

  def capture(id, amount, opts) do
    params = amount_params(amount)
    commit(:post, "charges/#{id}/capture", params, opts)
  end

  def void(id, opts),
    do: commit(:post, "charges/#{id}/refund", [], opts)

  def refund(amount, id, opts) do
    params = amount_params(amount)

    commit(:post, "charges/#{id}/refund", params, opts)
  end

  def store(card=%CreditCard{}, opts) do
    customer_id = Keyword.get(opts, :customer_id)
    params = card_params(card)

    path = if customer_id, do: "customers/#{customer_id}/card", else: "customers"

    commit(:post, path, params, opts)
  end

  def unstore(customer_id, nil, opts),
    do: commit(:delete, "customers/#{customer_id}", [], opts)

  def unstore(customer_id, card_id, opts),
    do: commit(:delete, "customers/#{customer_id}/#{card_id}", [], opts)

  defp amount_params(amount),
    do: [amount: money_to_cents(amount)]

  defp card_params(card=%CreditCard{}) do
    {expiration_year, expiration_month} = card.expiration

    ["card[number]":    card.number,
     "card[exp_year]":  expiration_year,
     "card[exp_month]": expiration_month,
     "card[cvc]":       card.verification_code,
     "card[name]":      card.name]
  end

  defp card_params(id), do: [card: id]

  defp address_params(address=%Address{}) do
    ["card[address_line1]": address.street1,
     "card[address_line2]": address.street2,
     "card[address_city]":  address.city,
     "card[address_state]": address.region,
     "card[address_zip]":   address.postal_code,
     "card[address_country]": address.country]
  end

  defp address_params(_), do: []

  defp connect_params(opts),
    do: Keyword.take(opts, [:destination, :application_fee])

  defp commit(method, path, params, opts) do
    config = Keyword.fetch!(opts, :config)
    # TODO: credentials should be investigated why it is {api_key, ""}
    # Did to mimic the earlier behavior.
    method
      |> http("#{@base_url}/#{path}", params, credentials: {config[:api_key], ""})
      |> respond
  end

  defp respond({:ok, %{status_code: 200, body: body}}) do
    data = decode!(body)
    {cvc_result, avs_result} = verification_result(data)
    {:ok, Response.success(authorization: data["id"], raw: data, cvc_result: cvc_result, avs_result: avs_result)}
  end

  defp respond({:ok, %{body: body, status_code: status_code}}) do
    data = decode!(body)
    {code, reason} = error(status_code, data["error"])
    {cvc_result, avs_result} = verification_result(data)

    {:error, Response.error(code: code, reason: reason, raw: data, cvc_result: cvc_result, avs_result: avs_result)}
  end

  defp verification_result(%{"card" => card}) do
    cvc_result = @cvc_code_translator[card["cvc_check"]]
    avs_result = @avs_code_translator[{card["address_line1_check"], card["address_zip_check"]}]

    {cvc_result, avs_result}
  end

  defp verification_result(_), do: {"N","N"}

  defp error(status, _) when status >= 500,            do: {:server_error, nil}
  defp error(_, %{"type" => "invalid_request_error"}), do: {:invalid_request, nil}
  defp error(_, %{"code" => "incorrect_number"}),      do: {:declined, :invalid_number}
  defp error(_, %{"code" => "invalid_expiry_year"}),   do: {:declined, :invalid_expiration}
  defp error(_, %{"code" => "invalid_expiry_month"}),  do: {:declined, :invalid_expiration}
  defp error(_, %{"code" => "invalid_cvc"}),           do: {:declined, :invalid_cvc}
  defp error(_, %{"code" => "rate_limit"}),            do: {:rate_limit, nil}
  defp error(_, _), do: {:declined, :unknown}
end
