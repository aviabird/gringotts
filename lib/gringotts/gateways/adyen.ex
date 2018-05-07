defmodule Gringotts.Gateways.Adyen do
  @moduledoc """
  [ADYEN][home] gateway implementation.

  For refernce see [ADYEN's API (v2.1) documentation][docs].

  The following features of ADYEN are implemented:

  | Action                       | Method        |
  | ------                       | ------        |

  ## The `opts` argument

  Most `Gringotts` API calls accept an optional `keyword` list `opts` to supply
  optional arguments for transactions with the ADYEN gateway. 

  ## Registering your ADYEN account at `Gringotts`

  After [making an account on ADYEN][dashboard], head to the dashboard and find
  your account "secrets".

  Here's how the secrets map to the required configuration parameters for ADYEN:

  | Config parameter | ADYEN secret    |
  | -------          | ----            |

  [home]: https://www.adyen.com/
  [docs]: https://docs.adyen.com/developers
  [dashboard]: 
  [gs]: https://github.com/aviabird/gringotts/wiki
  [example-repo]: https://github.com/aviabird/gringotts_example
  [currency-support]: https://docs.adyen.com/developers/currency-codes
  [country-support]: https://docs.adyen.com/developers/currency-codes
  [pci-dss]: 
  """

  use Gringotts.Gateways.Base
  use Gringotts.Adapter, required_config: [:username, :password, :account, :mode]

  alias Gringotts.{Response, Money, CreditCard}

  @base_url "https://pal-test.adyen.com/pal/servlet/Payment/v30/"
  @headers [{"Content-Type", "application/json"}]

  @spec authorize(Money.t(), String.t(), keyword) :: {:ok | :error, Response.t()}
  def authorize(amount, card, opts) do
    params = authorize_params(card, amount, opts)
    commit(:post, "authorise", params, opts)
  end

  @spec capture(String.t(), Money.t(), keyword) :: {:ok | :error, Response.t()}
  def capture(id, amount, opts) do
    params = capture_and_refund_params(id, amount, opts)
    commit(:post, "capture", params, opts)
  end

  @spec purchase(Money.t(), String.t(), keyword) :: {:ok | :error, Response.t()}
  def purchase(amount, card, opts) do
    {auth_atom, auth_response} = authorize(amount, card, opts)

    case auth_atom do
      :ok -> capture(auth_response.id, amount, opts)
      _ -> {auth_atom, auth_response}
    end
  end

  @spec refund(Money.t(), String.t(), keyword) :: {:ok | :error, Response.t()}
  def refund(amount, id, opts) do
    param = capture_and_refund_params(id, amount, opts)
    commit(:post, "refund", param, opts)
  end

  @spec void(String.t(), keyword) :: {:ok | :error, Response.t()}
  def void(id, opts) do
    param = void_params(id, opts)
    commit(:post, "cancel", param, opts)
  end

  defp authorize_params(%CreditCard{} = rec_card, amount, opts) do
    case Keyword.get(opts, :requestParameters) do
      nil ->
        body = get_authorize_params(rec_card, amount, opts)

      _ ->
        body = Enum.into(opts[:requestParameters], get_authorize_params(rec_card, amount, opts))
    end

    Poison.encode!(body)
  end

  defp get_authorize_params(rec_card, amount, opts) do
    %{
      card: card_map(rec_card),
      amount: amount_map(amount),
      merchantAccount: opts[:config][:account]
    }
  end

  defp capture_and_refund_params(id, amount, opts) do
    case Keyword.get(opts, :requestParameters) do
      nil ->
        body = get_capture_and_refund_params(id, amount, opts)

      _ ->
        body =
          Enum.into(opts[:requestParameters], get_capture_and_refund_params(id, amount, opts))
    end

    Poison.encode!(body)
  end

  defp get_capture_and_refund_params(id, amount, opts) do
    %{
      originalReference: id,
      modificationAmount: amount_map(amount),
      merchantAccount: opts[:config][:account]
    }
  end

  defp void_params(id, opts) do
    case Keyword.get(opts, :requestParameters) do
      nil ->
        body = get_void_params(id, opts)

      _ ->
        body = Enum.into(opts[:requestParameters], get_void_params(id, opts))
    end

    Poison.encode!(body)
  end

  defp get_void_params(id, opts) do
    %{
      originalReference: id,
      merchantAccount: opts[:config][:account]
    }
  end

  defp card_map(%CreditCard{} = rec_card) do
    %{
      number: rec_card.number,
      expiryMonth: rec_card.month,
      expiryYear: rec_card.year,
      cvc: rec_card.verification_code,
      holderName: CreditCard.full_name(rec_card)
    }
  end

  defp amount_map(amount) do
    {currency, int_value, _} = Money.to_integer(amount)

    %{
      value: int_value,
      currency: currency
    }
  end

  defp commit(method, endpoint, params, opts) do
    head = headers(opts)

    method
    |> HTTPoison.request(base_url(opts) <> endpoint, params, headers(opts))
    |> respond(opts)
  end

  defp respond({:ok, response}, opts) do
    case Poison.decode(response.body) do
      {:ok, parsed_resp} ->
        gateway_code = parsed_resp["status"]

        status = if gateway_code == 200 || response.status_code == 200, do: :ok, else: :error

        {status,
         %Response{
           id: parsed_resp["pspReference"],
           status_code: response.status_code,
           gateway_code: gateway_code,
           reason: parsed_resp["errorType"],
           message:
             parsed_resp["message"] || parsed_resp["resultCode"] || parsed_resp["response"],
           raw: response.body
         }}

      :error ->
        {:error, %Response{raw: response.body, reason: "could not parse ADYEN response"}}
    end
  end

  defp respond({:error, %HTTPoison.Error{} = response}, opts) do
    {
      :error,
      Response.error(
        reason: "network related failure",
        message: "HTTPoison says '#{response.reason}' [ID: #{response.id || "nil"}]"
      )
    }
  end

  defp headers(opts) do
    arg = get_in(opts, [:config, :username]) <> ":" <> get_in(opts, [:config, :password])

    [
      {"Authorization", "Basic #{Base.encode64(arg)}"}
      | @headers
    ]
  end

  defp base_url(opts), do: opts[:config][:url] || @base_url
end
