defmodule Gringotts.Gateways.Cams do
  @moduledoc """
  [CAMS][home] gateway implementation.

  CAMS provides a [sandbox account][dashboard] with documentation under the
  [`integration` tab][docs]. The login credentials are:

  | Key      | Credentials        |
  | ------   | --------           |
  | username | `testintegrationc` |
  | password | `password9`        |

  The [video tutorials][videos] (on vimeo) are excellent.

  The following features of CAMS are implemented:

  | Action                       | Method        |
  | ------                       | ------        |
  | Authorize                    | `authorize/3` |
  | Capture                      | `capture/3`   |
  | Purchase                     | `purchase/3`  |
  | Refund                       | `refund/3`    |
  | Cancel                       | `void/2`      |

  ## The `opts` argument

  Most `Gringotts` API calls accept an optional `keyword` list `opts` to supply
  optional arguments for transactions with the CAMS gateway. The following keys
  are supported:

  | Key               | Type       | Remark                                           |
  | ----              | ----       | ---                                              |
  | `billing_address` | `map`      | The address of the customer                      |
  | `order_id`        | `String.t` | Merchant provided identifier                     |
  | `description`     | `String.t` | Merchant provided description of the transaction |

  > CAMS supports more optional keys and you can raise an [issue][issues] if
    this is important to you.

  [issues]: https://github.com/aviabird/gringotts/issues/new

  ### Schema

  * `billing_address` is a `map` from `atoms` to `String.t`, and can include any
    of the keys from:
    `:name, :address1, :address2, :company, :city, :state, :zip, :country, :phone, :fax]`

  ## Registering your CAMS account at `Gringotts`

  | Config parameter | CAMS secret   |
  | -------          | ----          |
  | `:username`      | **Username**  |
  | `:password`      | **Password**  |

  > Your Application config **must include the `:username`, `:password`
  > fields** and would look something like this:

      config :gringotts, Gringotts.Gateways.Cams,
          username: "your_secret_user_name",
          password: "your_secret_password",

  ## Scope of this module

  * CAMS **does not** process money in cents.
  * Although CAMS supports payments from electronic check & various cards this module only
  accepts payments via `VISA`, `MASTER`, `AMERICAN EXPRESS` and `DISCOVER`.

  ## Supported countries
  **citation-needed**

  ## Supported currencies
  **citation-needed**

  ## Following the examples

  1. First, set up a sample application and configure it to work with CAMS.
    - You could do that from scratch by following our [Getting Started][gs] guide.
    - To save you time, we recommend [cloning our example][example-repo] that
      gives you a pre-configured sample app ready-to-go.
      + You could use the same config or update it the with your "secrets" that
        you get after [registering with
        CAMS](#module-registering-your-cams-account-at-gringotts).

  2. To save a lot of time, create a [`.iex.exs`][iex-docs] file as shown in
     [this gist][cams.iex.exs] to introduce a set of handy bindings and
     aliases.

  We'll be using these bindings in the examples below.

  [example-repo]: https://github.com/aviabird/gringotts_example
  [iex-docs]: https://hexdocs.pm/iex/IEx.html#module-the-iex-exs-file
  [cams.iex.exs]: https://gist.github.com/oyeb/9a299df95cc13a87324e321faca5c9b8

  ## Integrating with phoenix

  Refer the [GringottsPay][gpay-heroku-cams] website for an example of how to
  integrate CAMS with phoenix. The source is available [here][gpay-repo].

  [gpay-repo]: https://github.com/aviabird/gringotts_payment
  [gpay-heroku-cams]: http://gringottspay.herokuapp.com/cams

  ## TODO

  * Operations using Credit Card
    - Credit

  * Operations using electronic checks
    - Sale
    - Void
    - Refund

  [home]: http://www.centralams.com/
  [docs]: https://secure.centralams.com/merchants/resources/integration/integration_portal.php?tid=d669ab54bb17e34c5ff2cfe504f033e7
  [dashboard]: https://secure.centralams.com
  [videos]: https://secure.centralams.com/merchants/video.php?tid=d669ab54bb17e34c5ff2cfe504f033e7
  [gs]: #
  [example-repo]: https://github.com/aviabird/gringotts_example
  """

  use Gringotts.Gateways.Base
  use Gringotts.Adapter, required_config: [:username, :password]

  alias Gringotts.{CreditCard, Response, Money}
  alias Gringotts.Gateways.Cams.ResponseHandler, as: ResponseParser

  @live_url "https://secure.centralams.com/gw/api/transact.php"
  @headers [{"Content-Type", "application/x-www-form-urlencoded"}]

  @doc """
  Performs a (pre) Authorize operation.

  The authorization validates the `card` details with the banking network,
  places a hold on the transaction `amount` in the customer’s issuing bank and
  also triggers risk management. Funds are not transferred.

  When followed up with a `capture/3` transaction, funds will be transferred to
  the merchant's account upon settlement.

  CAMS returns a **Transaction ID** (available in the `Response.authorization`
  field) which can be used later to:
  * `capture/3` an amount.
  * `void/2` an authorized transaction.

  ## Optional Fields
      options[
        order_id: String,
        description: String
      ]

  ## Examples

  The following example shows how one would (pre) authorize a payment of $20 on
  a sample `card`.
  ```
  iex> card = %CreditCard{first_name: "Harry",
                          last_name: "Potter",
                          number: "4111111111111111",
                          year: 2099,
                          month: 12,
                          verification_code: "999",
                          brand: "VISA"}
  iex> money = Money.new(20, :USD)
  iex> {:ok, auth_result} = Gringotts.authorize(Gringotts.Gateways.Cams, money, card)
  ```
  """
  @spec authorize(Money.t(), CreditCard.t(), keyword) :: {:ok | :error, Response.t()}
  def authorize(money, %CreditCard{} = card, options) do
    params =
      []
      |> add_invoice(money)
      |> add_payment(card)
      |> add_address(card, options)

    commit("auth", params, options)
  end

  @doc """
  Captures a pre-authorized amount.

  Captures can be submitted for an `amount` equal to or less than the originally
  authorized `amount` in an `authorize/3`ation referenced by `transaction_id`.

  Partial captures are allowed, and the remaining amount is released back to
  the payment source [(video)][auth-and-capture].

  > Multiple, partial captures on the same `authorization` token are **not supported**.

  CAMS returns a **Transaction ID** (available in the `Response.authorization`
  field) which can be used later to:
  * `refund/3`
  * `void/2` *(only before settlements!)*

  [auth-and-capture]: https://vimeo.com/200903640

  ## Examples

  The following example shows how one would (partially) capture a previously
  authorized a payment worth $10 by referencing the obtained authorization `id`.
  ```
  iex> card = %CreditCard{first_name: "Harry",
                          last_name: "Potter",
                          number: "4111111111111111",
                          year: 2099,
                          month: 12,
                          verification_code: "999",
                          brand: "VISA"}
  iex> money = Money.new(10, :USD)
  iex> authorization = auth_result.authorization
  # authorization = "some_authorization_transaction_id"
  iex> {:ok, capture_result} = Gringotts.capture(Gringotts.Gateways.Cams, money, authorization)
  ```
  """
  @spec capture(Money.t(), String.t(), keyword) :: {:ok | :error, Response.t()}
  def capture(money, transaction_id, options) do
    params =
      [transactionid: transaction_id]
      |> add_invoice(money)

    commit("capture", params, options)
  end

  @doc """
  Transfers `amount` from the customer to the merchant.

  CAMS attempts to process a purchase on behalf of the customer, by debiting
  `amount` from the customer's account by charging the customer's `card`.

  Returns a **Transaction ID** (available in the `Response.authorization`
  field) which can be used later to:
  * `refund/3`
  * `void/2` *(only before settlements!)*

  ## Examples

  The following example shows how one would process a payment worth $20 in
  one-shot, without (pre) authorization.
  ```
  iex> card = %CreditCard{first_name: "Harry",
                          last_name: "Potter",
                          number: "4111111111111111",
                          year: 2099,
                          month: 12,
                          verification_code: "999",
                          brand: "VISA"}
  iex> money = Money.new(20, :USD)
  iex> Gringotts.purchase(Gringotts.Gateways.Cams, money, card)
  ```
  """
  @spec purchase(Money.t(), CreditCard.t(), keyword) :: {:ok | :error, Response.t()}
  def purchase(money, %CreditCard{} = card, options) do
    params =
      []
      |> add_invoice(money)
      |> add_payment(card)
      |> add_address(card, options)

    commit("sale", params, options)
  end

  @doc """
  Refunds the `amount` to the customer's account with reference to a prior transfer.

  It's better to `void/2` a transaction if it has not been settled yet! Refunds
  lead to to two entries on the customer's bank statement, one for the original
  `purchase/3` or `capture/3` and another for the `refund/3`.

  Multiple, partial refunds on the same **Transaction ID** are allowed till all
  the captured amount is refunded.

  ## Examples

  The following example shows how one would completely refund a previous capture
  (and similarily for purchases).
  ```
  iex> capture_id = capture_result.authorization
  # capture_id = "some_capture_transaction_id"
  iex> money = Money.new(20, :USD)
  iex> Gringotts.refund(Gringotts.Gateways.Cams, money, capture_id)
  ```
  """
  @spec refund(Money.t(), String.t(), keyword) :: {:ok | :error, Response.t()}
  def refund(money, transaction_id, options) do
    params =
      [transactionid: transaction_id]
      |> add_invoice(money)

    commit("refund", params, options)
  end

  @doc """
  Voids the referenced payment.

  Cancel a transaction referenced by `transaction_id` that is not settled
  yet. This will erase any entries from the customer's bank statement.

  > `authorize/3` can be `void/2`ed to prevent captures.

  ## Examples

  The following example shows how one would void a previous (pre)
  authorization.
  ```
  iex> auth_id = auth_result.id
  # auth_id = "aome_authorisation_transaction_id"
  iex> Gringotts.void(Gringotts.Gateways.Cams, auth_id)
  ```
  """
  @spec void(String.t(), keyword) :: {:ok | :error, Response.t()}
  def void(transaction_id, options) do
    params = [transactionid: transaction_id]
    commit("void", params, options)
  end

  @doc """
  Validates the `card`

  Verifies the credit `card` without authorizing any amount.

  ## Examples
  ```
  iex> card = %CreditCard{first_name: "Harry",
                          last_name: "Potter",
                          number: "4111111111111111",
                          year: 2099,
                          month: 12,
                          verification_code: "999",
                          brand: "VISA"}
  iex> Gringotts.validate(Gringotts.Gateways.Cams, card)
  ```
  """
  @spec validate(CreditCard.t(), keyword) :: {:ok | :error, Response.t()}
  def validate(card, options) do
    params =
      []
      |> add_invoice(%{value: Decimal.new(0), currency: "USD"})
      |> add_payment(card)
      |> add_address(card, options)

    commit("verify", params, options)
  end

  # private methods

  defp add_invoice(params, money) do
    {currency, value} = Money.to_string(money)
    [amount: value, currency: currency] ++ params
  end

  defp add_payment(params, %CreditCard{} = card) do
    exp_month = card.month |> to_string |> String.pad_leading(2, "0")
    exp_year = card.year |> to_string |> String.slice(-2..-1)

    [ccnumber: card.number, ccexp: "#{exp_month}#{exp_year}", cvv: card.verification_code] ++
      params
  end

  defp add_address(params, card, options) do
    params ++
      [firstname: card.first_name, lastname: card.last_name] ++
      if options[:billing_address] != nil, do: Enum.into(options[:billing_address], []), else: []
  end

  defp commit(action, params, options) do
    url = @live_url

    auth = [
      type: action,
      password: options[:config][:password],
      username: options[:config][:username]
    ]

    url
    |> HTTPoison.post({:form, auth ++ params}, @headers)
    |> ResponseParser.parse()
  end

  defmodule ResponseHandler do
    @moduledoc false
    alias Gringotts.Response

    # Fetched from CAMS POST API docs.
    @avs_code_translator %{
      "X" => {nil, "pass: 9-character numeric ZIP"},
      "Y" => {nil, "pass: 5-character numeric ZIP"},
      "D" => {nil, "pass: 5-character numeric ZIP"},
      "M" => {nil, "pass: 5-character numeric ZIP"},
      "2" => {"pass: customer name", "pass: 5-character numeric ZIP"},
      "6" => {"pass: customer name", "pass: 5-character numeric ZIP"},
      "A" => {"pass: only address", "fail"},
      "B" => {"pass: only address", "fail"},
      "3" => {"pass: address, customer name", "fail"},
      "7" => {"pass: address, customer name", "fail"},
      "W" => {"fail", "pass: 9-character numeric ZIP match"},
      "Z" => {"fail", "pass: 5-character ZIP match"},
      "P" => {"fail", "pass: 5-character ZIP match"},
      "L" => {"fail", "pass: 5-character ZIP match"},
      "1" => {"pass: only customer name", "pass: 5-character ZIP"},
      "5" => {"pass: only customer name", "pass: 5-character ZIP"},
      "N" => {"fail", "fail"},
      "C" => {"fail", "fail"},
      "4" => {"fail", "fail"},
      "8" => {"fail", "fail"},
      "U" => {nil, nil},
      "G" => {nil, nil},
      "I" => {nil, nil},
      "R" => {nil, nil},
      "E" => {nil, nil},
      "S" => {nil, nil},
      "0" => {nil, nil},
      "O" => {nil, nil},
      "" => {nil, nil}
    }

    # Fetched from CAMS POST API docs.
    @cvc_code_translator %{
      "M" => "pass",
      "N" => "fail",
      "P" => "not_processed",
      "S" => "Merchant indicated that CVV2/CVC2 is not present on card",
      "U" => "Issuer is not certified and/or has not provided Visa encryption key"
    }

    @doc false
    def parse({:ok, %HTTPoison.Response{body: body, status_code: 200}}) do
      decoded_body = URI.decode_query(body)
      {street, zip_code} = @avs_code_translator[decoded_body["avsresponse"]]
      gateway_code = decoded_body["response_code"]
      message = decoded_body["responsetext"]

      response = %Response{
        status_code: 200,
        id: decoded_body["transactionid"],
        gateway_code: gateway_code,
        avs_result: %{street: street, zip_code: zip_code},
        cvc_result: @cvc_code_translator[decoded_body["cvvresponse"]],
        message: decoded_body["responsetext"],
        raw: body
      }

      if successful?(gateway_code) do
        {:ok, response}
      else
        {:error, %{response | reason: message}}
      end
    end

    def parse({:ok, %HTTPoison.Response{body: body, status_code: code}}) do
      response = %Response{
        status_code: code,
        raw: body
      }

      {:error, response}
    end

    def parse({:error, %HTTPoison.Error{} = error}) do
      {
        :error,
        %Response{
          reason: "network related failure",
          message: "HTTPoison says '#{error.reason}' [ID: #{error.id || "nil"}]",
          success: false
        }
      }
    end

    defp successful?(gateway_code) do
      gateway_code == "100"
    end
  end
end
