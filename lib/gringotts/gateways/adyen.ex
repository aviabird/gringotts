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
  use Gringotts.Adapter, required_config: [:username, :password, :account, :mode, :url]

  alias Gringotts.{Response, Money, CreditCard}

  @base_url "https://pal-test.adyen.com/pal/servlet/Payment/v30/"
  @headers [{"Content-Type", "application/json"}]

  @spec authorize(Money.t(), CreditCard.t(), keyword) :: {:ok | :error, Response.t()}
  def authorize(amount, card, opts) do
    params = authorize_params(card, amount, opts)
    commit(:post, "authorise", params, opts)
  end

  @spec capture(String.t(), Money.t(), keyword) :: {:ok | :error, Response.t()}
  def capture(id, amount, opts) do
    params = capture_and_refund_params(id, amount, opts)
    commit(:post, "capture", params, opts)
  end

  @spec purchase(Money.t(), CreditCard.t(), keyword) :: {:ok | :error, Response.t()}
  def purchase(amount, card, opts) do
    {auth_atom, auth_response} = authorize(amount, card, opts)

    case auth_atom do
      :ok -> capture(auth_response.id, amount, opts)
      _ -> {auth_atom, auth_response}
    end
  end

  @spec refund(Money.t(), String.t(), keyword) :: {:ok | :error, Response.t()}
  def refund(amount, id, opts) do
    params = capture_and_refund_params(id, amount, opts)
    commit(:post, "refund", params, opts)
  end

  @spec void(String.t(), keyword) :: {:ok | :error, Response.t()}
  def void(id, opts) do
    params = void_params(id, opts)
    commit(:post, "cancel", params, opts)
  end

  defp merge_keyword_list_to_map(exclude_keys, keyword_list, map) do
    keyword_list
    |> Keyword.drop(exclude_keys)
    |> Map.new()
    |> Map.merge(map)
  end

  defp authorize_params(%CreditCard{} = card, amount, opts) do
    body = merge_keyword_list_to_map([:config], opts, get_authorize_params(card, amount, opts))

    Poison.encode!(body)
  end

  defp get_authorize_params(card, amount, opts) do
    %{
      card: card_params(card),
      amount: amount_params(amount),
      merchantAccount: opts[:config][:account]
    }
  end

  defp capture_and_refund_params(id, amount, opts) do
    body =
      merge_keyword_list_to_map([:config], opts, get_capture_and_refund_params(id, amount, opts))

    Poison.encode!(body)
  end

  defp get_capture_and_refund_params(id, amount, opts) do
    %{
      originalReference: id,
      modificationAmount: amount_params(amount),
      merchantAccount: opts[:config][:account]
    }
  end

  defp void_params(id, opts) do
    body = merge_keyword_list_to_map([:config], opts, get_void_params(id, opts))

    Poison.encode!(body)
  end

  defp get_void_params(id, opts) do
    %{
      originalReference: id,
      merchantAccount: opts[:config][:account]
    }
  end

  defp card_params(%CreditCard{} = card) do
    %{
      number: card.number,
      expiryMonth: card.month,
      expiryYear: card.year,
      cvc: card.verification_code,
      holderName: CreditCard.full_name(card)
    }
  end

  defp amount_params(amount) do
    {currency, int_value, _} = Money.to_integer(amount)

    %{
      value: int_value,
      currency: currency
    }
  end

  defp commit(method, endpoint, params, opts) do
    method
    |> HTTPoison.request(base_url(opts) <> endpoint, params, headers(opts))
    |> respond
  end

  defp respond({:ok, response}) do
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

  defp respond({:error, %HTTPoison.Error{} = response}) do
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

  defp base_url(opts) do
    if opts[:config][:mode] == :test do
      @base_url
    else
      opts[:config][:url]
    end
  end
end
