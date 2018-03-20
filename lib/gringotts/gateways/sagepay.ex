defmodule Gringotts.Gateways.Sagepay do
  @moduledoc """
  [sagepay][home] gateway implementation.

  The following features of MONEI are implemented:

  | Action                       | Method        | 
  | ------                       | ------        | 
  | Authorize                    | `authorize/3` | 
  | Release                      | `capture/3`   | 
  | Refund                       | `refund/3`    | 
  | Reversal                     | `void/2`      | 
  | Purchase                     | `purchase/3`  | 
  | Tokenization / Registrations | `store/2`     | not done yet



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

  > List features that have been implemented, and what "actions" they map to as
  > per the sagepay gateway docs.
  > A table suits really well for this.

  ## Optional or extra parameters

  Most `Gringotts` API calls accept an optional `Keyword` list `opts` to supply
  optional arguments for transactions with the gateway.

  > List all available (ie, those that will be supported by this module) keys, a
  > description of their function/role and whether they have been implemented
  > and tested.
  > A table suits really well for this.

  ## Registering your sagepay account at `Gringotts`

  Explain how to make an account with the gateway and show how to put the
  `required_keys` (like authentication info) to the configuration.

  > Your Application config would look
  > something like this:
  > 
  >     config :gringotts, Gringotts.Gateways.Sagepay,


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
          as described [above](#module-registering-your-monei-account-at-sagepay).

  2. Run an `iex` session with `iex -S mix` and add some variable bindings and
  aliases to it (to save some time):
  ```
  iex> alias Gringotts.{Response, CreditCard, Gateways.Sagepay}
  iex> card = %CreditCard{first_name: "Jo",
                          last_name: "Doe",
                          number: "4200000000000000",
                          year: 2099, month: 12,
                          verification_code: "123", brand: "VISA"}
  ```

  > Add any other frequently used bindings up here.

  We'll be using these in the examples below.

  [gs]: https://github.com/aviabird/gringotts/wiki/
  [home]: https://www.sagepay.co.uk/
  [example]: https://github.com/aviabird/gringotts_example
  """

  # The Base module has the (abstract) public API, and some utility
  # implementations.  
  use Gringotts.Gateways.Base

  # The Adapter module provides the `validate_config/1`
  # Add the keys that must be present in the Application config in the
  # `required_config` list
  use Gringotts.Adapter, required_config: []

  import Poison, only: [decode: 1]

  alias Gringotts.{Money, CreditCard, Response}
  @url "https://pi-test.sagepay.com/api/v1/"
  @doc """
  Performs a (pre) Authorize operation.

  The authorization validates the `card` details with the banking network,
  places a hold on the transaction `amount` in the customer’s issuing bank.

  > ** You could perhaps:**
  > 1. describe what are the important fields in the Response struct
  > 2. mention what a merchant can do with these important fields (ex:
  > `capture/3`, etc.)

  ## Note

  > If there's anything noteworthy about this operation, it comes here.

  ## Example

  > A barebones example using the bindings you've suggested in the `moduledoc`.
  """
  @spec authorize(Money.t(), CreditCard.t(), keyword) :: {:ok | :error, Response}
  def authorize(amount, card, opts) do
    merchant_key = generate_mkey(opts)

    card_key = generate_ckey(card, merchant_key)

    card_params = card_details(amount, merchant_key, card_key, opts)

    card_header = [
      {"Authorization", "Basic " <> opts[:config].auth_id},
      {"Content-type", "application/json"}
    ]

    body = commit(:post, "transactions", card_params, card_header)
  end

  @doc """
  Captures a pre-authorized `amount`.

  `amount` is transferred to the merchant account by sagepay used in the
  pre-authorization referenced by `payment_id`.

  ## Note

  > If there's anything noteworthy about this operation, it comes here.
  > For example, does the gateway support partial, multiple captures?

  ## Example

  > A barebones example using the bindings you've suggested in the `moduledoc`.
  """
  @spec capture(String.t(), Money.t(), keyword) :: {:ok | :error, Response}
  def capture(payment_id, amount, opts) do
  end

  @doc """
  Transfers `amount` from the customer to the merchant.

  sagepay attempts to process a purchase on behalf of the customer, by
  debiting `amount` from the customer's account by charging the customer's
  `card`.

  ## Note

  > If there's anything noteworthy about this operation, it comes here.

  ## Example

  > A barebones example using the bindings you've suggested in the `moduledoc`.
  """
  @spec purchase(Money.t(), CreditCard.t(), keyword) :: {:ok | :error, Response}
  def purchase(amount, card, opts) do
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
  > that true for sagepay?
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

  # Makes the request to sagepay's network.
  # For consistency with other gateway implementations, make your (final)
  # network request in here, and parse it using another private method called
  # `respond`.

  # @spec commit(_) :: {:ok | :error, Response}
  def commit(:post, endpoint, params, opts) do
    a_url = @url <> endpoint
    response = HTTPoison.post(a_url, params, opts)
    format_response(response)
  end

  # Function generate_mkey generate a merchant_session_key that will exist only for 400 seconds
  # and for 3 wrong card identifiers

  defp generate_mkey(opts) do
    vender_name = Poison.encode!(%{vendorName: opts[:config].vendor})

    merchant_header = [
      {"Authorization", "Basic " <> opts[:config].auth_id},
      {"Content-type", "application/json"}
    ]

    key =
      commit(:post, "merchant-session-keys", vender_name, merchant_header)
      |> Map.get("merchantSessionKey")
  end

  # Function generate_ckey generate a unique cardidentifier for every transaction

  defp generate_ckey(card, merchant_key) do
    card_header = [
      {"Authorization", "Bearer " <> merchant_key},
      {"Content-type", "application/json"}
    ]

    card = card |> Poison.encode!()

    card_identifier =
      commit(:post, "card-identifiers", card, card_header)
      |> Map.get("cardIdentifier")
  end

  # Function card_details creates the actual body (details of the customer )of the card 
  # and with merchant_session_key, card_identifiier ,shipping address of a
  # customer, and other details and converting the map into keyword list

  defp card_details(amount, merchant_key, card_key, opts) do
    card_body =
      Poison.encode!(%{
        "transactionType" => opts[:transactionType],
        "paymentMethod" => %{
          "card" => %{
            "merchantSessionKey" => merchant_key,
            "cardIdentifier" => card_key,
            "save" => false
          }
        },
        "vendorTxCode" => opts[:vendorTxCode],
        "amount" => amount,
        "currency" => opts[:currency],
        "description" => opts[:description],
        "customerFirstName" => opts[:customerFirstName],
        "customerLastName" => opts[:customerLastName],
        "billingAddress" => %{
          "address1" => opts[:billingAddress].address1,
          "city" => opts[:billingAddress].city,
          "postalCode" => opts[:billingAddress].postalCode,
          "country" => opts[:billingAddress].country
        }
      })
  end

  # Parses sagepay's response and returns a `Gringotts.Response` struct
  # in a `:ok`, `:error` tuple.

  defp format_response(response) do
    {:ok, %{body: body}} = response

    case response do
      {:ok, %{body: body}} -> body |> Poison.decode!()
      _ -> %{"error" => "something went wrong, please try again later"}
    end
  end

  """
  @spec respond(term) :: {:ok | :error, Response}
  defp respond(sagepay.ex_response)
  defp respond({:ok, %{status_code: 200, body: body}}), do: "something"
  defp respond({:ok, %{status_code: status_code, body: body}}), do: "something"
  defp respond({:error, %HTTPoison.Error{} = error}), do: "something"
  """
end
