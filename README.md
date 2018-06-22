<p align="center">
  <a href="" target='_blank'>
    <img alt="Gringotts Logo" title="Gringotts Logo" src="https://res.cloudinary.com/ashish173/image/upload/v1513770454/gringotts_logo.png" width="200">
  </a>
</p>

<p align="center">
  Gringotts is a payment processing library in Elixir integrating various payment gateways, drawing motivation from Shopify's <a href="https://github.com/activemerchant/active_merchant"><code>activemerchant</code></a> gem and <a href="https://github.com/joshnuss/commerce_billing"><code>commerce_billing</code></a>. Checkout the <a href="https://gringottspay.herokuapp.com/" target="_">demo here</a>.
</p>
<p align="center">
 <a href="https://travis-ci.org/aviabird/gringotts"><img src="https://travis-ci.org/aviabird/gringotts.svg?branch=master"  alt='Build Status' /></a>  <a href='https://coveralls.io/github/aviabird/gringotts?branch=master'><img src='https://coveralls.io/repos/github/aviabird/gringotts/badge.svg?branch=master' alt='Coverage Status' /></a> <a href=""><img src="https://img.shields.io/hexpm/v/gringotts.svg"/></a> <a href="https://inch-ci.org/github/aviabird/gringotts"><img src="http://inch-ci.org/github/aviabird/gringotts.svg?branch=master" alt="Docs coverage"></img></a> <a href="https://gitter.im/aviabird/gringotts"><img src="https://badges.gitter.im/aviabird/gringotts.svg"/></a>
 <a href="https://www.codetriage.com/aviabird/gringotts"><img src="https://www.codetriage.com/aviabird/gringotts/badges/users.svg" alt='Help Contribute to Open Source' /></a>
</p>

Gringotts offers a **simple and unified API** to access dozens of different payment
gateways with very different APIs, response schemas, documentation and jargon.

The project started out **as a fork of [`commerce_billing`][commerce-billing]** and
the notable differences are:
1. No `GenServer` process to act as a "payment worker".
2. Consistent docs and good amount of tests.
3. Support many more payment gateways.

[commerce-billing]: https://github.com/joshnuss/commerce_billing

## Installation

### From [`hex.pm`][hexpm]

Add `gringotts` to the list of dependencies of your application.
```elixir
# your mix.exs

def deps do
  [
    {:gringotts, "~> 1.1"},
    # ex_money provides an excellent Money library, and integrates
    # out-of-the-box with Gringotts
    {:ex_money, ">= 2.6.0"}
  ]
end
```

## Usage

This simple example demonstrates how a `purchase` can be made using a sample
credit card using the [MONEI][monei] gateway.

One must "register" their account with `gringotts` ie, put all the
authentication details in the Application config. Usually via
`config/config.exs`

```elixir
# config/config.exs

config :gringotts, Gringotts.Gateways.Monei,
    userId: "your_secret_user_id",
    password: "your_secret_password",
    entityId: "your_secret_channel_id"
```

Copy and paste this code in a module or an `IEx` session, or use this handy
[`.iex.exs`][monei-bindings] for all the bindings.

```elixir
alias Gringotts.Gateways.Monei
alias Gringotts.CreditCard

# a fake sample card that will work now because the Gateway is by default
# in "test" mode.

card = %CreditCard{
  first_name: "Harry",
  last_name: "Potter",
  number: "4200000000000000",
  year: 2099, month: 12,
  verification_code:  "123",
  brand: "VISA"
}

# a sum of $42
amount = Money.new(42, :USD)

case Gringotts.purchase(Monei, amount, card) do
  {:ok,    %{id: id}} ->
    IO.puts("Payment authorized, reference token: '#{id}'")

  {:error, %{status_code: error, raw: raw_response}} ->
    IO.puts("Error: #{error}\nRaw:\n#{raw_response}")
end
```

[hexpm]: https://hex.pm/packages/gringotts
[monei]: http://www.monei.net
[monei-bindings]: https://gist.github.com/oyeb/a2e2ac5986cc90a12a6136f6bf1357e5

## On the `Gringotts.Money` protocol and money representation

All financial applications must take proper care when representing money in
their system. Using simple `float`ing values might lead to losses in the real
world due to [various reasons][floating-issues].

Most payment gateways are strict about the formatting of the `amount` in the
request, hence we cannot render arbitrary floating amounts like
`$4.99999`. Moreover, such amounts might mean something to your application but
they don't have any value in the real world (since you can't charge someone for
a fraction of a US cent).

Your application **must round** such amounts before invoking Gringotts **and manage
any remainders sensibly** yourself.

> Gringotts may perform rounding using the [`half-even`][wiki-half-even]
strategy, but it will discard remainders if any.

### Supported "Money" libraries

Gringotts does not ship with any library to work with monies. You are free to
choose any monie library you wish, as long as they implement the
[`Gringotts.Money`][protocol] for their type!

That said, we recommend [`ex_money`][ex_money] (above [`v2.6.0`][2_6_0]) to
represent monies. You just have to add it in your `deps()`.

[protocol]: https://github.com/aviabird/gringotts/blob/dev/lib/gringotts/money.ex
[floating-issues]: https://elixirforum.com/t/comparison-of-decimals-not-logical/770/21
[wiki-half-even]: https://en.wikipedia.org/wiki/Rounding#Round_half_to_even
[ex-money]: https://github.com/kipcole9/money
[2_6_0]: https://github.com/kipcole9/money/releases/tag/v2.6.0

## Supported Gateways

| Gateway               | PCI compliance | `purchase` | `authorize` | `capture` | `void`   | `refund` | (card) `store` | (card) `unstore` |
|-----------------------|----------------|------------|-------------|-----------|----------|----------|----------------|------------------|
| [Authorize.Net][anet] | mandatory      | &#9989;    | &#9989;     | &#9989;   | &#9989;  | &#9989;  | &#9989;        | &#9989;          |
| [CAMS][cams]          | mandatory      | &#9989;    | &#9989;     | &#9989;   | &#9989;  | &#9989;  | &#10060;       | &#10060;         |
| [MONEI][monei]        | mandatory      | &#9989;    | &#9989;     | &#9989;   | &#9989;  | &#9989;  | &#9989;        | &#10060;         |
| [PAYMILL][paymill]    | optional       | &#9989;    | &#9989;     | &#9989;   | &#9989;  | &#9989;  | &#10060;       | &#10060;         |
| [Stripe][stripe]      | optional       | &#9989;    | &#9989;     | &#9989;   | &#9989;  | &#9989;  | &#9989;        | &#9989;          |
| [TREXLE][trexle]      | mandatory      | &#9989;    | &#9989;     | &#9989;   | &#10060; | &#9989;  | &#9989;        | &#10060;         |

[anet]: http://www.authorize.net/
[cams]: https://www.centralams.com/
[monei]: http://www.monei.net/
[paymill]: https://www.paymill.com
[stripe]: https://www.stripe.com/
[trexle]: https://www.trexle.com/
[wirecard]: http://www.wirecard.com
[demo]: https://gringottspay.herokuapp.com/

## [Road Map][roadmap]

Apart from supporting more and more gateways, we also keep a somewhat detailed
plan for the future on our [wiki][roadmap].

## FAQ

#### 1. What's with the name? "Gringotts"?

Gringotts has a nice ring to it. Also [this][reason].

[reason]: http://harrypotter.wikia.com/wiki/Gringotts

## License

MIT

[roadmap]: https://github.com/aviabird/gringotts/wiki/Roadmap
