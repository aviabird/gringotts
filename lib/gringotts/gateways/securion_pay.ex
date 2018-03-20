defmodule Gringotts.Gateways.SecurionPay do
  @moduledoc """
  [SecurionPay][home] gateway implementation.

  ## Instructions!

  ***This is an example `moduledoc`, and suggests some items that should be
  documented in here.***

  The quotation boxes like the one below will guide you in writing excellent
  documentation for your gateway. All our gateways are documented in this manner
  and we aim to keep our docs as consistent with each other as possible.
  **Please read them and do as they suggest**. Feel free to add or skip sections
  though.

  If you'd like to make edits to the template docs, they exist at
  `templates/gateway.eex`. We encourage you to make corrections and open a PR
  and tag it with the label `template`.

  ***Actual docs begin below this line!***

  --------------------------------------------------------------------------------

  The following set of functions for SecurionPay have been implemented:

  | Action                                       | Method        |
  | ------                                       | ------        |
  | Authorize a Credit Card                      | `authorize/3` |
  | Capture a previously authorized amount       | `capture/3`   |

  ## Optional or extra parameters

  Most `Gringotts` API calls accept an optional `Keyword` list `opts` to supply
  optional arguments for transactions with the gateway.

  > List all available (ie, those that will be supported by this module) keys, a
  > description of their function/role and whether they have been implemented
  > and tested.
  > A table suits really well for this.

  ## Registering your SecurionPay account at `Gringotts`

  Explain how to make an account with the gateway and show how to put the
  `required_keys` (like authentication info) to the configuration.

  > Your Application config would look
  > something like this:
  > 
  >     config :gringotts, Gringotts.Gateways.SecurionPay,


  ## Scope of this module

  > It's unlikely that your first iteration will support all features of the
  > gateway, so list down those items that are missing.

  ## Supported currencies and countries

  > It's enough if you just add a link to the gateway's docs or FAQ that provide
  > info about this.

  ## Following the examples

  1. First, set up a sample application and configure it to work with MONEI.
  - You could do that from scratch by following our [Getting Started][gs] guide.
      - To save you time, we recommend [cloning our example
      repo][example] that gives you a pre-configured sample app ready-to-go.
          + You could use the same config or update it the with your "secrets"
          as described [above](#module-registering-your-monei-account-at-SecurionPay).

  2. Run an `iex` session with `iex -S mix` and add some variable bindings and
  aliases to it (to save some time):
  ```
  iex> alias Gringotts.{Response, CreditCard, Gateways.SecurionPay}
  iex> card = %CreditCard{first_name: "Jo",
                          last_name: "Doe",
                          number: "4200000000000000",
                          year: 2099, month: 12,
                          verification_code: "123", brand: "VISA"}
  ```

  > Add any other frequently used bindings up here.

  We'll be using these in the examples below.

  [gs]: https://github.com/aviabird/gringotts/wiki/
  [home]: https://securionpay.com/
  [example]: https://github.com/aviabird/gringotts_example
  """

  @base_url "https://api.securionpay.com/"
  # The Base module has the (abstract) public API, and some utility
  # implementations.  

  use Gringotts.Gateways.Base

  # The Adapter module provides the `validate_config/1`
  # Add the keys that must be present in the Application config in the
  # `required_config` list
  use Gringotts.Adapter, required_config: []

  import Poison, only: [decode: 1]

  alias Gringotts.{CreditCard, Response, Address}

  @doc """
  Authorize a credit card transaction.

  The authorization validates the `card` details with the banking network,
  places a hold on the transaction `amount` in the customer’s issuing bank and
  also triggers risk management. Funds are not transferred.

  The second argument can be a CreditCard or a cardId. The customerId of the cutomer who owns the card must be
  given in optional field. 

  To transfer the funds to merchant's account follow this up with a `capture/3`.

  SecurionPay returns a `chargeId` which uniquely identifies a transaction (available in the `Response.id` field) 
  which should be stored at your side to use in:

  * `capture/3` an authorized transaction.
  * `void/2` a transaction.


  ## Example 1
      iex> amount = Money.new(20, :USD}
      iex> opts = [config: "c2tfdGVzdF9GZjJKcHE1OXNTV1Q3cW1JOWF0aWk1elI6"]
      iex> card = %CreditCard{
           first_name: "Harry",
           last_name: "Potter",
           number: "4200000000000000",
           year: 2027,
           month: 12,
           verification_code: "123",
           brand: "VISA"
          }
      iex> result = Gringotts.Gateways.SecurionPay.authorize(amount, card, opts)

  ## Example 2
      iex> amount = Money.new(20, :USD}
      iex> opts = [config: "c2tfdGVzdF9GZjJKcHE1OXNTV1Q3cW1JOWF0aWk1elI6", customerId: "cust_zpYEBK396q3rvIBZYc3PIDwT"]
      iex> card = "card_LqTT5tC10BQzDbwWJhFWXDoP"
      iex> result = Gringotts.Gateways.SecurionPay.authorize(amount, card, opts)

  """
  @spec authorize(Money.t(), CreditCard.t() | {}, keyword) :: {:ok | :error, Response}
  def authorize(amount, %CreditCard{} = card, opts) do
    header = [{"Authorization", "Basic " <> opts[:config]}]

    create_token(card, header)
    |> create_params(amount, false)
    |> commit(:post, "charges", header)
    |> respond
  end

  def authorize(amount, card, opts) do
    header = [{"Authorization", "Basic " <> opts[:config]}]

    create_params({card, opts[:customerId]}, amount, false)
    |> commit(:post, "charges", header)
    |> respond
  end

  @doc """
  Captures a pre-authorized transcation from the customer.

  The amount present in the pre-authorization referenced by `payment_id` is transferred to the 
  merchant account by SecurionPay.


  Successful request returns a charge object that was captured.

  ## Note
  > SecurionPay does not support partial captures. So there is no need of amount in capture.

  ## Example

  iex> amount = 100
  iex> payment_id = "char_WCglhaf1Gn9slpXWYBkZqbGK"
  iex> opts = [config: "c2tfdGVzdF9GZjJKcHE1OXNTV1Q3cW1JOWF0aWk1elI6"]
  iex> result = Gringotts.Gateways.SecurionPay.capture(payment_id, amount, opts)

  """
  @spec capture(String.t(), Money.t(), keyword) :: {:ok | :error, Response}
  def capture(payment_id, _amount, opts) do
    header = [{"Authorization", "Basic " <> opts[:config]}]

    commit([], :post, "charges/#{payment_id}/capture", header)
    |> respond
  end

  @doc """
  Transfers `amount` from the customer to the merchant.

  SecurionPay attempts to process a purchase on behalf of the customer, by
  debiting `amount` from the customer's account by charging the customer's
  `card`.

  ## Note

  > If there's anything noteworthy about this operation, it comes here.

  ## Example

  > A barebones example using the bindings you've suggested in the `moduledoc`.
  """
  @spec purchase(Money.t(), CreditCard.t(), keyword) :: {:ok | :error, Response}
  def purchase(amount, card = %CreditCard{}, opts) do
    # commit(args, ...)
  end

  @doc """
  Voids the referenced payment.

  This method attempts a reversal of a previous transaction referenced by
  `payment_id`.

  > As a consequence, the customer will never see any booking on his statement.

  ## Note

  > Which transactions can be voided?
  > Is there a limited time window within which a void can be perfomed?

  ## Example

  > A barebones example using the bindings you've suggested in the `moduledoc`.
  """
  @spec void(String.t(), keyword) :: {:ok | :error, Response}
  def void(payment_id, opts) do
    # commit(args, ...)
  end

  @doc """
  Refunds the `amount` to the customer's account with reference to a prior transfer.

  > Refunds are allowed on which kinds of "prior" transactions?

  ## Note

  > The end customer will usually see two bookings/records on his statement. Is
  > that true for SecurionPay?
  > Is there a limited time window within which a void can be perfomed?

  ## Example

  > A barebones example using the bindings you've suggested in the `moduledoc`.
  """
  @spec refund(Money.t(), String.t(), keyword) :: {:ok | :error, Response}
  def refund(amount, payment_id, opts) do
    # commit(args, ...)
  end

  @doc """
  Stores the payment-source data for later use.

  > This usually enable "One Click" and/or "Recurring Payments"

  ## Note

  > If there's anything noteworthy about this operation, it comes here.

  ## Example

  > A barebones example using the bindings you've suggested in the `moduledoc`.
  """
  @spec store(CreditCard.t(), keyword) :: {:ok | :error, Response}
  def store(%CreditCard{} = card, opts) do
    # commit(args, ...)
  end

  @doc """
  Removes card or payment info that was previously `store/2`d

  Deletes previously stored payment-source data.

  ## Note

  > If there's anything noteworthy about this operation, it comes here.

  ## Example

  > A barebones example using the bindings you've suggested in the `moduledoc`.
  """
  @spec unstore(String.t(), keyword) :: {:ok | :error, Response}
  def unstore(registration_id, opts) do
    # commit(args, ...)
  end

  ###############################################################################
  #                                PRIVATE METHODS                              #
  ###############################################################################

  # Creates the parameter for authorise and capture function when cardId and customerId is provided.
  @spec create_params({}, Money.t(), boolean) :: {[]}
  defp create_params({cardId, customerId}, amount, captured) do
    {currency, value, _, _} = Money.to_integer_exp(amount)

    [
      {"amount", value},
      {"currency", to_string(currency)},
      {"card", cardId},
      {"captured", "#{captured}"},
      {"customerId", customerId}
    ]
  end

  # Creates the parameter for authorise and capture function when token is provided.
  @spec create_params(Integer.t(), Money.t(), boolean) :: {[]}
  defp create_params(token, amount, captured) do
    {currency, value, _, _} = Money.to_integer_exp(amount)

    [
      {"amount", value},
      {"currency", to_string(currency)},
      {"card", token},
      {"captured", "#{captured}"}
    ]
  end

  # Makes the request to SecurionPay's network.
  # For consistency with other gateway implementations, make your (final)
  # network request in here, and parse it using another private method called
  # `respond`.
  defp commit(params, method, path, header) do
    HTTPoison.request(method, "#{@base_url}#{path}", {:form, params}, header)
  end

  # Parses SecurionPay's response and returns a `Gringotts.Response` struct
  # in a `:ok`, `:error` tuple.
  @spec respond(term) :: {:ok | :error, Response}

  defp respond({:ok, %{status_code: 200, body: body}}) do
    parsedBody = Poison.decode!(body)

    {:ok,
     %{
       success: true,
       id: Map.get(parsedBody, "id"),
       token: Map.get(parsedBody["card"], "id"),
       status_code: 200,
       gateway_code: 200,
       reason: nil,
       message: "Card succesfully authorized",
       avs_result: nil,
       cvc_result: nil,
       raw: body,
       fraud_review: Map.get(parsedBody, "fraudDetails")
     }}
  end

  defp respond({:ok, %{body: body, status_code: code}}) do
    {:error, %Response{raw: body, status_code: code}}
  end

  defp respond({:error, %HTTPoison.Error{} = error}) do
    {
      :error,
      %Response{
        reason: "network related failure",
        message: "HTTPoison says '#{error.reason}' [ID: #{error.id || "nil"}]"
      }
    }
  end

  defp create_token(card, header) do
    [
      {"number", card.number},
      {"expYear", card.year},
      {"cvc", card.verification_code},
      {"expMonth", card.month},
      {"cardholderName", card.first_name <> " " <> card.last_name}
    ]
    |> commit(:post, "tokens", header)
    |> make_map
    |> Map.fetch!("id")
  end

  defp make_map(response) do
    case response do
      {:ok, %HTTPoison.Response{body: body}} -> body |> Poison.decode!()
    end
  end
end
