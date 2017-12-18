defmodule Kuber.Hex.Gateways.Monei do
  @moduledoc ~S"""
  An API client for the [MONEI](https://www.monei.net) gateway.

  For reference see [MONEI's API (v1) documentation](https://docs.monei.net).

  The following features of MONEI are implemented:
  
  * `PA` **Pre-Authorize**\
  In `authorize/3`.

  * `CP` **Capture**\
  In `capture/3`.

  * `RF` **Refund**\
  In `refund/3` and ~~also `void/2`~~.

  * `RV` **Reversal**\
  In `void/2`.

  * `DB` **Debit**\
  In `purchase/3`.
  
  * **Tokenization** and **Registrations**\
  In `store/2` ~~and `unstore/2`~~.

  ## The `opts` argument

  This is a `Keyword` list of optional arguments for transactions with the MONEI
  gateway. The following keys are supported:

  | Key                 | Remark | Status          |
  | ----                | ---    | ----            |
  | `billing_address`   |        | Not implemented |
  | `shipping_address`  |        | Not implemented |
  | `customer`          |        | Not implemented |
  | `shipping_customer` |        | Not implemented |
  | `merchant`          |        | Not implemented |
  | `cart`              |        | Not implemented |
  | `invoice`           |        | Not implemented |
  | `customParameters`  |        | Not implemented |
  | `currency`          |        | Not implemented |

  ## MONEI _quirks_

  * MONEI does not process money in cents, and the `amount` is rounded to 2 decimal places.

  ## Caveats

  Although MONEI supports payments from [various cards](https://support.monei.net/charges-and-refunds/accepted-credit-cards-payment-methods), banks and virtual accounts (like some wallets), this library only accepts payments by (supported) cards.

  ## TODO

  * [Backoffice operations](https://docs.monei.net/tutorials/manage-payments/backoffice)
    - Credit
    - Rebill
  * [Recurring payments](https://docs.monei.net/recurring)
  * [Reporting](https://docs.monei.net/tutorials/reporting)
  
  """
  
  use Kuber.Hex.Adapter, required_config: [:userId, :entityId, :password]
  import Poison, only: [decode: 1]
  alias Kuber.Hex.{CreditCard, Response}
  
  @base_url "https://test.monei-api.net"
  @default_headers ["Content-Type": "application/x-www-form-urlencoded",
                    "charset": "UTF-8"]
  @default_currency "EUR"
  
  @version "v1"

  @cvc_code_translator %{
    "M" => "pass",
    "N" => "fail",
    "P" => "not_processed",
    "U" => "issuer_unable",
    "S" => "issuer_unable"
  }

  @avs_code_translator %{
    "F" => {"pass", "pass"},
    "A" => {"pass", "fail"},
    "Z" => {"fail", "pass"},
    "N" => {"fail", "fail"},
    "U" => {"error", "error"},
    nil => {nil, nil}
  }
  
  # MONEI supports payment by card, bank account and even something obscure: virtual account
  # opts has the auth keys.

  @doc """  
  Performs a (pre) Authorize operation.

  The authorization validates the `card` details with the banking network,
  places a hold on the transaction `amount` in the customer’s issuing bank also
  triggers risk management. Funds are not transferred.

  MONEI returns an ID string which can be used to:

  * `capture/3` _an_ amount.
  * `void/2` a pre-authorization.

  ### Note  
  
  A stand-alone pre-authorization [expires in
  72hrs](https://docs.monei.net/tutorials/manage-payments/backoffice).
  """
  @spec authorize(number, CreditCard, keyword) :: Response
  def authorize(amount, card = %CreditCard{}, opts) when is_integer(amount) do
    authorize(amount / 1, card, opts)
  end
  
  def authorize(amount, card = %CreditCard{}, opts) when is_float(amount) do
    params = [paymentType: "PA",
              amount: :erlang.float_to_binary(amount, decimals: 2),
              currency: currency(opts)] ++ card_params(card)
    auth_info = Keyword.fetch!(opts, :config)
    commit(:post, "payments", params, auth_info)
  end

  @doc """  
  Captures a pre-authorized `amount`.

  `amount` is transferred to the merchant account by MONEI when it is smaller or
  equal to the amount used in the pre-authorization referenced by `paymentId`.

  ### Note

  MONEI allows partial captures and unlike many other gateways, does not release
  the remaining amount back to the payment source. Thus, the same
  pre-authorisation ID can be used to perform multiple captures, till:
  * all the pre-authorized amount is captured or,
  * the remaining amount is explicitly "reversed" via `void/2`. **[citation-needed]**
  """
  @spec capture(number, String.t, keyword) :: Response
  def capture(amount, paymentId, opts)
  def capture(amount, <<paymentId::bytes-size(32)>>, opts) when is_integer(amount) do
    capture(amount / 1, paymentId, opts)
  end
  
  def capture(amount, <<paymentId::bytes-size(32)>>, opts) when is_float(amount) do
    params = [paymentType: "CP",
              amount: :erlang.float_to_binary(amount, decimals: 2),
              currency: currency(opts)]
    auth_info = Keyword.fetch!(opts, :config)
    commit(:post, "payments/#{paymentId}", params, auth_info)
  end

  @doc """
  Credits the merchant account with `amount` by debiting the account of the customer.
  
  MONEI attempts to debit the customer to accept a payment of `amount` with the
  given `card`.
  """
  @spec purchase(number, CreditCard, keyword) :: Response
  def purchase(amount, card = %CreditCard{}, opts) when is_integer(amount) do purchase(amount / 1, card, opts) end
  
  def purchase(amount, card = %CreditCard{}, opts) when is_float(amount) do
    params = [paymentType: "DB",
              amount: :erlang.float_to_binary(amount, decimals: 2),
              currency: currency(opts)] ++ card_params(card)
    auth_info = Keyword.fetch!(opts, :config)
    commit(:post, "payments", params, auth_info)
  end

  @doc """
  Voids the referenced payment.

  This method attempts a reversal of the `paymentId` referencing either a
  previous `purchase/3` or `authorize/3`.

  ## Voiding a previous authorization
  
  MONEI will reverse the authorization by sending a "reversal request" to be
  sent the payment source (card issuer) to clear the funds held against the
  authorization. If some of the authorized amount was captured, only the
  remaining amount is cleared. **[citation-needed]**

  ## Voiding a previous purchase

  MONEI will reverse the payment, by sending all the amount back to the
  customer.

  As a consequence, the customer will never see any booking on his
  statement. Refer MONEI's [Backoffice
  Operations](https://docs.monei.net/tutorials/manage-payments/backoffice)
  guide.
  """  
  @spec void(String.t, keyword) :: Response
  def void(paymentId, opts)
  def void(<<paymentId::bytes-size(32)>>, opts) do
    params = [paymentType: "RV"]
    auth_info = Keyword.fetch!(opts, :config)
    commit(:post, "payments/#{paymentId}", params, auth_info)
  end

  @doc """
  Credits the account of the customer with a reference to a prior transfer.

  MONEI can process a full or partial refund worth `amount`, referencing a
  previous `purchase/3` or `capture/3`ed.

  The end customer will always see two bookings/records on his statement.  Refer
  MONEI's [Backoffice
  Operations](https://docs.monei.net/tutorials/manage-payments/backoffice)
  guide.
  """
  @spec refund(number, String.t, keyword) :: Response
  def refund(amount, paymentId, opts)
  def refund(amount, <<paymentId::bytes-size(32)>>, opts) do
    params = [paymentType: "RF",
              amount: :erlang.float_to_binary(amount, decimals: 2),
              currency: currency(opts)]
    auth_info = Keyword.fetch!(opts, :config)
    commit(:post, "payments/#{paymentId}", params, auth_info)
  end

  @doc """
  Stores the payment-source data for later use.

  MONEI can store the payment-source details, for example card or bank details
  which can be used to effectively process _One-Click_ and _Recurring_ payments,
  and return a registration token for reference.

  It is recommended to associate these details with a "Customer" by passing
  customer details in the `opts`.

  ### Note

  * _One-Click_ and _Recurring_ payments are currently not implemented.
  * Payment details can be saved during a `purchase/3` or `capture/3`.
  """
  @spec store(CreditCard, keyword) :: Response
  def store(card = %CreditCard{}, opts) do
    params = card_params(card)
    auth_info = Keyword.fetch!(opts, :config)
    commit(:post, "registrations", params, auth_info)
  end

  @doc """
  WIP

  **MONEI unstore does not seem to work. MONEI always returns a `403`**

  Deletes previously stored payment-source data.
  """
  @spec unstore(String.t, keyword) :: Response
  def unstore(<<registrationId::bytes-size(32)>>, opts) do
    auth_info = Keyword.fetch!(opts, :config)
    commit(:delete, "registrations/#{registrationId}", [], auth_info)
  end


  
  defp card_params(card) do
    ["card.number": card.number,
     "card.holder": "#{card.first_name} #{card.last_name}",
     "card.expiryMonth": card.month |> Integer.to_string |> String.pad_leading(2, "0"),
     "card.expiryYear": card.year |> Integer.to_string,
     "card.cvv": card.verification_code,
     "paymentBrand": card.brand]
  end

  @doc """
  Makes the request to MONEI's network.
  """
  @spec commit(atom, String.t, keyword, keyword) ::
  {:ok, HTTPoison.Response} |
  {:error, HTTPoison.Error}
  def commit(method, endpoint, params, opts) do
    auth_params = ["authentication.userId": opts[:userId],
                   "authentication.password": opts[:password],
                   "authentication.entityId": opts[:entityId]]
    body = params ++ auth_params
    url = "#{base_url(opts)}/#{version(opts)}/#{endpoint}"
    case method do
      :post -> HTTPoison.post(url, {:form, body}, @default_headers) |> respond
      :delete -> HTTPoison.delete(url  <> "?" <> URI.encode_query(auth_params)) |> respond
    end
  end

  @doc """
  Parses MONEI's response and returns a `Response` struct in a `:ok`, `:error` tuple.
  """
  def respond({:ok, %{status_code: 200, body: body}}) do
    case decode(body) do
      {:ok, decoded_json} -> case verification_result(decoded_json) do
                               {:ok, results} -> {:ok, Response.success([{:id, decoded_json["id"]} | results])}
                               {:error, errors} -> {:ok, Response.error([{:id, decoded_json["id"]} | errors])}
                             end
      {:error, _} -> {:error, Response.error(raw: body, code: :undefined_response_from_monei)}
    end
  end

  def respond({:ok, %{status_code: status_code, body: body}}) do
    {:error, Response.error(code: status_code, raw: body)}
  end

  def respond({:error, %HTTPoison.Error{} = error}) do
    {:error, Response.error(code: error.id, reason: :network_fail?, description: "HTTPoison says '#{error.reason}'")}
  end

  defp verification_result(data = %{"result" => result}) do
    {address, zip_code} = @avs_code_translator[result["avsResponse"]]
    code = result["code"]
    results = [code: code,
               description: result["description"],
               risk: data["risk"]["score"],
               cvc_result: @cvc_code_translator[result["cvvResponse"]],
               avs_result: [address: address, zip_code: zip_code],
               raw: data]

    cond do
      String.match?(code, ~r{^(000\.000\.|000\.100\.1|000\.[36])}) -> {:ok, results}
      true -> {:error, [{:reason, result["description"]} | results]}
    end
  end

  defp base_url(opts), do: opts[:test_url] || @base_url
  defp currency(opts), do: opts[:currency] || @default_currency
  defp version(opts), do: opts[:api_version] || @version
end


