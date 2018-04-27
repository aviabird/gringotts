defmodule Gringotts do
  @moduledoc """
  Gringotts is a payment gateway integration library for merchants

  Gringotts provides a unified interface for multiple Payment Gateways to make it
  easy for merchants to use multiple gateways.
  All gateways must conform to the API as described in this module, but can also
  support more gateway features than those required by Gringotts.

  ## Standard API arguments

  All requests to Gringotts are served by a supervised worker, this might be
  made optional in future releases.

  ### `gateway` (Module) Name

  The `gateway` to which this request is made. This is required in all API calls
  because Gringotts supports multiple Gateways.

  #### Example
  If you've configured Gringotts to work with Stripe, you'll do this
  to make an `authorization` request:

      Gringotts.authorize(Gingotts.Gateways.Stripe, other args ...)

  ### `amount` _and currency_

  This argument represents the "amount", annotated with the currency unit for
  the transaction. `amount` is polymorphic thanks to the `Gringotts.Money`
  protocol which can even be implemented by your very own custom Money type!

  #### Note

  Gringotts supports [`ex_money`][ex_money] out of the box, just drop `ex_money`
  types in this argument and everything will work as expected.

  > Support for [`monetized`][monetized] and [`money`][money] is on the
  > way, track it [here][iss-money-lib-support]!

  Otherwise, just wrap your `amount` with the `currency` together in a `Map` like so,
      money = %{value: Decimal.new("100.50"), currency: "USD"}

  > When this highly precise `amount` is serialized into the network request, we
  > use a potentially lossy `Gringotts.Money.to_string/1` or
  > `Gringotts.Money.to_integer/1` to perform rounding (if required) using the
  > [`half-even`][wiki-half-even] strategy.
  >
  > **Hence, to ensure transparency, protect sanity and save _real_ money, we
  > STRONGLY RECOMMEND that merchants perform any required rounding and handle
  > remainders in their application logic -- before passing the `amount` to
  > Gringotts's API.**

  #### Example

  If you use `ex_money` in your project, and want to make an authorization for
  $2.99 to the `XYZ` Gateway, you'll do the following:

      # the money lib is aliased as "MoneyLib"

      amount = MoneyLib.new("2.99", :USD)
      Gringotts.authorize(Gringotts.Gateways.XYZ, amount, some_card, extra_options)

  [ex_money]: https://hexdocs.pm/ex_money/readme.html
  [monetized]: https://hexdocs.pm/monetized/
  [money]: https://hexdocs.pm/money/Money.html
  [iss-money-lib-support]: https://github.com/aviabird/gringotts/projects/3#card-6801146
  [wiki-half-even]: https://en.wikipedia.org/wiki/Rounding#Round_half_to_even

  ### `card`, a payment source

  Gringotts provides a `Gringotts.CreditCard` type to hold card parameters
  which merchants fetch from their clients. The same type can also hold Debit
  card details.

  #### Note

  Gringotts only supports payment by debit or credit card, even though the
  gateways might support payment via other instruments such as e-wallets,
  vouchers, bitcoins or banks. Support for these instruments is planned in
  future releases.

      %CreditCard {
          first_name: "Harry",
          last_name: "Potter",
          number: "4242424242424242",
          month: 12,
          year: 2099,
          verification_code: "123",
          brand: "VISA"}
    
  ### `opts` for optional params

  `opts` is a `keyword` list of other options/information accepted by the
  gateway. The format, use and structure is gateway specific and documented in
  the Gateway's docs.

  ## Configuration

  Merchants must provide Gateway specific configuration in their application
  config in the usual elixir style. The required and optional fields are
  documented in every Gateway.

  > The required config keys are validated at runtime, as they include
  > authentication information. See `Gringotts.Adapter.validate_config/2`.

  ### Global config

  This is set using the `:global_config` key once in your application.

  #### `:mode`

  Gateways usually provide sandboxed environments to test applications and the
  merchant can use the `:mode` switch to choose between the sandbox or live
  environment.

  **Available Options:**

  * `:test` -- for sandbox environment, all requests will be routed to the
    gateway's sandbox/test API endpoints. Use this in your `:dev` and `:test`
    environments.  
  * `:prod` -- for live environment, all requests will reach the financial and
    banking networks. Switch to this in your application's `:prod` environment.

  **Example**

      config :gringotts, :global_config,
          # for live environment
          mode: :prod

  ### Gateway specific config

  The gateway level config is documented in their docs. They must be of the
  following format:

      config :gringotts, Gringotts.Gateways.XYZ,
        # some_documented_key: associated_value
        # some_other_key: another_value
  """

  @doc """
  Performs a (pre) Authorize operation.

  The authorization validates the `card` details with the banking network,
  places a hold on the transaction `amount` in the customer’s issuing bank and
  may also trigger risk management. Funds are not transferred, until the
  authorization is `capture/3`d.

  > `capture/3` must also be implemented alongwith this.

  ## Example

  To (pre) authorize a payment of $4.20 on a sample `card` with the `XYZ`
  gateway,

      amount = Money.new("4.2", :USD)
      # IF YOU DON'T USE ex_money
      # amount = %{value: Decimal.new("4.2"), currency: "EUR"}
      card = %Gringotts.CreditCard{first_name: "Harry", last_name: "Potter", number: "4200000000000000", year: 2099, month: 12, verification_code: "123", brand: "VISA"}
      {:ok, auth_result} = Gringotts.authorize(Gringotts.Gateways.XYZ, amount, card, opts)
  """
  def authorize(gateway, amount, card, opts \\ []) do
    config = get_and_validate_config(gateway)
    gateway.authorize(amount, card, [{:config, config} | opts])
  end

  @doc """
  Captures a pre-authorized `amount`.

  `amount` is transferred to the merchant account. The gateway might support,
  * partial captures,
  * multiple captures, per authorization

  ## Example

  To capture $4.20 on a previously authorized payment worth $4.20 by referencing
  the obtained authorization `id` with the `XYZ` gateway,

      amount = Money.new("4.2", :USD)
      # IF YOU DON'T USE ex_money
      # amount = %{value: Decimal.new("4.2"), currency: "EUR"}
      card = %Gringotts.CreditCard{first_name: "Harry", last_name: "Potter", number: "4200000000000000", year: 2099, month: 12, verification_code: "123", brand: "VISA"}
      Gringotts.capture(Gringotts.Gateways.XYZ, amount, auth_result.id, opts)
  """
  def capture(gateway, id, amount, opts \\ []) do
    config = get_and_validate_config(gateway)
    gateway.capture(id, amount, [{:config, config} | opts])
  end

  @doc """
  Transfers `amount` from the customer to the merchant.

  Gateway attempts to process a purchase on behalf of the customer, by debiting
  `amount` from the customer's account by charging the customer's `card`.

  This method _can_ be implemented as a chained call to `authorize/3` and
  `capture/3`. But it must be implemented as a single call to the Gateway if it
  provides a specific endpoint or action for this.

  > ***Note!**
  > All gateways must implement (atleast) this method.

  ## Example

  To process a purchase worth $4.2, with the `XYZ` gateway,

      amount = Money.new("4.2", :USD)
      # IF YOU DON'T USE ex_money
      # amount = %{value: Decimal.new("4.2"), currency: "EUR"}
      card = %Gringotts.CreditCard{first_name: "Harry", last_name: "Potter", number: "4200000000000000", year: 2099, month: 12, verification_code: "123", brand: "VISA"}
      Gringotts.purchase(Gringotts.Gateways.XYZ, amount, card, opts)
  """
  def purchase(gateway, amount, card, opts \\ []) do
    config = get_and_validate_config(gateway)
    gateway.purchase(amount, card, [{:config, config} | opts])
  end

  @doc """
  Refunds the `amount` to the customer's account with reference to a prior transfer.

  The end customer will usually see two bookings/records on his statement.

  ## Example

  To refund a previous purchase worth $4.20 referenced by `id`, with the `XYZ`
  gateway,

      amount = Money.new("4.2", :USD)
      # IF YOU DON'T USE ex_money
      # amount = %{value: Decimal.new("4.2"), currency: "EUR"}
      Gringotts.purchase(Gringotts.Gateways.XYZ, amount, id, opts)
  """
  def refund(gateway, amount, id, opts \\ []) do
    config = get_and_validate_config(gateway)
    gateway.refund(amount, id, [{:config, config} | opts])
  end

  @doc """
  Stores the payment-source data for later use, returns a `token`.

  > The token must be returned in the `Response.authorization` field.

  ## Note

  This usually enables _One-Click_ and _Recurring_ payments.

  ## Example

  To store a card (a payment-source) for future use, with the `XYZ` gateway,

      card = %Gringotts.CreditCard{first_name: "Jo", last_name: "Doe", number: "4200000000000000", year: 2099, month: 12, verification_code:  "123", brand: "VISA"}
      Gringotts.store(Gringotts.Gateways.XYZ, card, opts)
  """
  def store(gateway, card, opts \\ []) do
    config = get_and_validate_config(gateway)
    gateway.store(card, [{:config, config} | opts])
  end

  @doc """
  Removes a previously `token` from the gateway

  Once `unstore/3`d, the `token` must becom invalid, though some gateways might
  not support this feature.

  ## Example

  To unstore with the `XYZ` gateway,

      token = "some_privileged_customer"
      Gringotts.unstore(Gringotts.Gateways.XYZ, token)
  """
  def unstore(gateway, token, opts \\ []) do
    config = get_and_validate_config(gateway)
    gateway.unstore(token, [{:config, config} | opts])
  end

  @doc """
  Voids the referenced payment.

  This method attempts a reversal/immediate cancellation of the a previous
  transaction referenced by `id`.

  As a consequence, the customer usually **won't** see any booking on his
  statement.

  ## Example

  To void a previous (pre) authorization with the `XYZ` gateway,

      id = "some_previously_obtained_token"
      Gringotts.void(Gringotts.Gateways.XYZ, id, opts)
  """
  def void(gateway, id, opts \\ []) do
    config = get_and_validate_config(gateway)
    gateway.void(id, [{:config, config} | opts])
  end

  defp get_and_validate_config(gateway) do
    config = Application.get_env(:gringotts, gateway)
    # The following call to validate_config might raise an error
    gateway.validate_config(config)
    global_config = Application.get_env(:gringotts, :global_config) || [mode: :test]
    Keyword.merge(global_config, config)
  end
end
