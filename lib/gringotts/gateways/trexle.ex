defmodule Gringotts.Gateways.Trexle do

  @moduledoc """
  Trexle Payment Gateway Implementation:

  For further details, please refer [Trexle API documentation](https://docs.trexle.com/).

  Following are the features that have been implemented for the Trexle Gateway:

  | Action                       | Method        |
  | ------                       | ------        |
  | Authorize                    | `authorize/3` |
  | Purchase                     | `purchase/3`  |
  | Capture                      | `capture/3`   |
  | Refund                       | `refund/3`    |
  | Store                        | `store/2`     |

  ## The `opts` argument
  A `Keyword` list `opts` passed as an optional argument for transactions with the gateway. Following are the keys
  supported:

  * email
  * ip_address
  * description

  ## Trexle account registeration with `Gringotts`
  After creating your account successfully on [Trexle](https://docs.trexle.com/) follow the [dashboard link](https://trexle.com/dashboard/api-keys) to fetch the secret api_key.

  Your Application config must look something like this:

      config :gringotts, Gringotts.Gateways.Trexle,
          adapter: Gringotts.Gateways.Trexle,
          api_key: "Secret API key",
          default_currency: "USD"
  """

  @base_url "https://core.trexle.com/api/v1/"

  use Gringotts.Gateways.Base
  use Gringotts.Adapter, required_config: [:api_key, :default_currency]
  import Poison, only: [decode: 1]
  alias Gringotts.{Response, CreditCard, Address}

  @doc """
  Performs the authorization of the card to be used for payment.

  Authorizes your card with the given amount and returns a charge token and captured status as false in response.

  ### Example
  ```
  iex> amount = 100

  iex> card = %CreditCard{
    number: "5200828282828210",
    month: 12,
    year: 2018,
    first_name: "John",
    last_name: "Doe",
    verification_code: "123",
    brand: "visa"
  }

  iex> @address %Address{
    street1: "123 Main",
    street2: "Suite 100",
    city: "New York",
    region: "NY",
    country: "US",
    postal_code: "11111",
    phone: "(555)555-5555"
  }

  iex> options = [email: "john@trexle.com", ip_address: "66.249.79.118", billing_address: @address, description: "Store Purchase 1437598192"]

  iex> Gringotts.authorize(:payment_worker, Gringotts.Gateways.Trexle, amount, card, options)
  ```
  """

  @spec authorize(float, CreditCard.t, list) :: map
  def authorize(amount, payment, opts \\ []) do
    params = create_params_for_auth_or_purchase(amount, payment, opts, false)
    commit(:post, "charges", params, opts)
  end

  @doc """
  Performs the amount transfer from the customer to the merchant.

  The actual amount deduction performed by Trexle using the customer's card info.

  ## Example
  ```
  iex> card = %CreditCard{
    number: "5200828282828210",
    month: 12,
    year: 2018,
    first_name: "John",
    last_name: "Doe",
    verification_code: "123",
    brand: "visa"
  }

  iex> @address %Address{
    street1: "123 Main",
    street2: "Suite 100",
    city: "New York",
    region: "NY",
    country: "US",
    postal_code: "11111",
    phone: "(555)555-5555"
  }

  iex> options = [email: "john@trexle.com", ip_address: "66.249.79.118" ,billing_address: @address, description: "Store Purchase 1437598192"]

  iex> amount = 50

  iex> Gringotts.purchase(:payment_worker, Gringotts.Gateways.Trexle, amount, card, options)
  ```
  """

  @spec purchase(float, CreditCard.t, list) :: map
  def purchase(amount, payment, opts \\ []) do
    params = create_params_for_auth_or_purchase(amount, payment, opts)
    commit(:post, "charges", params, opts)
  end

  @doc """
  Captures a particular amount using the charge token of a pre authorized card.

  The amount specified should be less than or equal to the amount given prior to capture while authorizing the card.
  If the amount mentioned is less than the amount given in authorization process, the mentioned amount is debited.
  Please note that multiple captures can't be performed for a given charge token from the authorization process.

  ### Example
  ```
  iex> amount = 100

  iex> token = "charge_6a5fcdc6cdbf611ee3448a9abad4348b2afab3ec"

  iex> Gringotts.capture(:payment_worker, Gringotts.Gateways.Trexle, token, amount)
  ```
  """

  @spec capture(String.t, float, list) :: map
  def capture(charge_token, amount, opts \\ []) do
    params = [amount: amount]
    commit(:put, "charges/#{charge_token}/capture", params, opts)
  end

  @doc """
  Refunds the amount to the customer's card with reference to a prior transfer.

  Trexle processes a full or partial refund worth `amount`, referencing a
  previous `purchase/3` or `capture/3`.

  Multiple refund can be performed for the same charge token from purchase or capture done before performing refund action unless the cumulative amount is less than the amount given while authorizing.

  ## Example
  The following session shows how one would refund a previous purchase (and similarily for captures).
  ```
  iex> amount = 5

  iex> token = "charge_668d3e169b27d4938b39246cb8c0890b0bd84c3c"

  iex> options = [email: "john@trexle.com", ip_address: "66.249.79.118", description: "Store Purchase 1437598192"]

  iex> Gringotts.refund(:payment_worker, Gringotts.Gateways.Trexle, amount, token, options)
  ```
  """

  @spec refund(float, String.t, list) :: map
  def refund(amount, charge_token, opts \\ []) do
    params = [amount: amount]
    commit(:post, "charges/#{charge_token}/refunds", params, opts)
  end

  @doc """
  Stores the card information for future use.

  ## Example
  The following session shows how one would store a card (a payment-source) for future use.
  ```
  iex> card = %CreditCard{
    number: "5200828282828210",
    month: 12,
    year: 2018,
    first_name: "John",
    last_name: "Doe",
    verification_code: "123",
    brand: "visa"
  }

  iex> @address %Address{
    street1: "123 Main",
    street2: "Suite 100",
    city: "New York",
    region: "NY",
    country: "US",
    postal_code: "11111",
    phone: "(555)555-5555"
  }

  iex> options = [email: "john@trexle.com", ip_address: "66.249.79.118", billing_address: @address, description: "Store Purchase 1437598192"]

  iex> Gringotts.store(:payment_worker, Gringotts.Gateways.Trexle, card, options)
  ```
  """

  @spec store(CreditCard.t, list) :: map
  def store(payment, opts \\ []) do
    params = [
              email: opts[:email]
            ]
            ++ card_params(payment)
            ++ address_params(opts[:billing_address])
    commit(:post, "customers", params, opts)
  end

  defp create_params_for_auth_or_purchase(amount, payment, opts, capture \\ true) do
    [
      capture: capture,
      amount: amount,
      currency: opts[:config][:default_currency],
      email: opts[:email],
      ip_address: opts[:ip_address],
      description: opts[:description]
    ] ++ card_params(payment)
      ++ address_params(opts[:billing_address])
  end

  defp card_params(%CreditCard{} = card) do
    card = Map.from_struct(card)
    [
      "card[name]": card[:first_name],
      "card[number]": card[:number],
      "card[expiry_year]": card[:year],
      "card[expiry_month]": card[:month],
      "card[cvc]": card[:verification_code]
    ]
  end

  defp address_params(%Address{} = address) do
    address = Map.from_struct(address)
    [
      "card[address_line1]": address[:street1],
      "card[address_line2]": address[:street2],
      "card[address_city]": address[:city],
      "card[address_postcode]": address[:postal_code],
      "card[address_state]": address[:region],
      "card[address_country]": address[:country]
    ]
  end

  defp commit(method, path, params \\ [], opts \\ []) do
    auth_token = "Basic #{Base.encode64(opts[:config][:api_key])}"
    headers = [{"Content-Type", "application/x-www-form-urlencoded"}, {"Authorization", auth_token}]
    data = params_to_string(params)
    options = [hackney: [:insecure, basic_auth: {opts[:config][:api_key], "password"}]]
    url = "#{@base_url}#{path}"
    response = HTTPoison.request(method, url, data, headers, options)
    response |> respond
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
