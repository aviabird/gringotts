defmodule Gringotts.Gateways.Pinpay do
  @moduledoc """
  [PinPay][home] gateway implementation.

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
  > per the PinPay gateway docs.
  > A table suits really well for this.

  ## Optional or extra parameters

  Most `Gringotts` API calls accept an optional `Keyword` list `opts` to supply
  optional arguments for transactions with the gateway.
  
  > List all available (ie, those that will be supported by this module) keys, a
  > description of their function/role and whether they have been implemented
  > and tested.
  > A table suits really well for this.

  ## Registering your PinPay account at `Gringotts`

  Explain how to make an account with the gateway and show how to put the
  `required_keys` (like authentication info) to the configuration.
  
  > Your Application config would look
  > something like this:
  > 
  >     config :gringotts, Gringotts.Gateways.Pinpay,
  
  
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
          as described [above](#module-registering-your-monei-account-at-PinPay).

  2. Run an `iex` session with `iex -S mix` and add some variable bindings and
  aliases to it (to save some time):
  ```
  iex> alias Gringotts.{Response, CreditCard, Gateways.Pinpay}
  iex> card = %CreditCard{first_name: "Jo",
                          last_name: "Doe",
                          number: "4200000000000000",
                          year: 2099, month: 12,
                          verification_code: "123", brand: "VISA"}
  ```

  > Add any other frequently used bindings up here.

  We'll be using these in the examples below.

  [gs]: https://github.com/aviabird/gringotts/wiki/
  [home]: https://pinpayments.com
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

  @test_url "https://test-api.pinpayments.com/1/"
  @production_url "https://api.pinpayments.com"
  @headers [{"Content-Type", "application/x-www-form-urlencoded"},{"Authorization", "Basic YzRueGd6bmFuVzRYWlVhRVFoeFM2Zzo="}]
  
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
  def authorize(amount, card = %CreditCard{}, opts) do
    # commit(args, ...)
    {currency, value,_} = Money.to_integer(amount)

    params =
      [
        amount: value,
        capture: false
      ] ++ card_params(card, opts) 

      

    commit(:post, "charges", params, [{:currency, currency} | opts])


  end

  def card_params(card, opts) do
    [
      "card[number]": card.number,
      "card[name]": card.first_name <> card.last_name,
      "card[expiry_month]": card.month |> Integer.to_string() |> String.pad_leading(2, "0"),
      "card[expiry_year]": card.year |> Integer.to_string(),
      "card[cvc]": card.verification_code,
      "card[address_line1]": opts[:Address][:street1],
      "card[address_city]": opts[:Address][:city],
      "card[address_country]": opts[:Address][:country],
      "description": "hello",
      "email": "hi@hello.com"
    ]

  end

  def card_param(card, opts) do
    [
      "number": card.number,
      "name": card.first_name <> card.last_name,
      "expiry_month": card.month |> Integer.to_string() |> String.pad_leading(2, "0"),
      "expiry_year": card.year |> Integer.to_string(),
      "cvc": card.verification_code,
      "address_line1": opts[:Address][:street1],
      "address_city": opts[:Address][:city],
      "address_country": opts[:Address][:country],
      
    ]

  end

  @doc """
  Captures a pre-authorized `amount`.

  `amount` is transferred to the merchant account by PinPay used in the
  pre-authorization referenced by `payment_id`.

  ## Note

  > If there's anything noteworthy about this operation, it comes here.
  > For example, does the gateway support partial, multiple captures?

  ## Example

  > A barebones example using the bindings you've suggested in the `moduledoc`.
  """
  @spec capture(String.t(), Money.t, keyword) :: {:ok | :error, Response}
  def capture(payment_id, amount, opts) do
    # commit(args, ...)
    url = @test_url <> "/1/charges/" <> payment_id <> "/capture"
    commit(:put, url)
  end

  @doc """
  Transfers `amount` from the customer to the merchant.

  PinPay attempts to process a purchase on behalf of the customer, by
  debiting `amount` from the customer's account by charging the customer's
  `card`.

  ## Note

  > If there's anything noteworthy about this operation, it comes here.

  ## Example

  > A barebones example using the bindings you've suggested in the `moduledoc`.
  """
  @spec purchase(Money.t, CreditCard.t(), keyword) :: {:ok | :error, Response}
  def purchase(amount, card = %CreditCard{}, opts) do
    # commit(args, ...)
    # commit(args, ...)
    {currency, value,_} = Money.to_integer(amount)

    params =
      [
        amount: value
        
      ] ++ card_params(card, opts) 

      

    commit(:post, "charges", params, [{:currency, currency} | opts])
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
  > that true for PinPay?
  > Is there a limited time window within which a void can be perfomed?

  ## Example

  > A barebones example using the bindings you've suggested in the `moduledoc`.
  """
  @spec refund(Money.t, String.t(), keyword) :: {:ok | :error, Response}
  def refund(amount, payment_id, opts) do
    # commit(args, ...)
    url=@test_url <>"charges/" <> payment_id <> "/refunds"

    commit(:post, url)
  end


  @doc """
  Stores the payment-source data for later use.

  > This usually enable "One Click" and/or "Recurring Payments"

  ## Note

  > If there's anything noteworthy about this operation, it comes here.

  ## Example

  > A barebones example using the bindings you've suggested in the `moduledoc`.
  """
  defp auth_params(opts) do
    [
      "username": opts[:config][:apiKey],
      "password": opts[:config][:pass]
    ]
  end


  @spec store(CreditCard.t(), keyword) :: {:ok | :error, Response}
  def store(%CreditCard{} = card, opts) do
    # commit(args, ...)

    commit(:post, "cards", card_param(card, opts), opts)
    |> respond

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
  
  # Makes the request to PinPay's network.
  # For consistency with other gateway implementations, make your (final)
  # network request in here, and parse it using another private method called
  # `respond`.
  @spec commit(atom, String.t(), keyword, keyword) :: {:ok | :error, Response}
  defp commit(:post, endpoint, param, opts) do
    # resp = HTTPoison.request(args, ...)
    # respond(resp, ...)
    url = @test_url <> "#{endpoint}"
      
    
        url
        |> HTTPoison.post({:form, param }, @headers)
        |> respond
    end

    defp commit(method, url) do
      HTTPoison.request(method, url, [], @headers )
      |> respond
    end

  # Parses PinPay's response and returns a `Gringotts.Response` struct
  # in a `:ok`, `:error` tuple.
  @spec respond(term) :: {:ok | :error, Response}
  defp respond(pin_pay_response)
  #defp respond({:ok, %{status_code: 200, body: body}}), do: "something1"
  defp respond({:ok, %{status_code: code, body: body}}) when code in [200, 201] do
    case decode(body) do
      {:ok, results} -> {:ok, Response.success(raw: results, status_code: code)}
    end
  end
  defp respond({:ok, %{status_code: code, body: body}}) when code in [400, 401, 402, 403, 404] do
    case decode(body) do
      {:ok, results} -> {:ok, Response.success(raw: results, status_code: code)}
    end
  end
  defp respond({:error, %HTTPoison.Error{} = error}), do: "something3"
end
