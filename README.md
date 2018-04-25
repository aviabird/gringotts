<p align="center">
  <a href="" target='_blank'>
    <img alt="Gringotts Logo" title="Gringotts Logo" src="https://res.cloudinary.com/ashish173/image/upload/v1513770454/gringotts_logo.png" width="200">
  </a>
</p>

<p align="center">
  Gringotts is a payment processing library in Elixir integrating various payment gateways, drawing motivation for Shopify's <a href="https://github.com/activemerchant/active_merchant"><code>activemerchant</code></a> gem. Checkout the <a href="https://gringottspay.herokuapp.com/" target="_">Demo</a> here.
</p>
<p align="center">
 <a href="https://travis-ci.org/aviabird/gringotts"><img src="https://travis-ci.org/aviabird/gringotts.svg?branch=master"  alt='Build Status' /></a>  <a href='https://coveralls.io/github/aviabird/gringotts?branch=master'><img src='https://coveralls.io/repos/github/aviabird/gringotts/badge.svg?branch=master' alt='Coverage Status' /></a> <a href=""><img src="https://img.shields.io/hexpm/v/gringotts.svg"/></a> <a href="https://inch-ci.org/github/aviabird/gringotts"><img src="http://inch-ci.org/github/aviabird/gringotts.svg?branch=master" alt="Docs coverage"></img></a> <a href="https://gitter.im/aviabird/gringotts"><img src="https://badges.gitter.im/aviabird/gringotts.svg"/></a>
 <a href="https://www.codetriage.com/aviabird/gringotts"><img src="https://www.codetriage.com/aviabird/gringotts/badges/users.svg" alt='Help Contribute to Open Source' /></a>
</p>

Gringotts offers a **simple and unified API** to access dozens of different payment
gateways with very different APIs, response schemas, documentation and jargon.

## Installation

### From [`hex.pm`][hexpm]

Add `gringotts` to the list of dependencies of your application.
```elixir
# your mix.exs

def deps do
  [
    {:gringotts, "~> 1.0"},
    # ex_money provides an excellent Money library, and integrates
    # out-of-the-box with Gringotts
    {:ex_money, "~> 1.1.0"}
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

Copy and paste this code in a module or an `IEx` session

```elixir
alias Gringotts.Gateways.Monei
alias Gringotts.{CreditCard}

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

## Supported Gateways

| Gateway               | Supported countries                                                                                                                                                                                                                                                        |
| ------                | -----                                                                                                                                                                                                                                                                      |
| [Authorize.Net][anet] | AD, AT, AU, BE, BG, CA, CH, CY, CZ, DE, DK, ES, FI, FR, GB, GB, GI, GR, HU, IE, IT, LI, LU, MC, MT, NL, NO, PL, PT, RO, SE, SI, SK, SM, TR, US, VA                                                                                                                         |
| [CAMS][cams]          | AU, US                                                                                                                                                                                                                                                                     |
| [MONEI][monei]         | DE, EE, ES, FR, IT, US                                                                                                                                                                                                                                                     |
| [PAYMILL][paymill]    | AD, AT, BE, BG, CH, CY, CZ, DE, DK, EE, ES, FI, FO, FR, GB, GI, GR, HU, IE, IL, IS, IT, LI, LT, LU, LV, MT, NL, NO, PL, PT, RO, SE, SI, SK, TR, VA                                                                                                                         |
| [Stripe][stripe]      | AT, AU, BE, CA, CH, DE, DK, ES, FI, FR, GB, IE, IN, IT, LU, NL, NO, SE, SG, US                                                                                                                                                                                             |
| [TREXLE][trexle]      | AD, AE, AT, AU, BD, BE, BG, BN, CA, CH, CY, CZ, DE, DK, EE, EG, ES, FI, FR, GB, GI, GR, HK, HU, ID, IE, IL, IM, IN, IS, IT, JO, KW, LB, LI, LK, LT, LU, LV, MC, MT, MU, MV, MX, MY, NL, NO, NZ, OM, PH, PL, PT, QA, RO, SA, SE, SG, SI, SK, SM, TR, TT, UM, US, VA, VN, ZA |
| [Wirecard][wirecard]  | AD, AT, BE, BG, CH, CY, CZ, DE, DK, EE, ES, FI, FR, GB, GI, GR, HU, IE, IL, IM, IS, IT, LI, LT, LU, LV, MC, MT, NL, NO, PL, PT, RO, SE, SI, SK, SM, TR, VA                                                                                                                 |

[anet]: http://www.authorize.net/
[cams]: https://www.centralams.com/
[monei]: http://www.monei.net/
[paymill]: https://www.paymill.com
[stripe]: https://www.stripe.com/
[trexle]: https://www.trexle.com/
[wirecard]: http://www.wirecard.com
[demo]: https://gringottspay.herokuapp.com/

## Road Map

Apart from supporting more and more gateways, we also keep a somewhat detailed
plan for the future on our [wiki][roadmap].

## FAQ

#### 1. What's with the name? "Gringotts"?

Gringotts has a nice ring to it. Also [this][reason].

#### 2. What is the worker doing in the middle?

We wanted to "supervise" our payments, and power utilities to process recurring
payments, subscriptions with it. But yes, as of now, it is a bottle neck and
unnecessary.

It's slated to be removed in [`v2.0.0`][milestone-2_0_0_alpha] and any
supervised/async/parallel work can be explicitly managed via native elixir
constructs.

**In fact, it's already been removed from our [dev](#) branch.**

[milestone-2_0_0_alpha]: https://github.com/aviabird/gringotts/milestone/3
[reason]: http://harrypotter.wikia.com/wiki/Gringotts

## License

MIT

[roadmap]: https://github.com/aviabird/gringotts/wiki/Roadmap
