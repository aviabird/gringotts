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

  ### Worker Name 
    eg: :payment_worker

    The standard central supervised worker responsible for delegating/calling all
    the payment specific methods such as `authorise` & `purchase`.

    > This option is going to be removed in our next version.

  ### Gateway Name
    eg: Gringotts.Gateways.Stripe

    This option specifies which payment gateway this request should be called for.
    Since `Gringotts` supports multiple payment gateway integrations at the same time
    so this information get's critical.

  ### Amount
    eg: 5000

    Amount is the money an application wants to deduct in cents on the card.

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
    eg: [currency: "usd"]

    This is a keyword list of all the other options/information which the payment gateway 
    needs apart from the above mentioned options. 

    > This is passed as is to the gateway and not modified, usually it comes back in the 
    response object intact.
  """
  
  import GenServer, only: [call: 2]

  @doc """
  This is the bare minimum API for a gateway to support, and consists of a single call:
       
      @payment %{
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

      @options [currency: "usd"]

      Gringotts.purchase(:payment_worker, Gringotts.Gateways.Stripe, 5, @payment, @options)

  This method is expected to authorize payment and transparently trigger eventual 
  settlement. Preferably it is implemented as a single call to the gateway, 
  but it can also be implemented as chained `authorize` and `capture` calls.
  """
  def purchase(worker, gateway, amount, card, opts \\ []) do
    validate_config(gateway)
    call(worker, {:purchase, gateway, amount, card, opts})
  end

  @doc """
  Authorize should authorize funds on a payment instrument that will 
  not be settled without a following call to `capture` within some finite 
  period of time. When implementing this API, authorize and capture are 
  both required.

      @payment %{
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

      @options [currency: "usd"]

      Gringotts.authorize(:payment_worker, Gringotts.Gateways.Stripe, 5, @payment, @options)
  """
  def authorize(worker, gateway, amount, card, opts \\ []) do
    validate_config(gateway)
    call(worker, {:authorize, gateway, amount, card, opts})
  end

  @doc """
  Captures deducts an amount from the card, this happens once the card is authorised.

  Partial captures, if supported by the gateway, are achieved by passing an amount. 
  Not passing an amount to capture should always cause the full amount of the initial 
  authorization to be captured.

  If the gateway does not support partial captures, calling `capture` with an amount 
  other than nil should raise an error indicating partial capture is not supported.
  
      @payment %{
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

      @options [currency: "usd"]

      id = "ch_1BYvGkBImdnrXiZwet3aKkQE"

      Gringotts.capture(:payment_worker, Gringotts.Gateways.Stripe, id, 5)
  """
  def capture(worker, gateway, id, amount, opts \\ []) do 
    validate_config(gateway)
    call(worker, {:capture, gateway, id, amount, opts})
  end

  @doc """
  Void is an optional (but highly recommended) supplement to `authorise` & `capture` 
  API that should immediately cancel an authorized charge, clearing it off of the 
  underlying payment instrument without waiting for expiration.

      @payment %{
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

      @options [currency: "usd"]

      id = "ch_1BYvGkBImdnrXiZwet3aKkQE"

      Gringotts.void(:payment_worker, Gringotts.Gateways.Stripe, id)

  """
  def void(worker, gateway, id, opts \\ []) do 
    validate_config(gateway)
    call(worker, {:void, gateway, id, opts})
  end

  @doc """
  Cancels settlement or returns funds as appropriate for a referenced prior 
  `purchase` or `capture`.

      @payment %{
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

      Gringotts.refund(:payment_worker, Gringotts.Gateways.Stripe, 5, id)
  """
  def refund(worker, gateway, amount, id, opts \\ []) do 
    validate_config(gateway)
    call(worker, {:refund, gateway, amount, id, opts})
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

      @payment %{
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

      Gringotts.store(:payment_worker, Gringotts.Gateways.Stripe, @payment)
  """
  def store(worker, gateway, card, opts \\ []) do 
    validate_config(gateway)
    call(worker, {:store, gateway, card, opts})
  end

  @doc """
  Removes the token from the payment gateway, once `unstore` request is fired the 
  token which could enable `authorise` & `capture` would not work with this token.

  This should be done once the payment capture is done and you don't wish to make any
  further deductions for the same card.

      customer_id = "random_customer"

      Gringotts.unstore(:payment_worker, Gringotts.Gateways.Stripe, customer_id)
  """
  def unstore(worker, gateway, customer_id, opts \\ []) do 
    validate_config(gateway)
    call(worker, {:unstore, gateway, customer_id, opts})
  end

  # TODO: This is runtime error reporting fix this so that it does compile
  # time error reporting.
  defp validate_config(gateway) do
    # Keep the key name and adapter the same in the config in application
    config = Application.get_env(:gringotts, gateway)
    gateway.validate_config(config)
  end
end
