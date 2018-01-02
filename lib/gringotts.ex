defmodule Gringotts do
  @moduledoc ~S"""
  Gringotts is a payment gateway integration library supporting many gateway integrations.
  
  ## Configuration
  
  The configuration for `Gringotts` must be in your application environment, 
  usually defined in your `config/config.exs` and is **mandatory**:

  **Global Configuration**
  
  The global configuration sets the library level configurations to interact with the gateway.
  If the mode is not set then by 'default' the sandbox account is selected.

  To integrate with the sandbox account set.
      config :gringotts, :global_config,
        mode: :test
  To integrate with the live account set.
      config :gringotts, :global_config,
        mode: :prod

  **Gateway Configuration**

  The gateway level configurations are for fields related to a specific gateway. 
      config :Gringotts, Gringotts.Gateways.Stripe,
        adapter: Gringotts.Gateways.Stripe,
        api_key: "sk_test_vIX41hC0sdfBKrPWQerLuOMld",
        default_currency: "USD"

  `Key` for the configuration and the adapter value should be the same, we could have
  chosen to pick adapter and used it as the key but we have chosen to be explicit rather 
  than implicit.

  ## Standard Arguments

  The public API is designed in such a way that library users end up passing mostly a 
  standard params for almost all requests.

  ### Gateway Name
    eg: Gringotts.Gateways.Stripe

    This option specifies which payment gateway this request should be called for.
    Since `Gringotts` supports multiple payment gateway integrations at the same time
    so this information gets critical.

  ### Amount _and currency_
    eg:
        %{amount: Decimal.new(42), currency: "USD"}

    This argument represents the "amount", annotated with the currency unit for
    which the transaction is being requested. `amount` is polymorphic thanks to
    the `Gringotts.Money` protocol which can be implemented by your custom Money
    type.

    We support [`ex_money`][ex_money] and [`monetized`][monetized] out of the
    box, and you can drop their types in this argument and everything will work
    as expected.

  ### Card Info
    eg: 
        %CreditCard {
          name: "John Doe",
          number: "4242424242424242",
          expiration: {2018, 12},
          cvc:  "123",
          street1: "123 Main",
          street2: "Suite 100",
          city: "New York",
          region: "NY",
          country: "US",
          postal_code: "11111" 
        }
    
    This stores all the credit card info of the customer along with some address info etc.

  ### Other options

    `opts` is a `keyword` list of other options/information which the
    payment gateway needs apart from the above mandatory method arguments. These
    are gateway specific options and you can see what's supported in the
    gateway's docs.

  [ex_money]: https://hexdocs.pm/ex_money/readme.html
  [monetized]: https://hexdocs.pm/monetized/
  """
  
  import GenServer, only: [call: 2]

  @doc """
  This is the bare minimum API for a gateway to support, and consists of a single call:
       
      payment = %{
        name: "John Doe",
        number: "4242424242424242",
        expiration: {2018, 12},
        cvc:  "123",
        street1: "123 Main",
        street2: "Suite 100",
        city: "New York",
        region: "NY",
        country: "US",
        postal_code: "11111"
      }
      amount = %{amount: Decimal.new(4.99), currency: "USD"}
      Gringotts.purchase(Gringotts.Gateways.Stripe, amount, payment)

  This method is expected to authorize payment and transparently trigger eventual 
  settlement. Preferably it is implemented as a single call to the gateway, 
  but it can also be implemented as chained `authorize` and `capture` calls.
  """
  def purchase(gateway, amount, card, opts \\ []) do
    validate_config(gateway)
    call(:payment_worker, {:purchase, gateway, amount, card, opts})
  end

  @doc """
  Authorize should authorize funds on a payment instrument that will 
  not be settled without a following call to `capture` within some finite 
  period of time. When implementing this API, authorize and capture are 
  both required.

      payment = %{
        name: "John Doe",
        number: "4242424242424242",
        expiration: {2018, 12},
        cvc:  "123",
        street1: "123 Main",
        street2: "Suite 100",
        city: "New York",
        region: "NY",
        country: "US",
        postal_code: "11111"
      }
      amount = %{amount: Decimal.new(4.99), currency: "USD"}
      Gringotts.authorize(Gringotts.Gateways.Stripe, amount, payment)
  """
  def authorize(gateway, amount, card, opts \\ []) do
    validate_config(gateway)
    call(:payment_worker, {:authorize, gateway, amount, card, opts})
  end

  @doc """
  Captures deducts an amount from the card, this happens once the card is authorised.

  Partial captures, if supported by the gateway, are achieved by passing an amount. 
  Not passing an amount to capture should always cause the full amount of the initial 
  authorization to be captured.

  If the gateway does not support partial captures, calling `capture` with a
  `nil` amount should raise an error indicating partial capture is not
  supported.
  
      payment = %{
        name: "John Doe",
        number: "4242424242424242",
        expiration: {2018, 12},
        cvc:  "123",
        street1: "123 Main",
        street2: "Suite 100",
        city: "New York",
        region: "NY",
        country: "US",
        postal_code: "11111"
      }

      amount = %{amount: Decimal.new(4.99), currency: "USD"}
      id = "ch_1BYvGkBImdnrXiZwet3aKkQE"
      Gringotts.capture(Gringotts.Gateways.Stripe, id, amount)
  """
  def capture(gateway, id, amount, opts \\ []) do 
    validate_config(gateway)
    call(:payment_worker, {:capture, gateway, id, amount, opts})
  end

  @doc """
  Void is an optional (but highly recommended) supplement to `authorise` & `capture` 
  API that should immediately cancel an authorized charge, clearing it off of the 
  underlying payment instrument without waiting for expiration.

       payment = %{
        name: "John Doe",
        number: "4242424242424242",
        expiration: {2018, 12},
        cvc:  "123",
        street1: "123 Main",
        street2: "Suite 100",
        city: "New York",
        region: "NY",
        country: "US",
        postal_code: "11111"
      }
      id = "ch_1BYvGkBImdnrXiZwet3aKkQE"
      Gringotts.void(Gringotts.Gateways.Stripe, id)

  """
  def void(gateway, id, opts \\ []) do 
    validate_config(gateway)
    call(:payment_worker, {:void, gateway, id, opts})
  end

  @doc """
  Cancels settlement or returns funds as appropriate for a referenced prior 
  `purchase` or `capture`.

      payment = %{
        name: "John Doe",
        number: "4242424242424242",
        expiration: {2018, 12},
        cvc:  "123",
        street1: "123 Main",
        street2: "Suite 100",
        city: "New York",
        region: "NY",
        country: "US",
        postal_code: "11111"
      }
      amount = %{amount: Decimal.new(4.99), currency: "USD"}  
      id = "ch_1BYvGkBImdnrXiZwet3aKkQE"
      Gringotts.refund(Gringotts.Gateways.Stripe, amount, id)
  """
  def refund(gateway, amount, id, opts \\ []) do 
    validate_config(gateway)
    call(:payment_worker, {:refund, gateway, amount, id, opts})
  end

  @doc """
  Tokenizes a supported payment method in the gateway's vault. If the gateway 
  conflates tokenization with customer management, `Gringotts` should hide all 
  customer management and any customer identifier(s) within the token returned. 
  It's certainly legitimate to have a library that interacts with all the features 
  in a gateway's vault, but `Gringotts` is not the right place for it.

  It's critical that `store` returns a token that can be used against `purchase` 
  and `authorize`. Currently the standard is to return the token in the 
  `%Response{...}` `authorization` field.

      payment = %{
        name: "John Doe",
        number: "4242424242424242",
        expiration: {2018, 12},
        cvc:  "123",
        street1: "123 Main",
        street2: "Suite 100",
        city: "New York",
        region: "NY",
        country: "US",
        postal_code: "11111"
      }
      Gringotts.store(Gringotts.Gateways.Stripe, payment)
  """
  def store(gateway, card, opts \\ []) do 
    validate_config(gateway)
    call(:payment_worker, {:store, gateway, card, opts})
  end

  @doc """
  Removes the token from the payment gateway, once `unstore` request is fired the 
  token which could enable `authorise` & `capture` would not work with this token.

  This should be done once the payment capture is done and you don't wish to make any
  further deductions for the same card.

      customer_id = "some_privileged_customer"
      Gringotts.unstore(Gringotts.Gateways.Stripe, customer_id)
  """
  def unstore(gateway, customer_id, opts \\ []) do 
    validate_config(gateway)
    call(:payment_worker, {:unstore, gateway, customer_id, opts})
  end

  # TODO: This is runtime error reporting fix this so that it does compile
  # time error reporting.
  defp validate_config(gateway) do
    # Keep the key name and adapter the same in the config in application
    config = Application.get_env(:gringotts, gateway)
    gateway.validate_config(config)
  end
end
