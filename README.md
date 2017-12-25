<p align="center">
  <a href="" target='_blank'>
    <img alt="Gringotts Logo" title="Gringotts Logo" src="https://res.cloudinary.com/ashish173/image/upload/v1513770454/gringotts_logo.png" width="200">
  </a>
</p>

<p align="center">
  Gringotts is a payment processing library in Elixir integrating various payment gateways, this draws motivation for shopify's <a href="https://github.com/activemerchant/active_merchant">activemerchant</a> gem.
</p>
<p align="center">
 <a href="https://travis-ci.org/aviabird/gringotts"><img src="https://travis-ci.org/aviabird/gringotts.svg?branch=master"  alt='Build Status' /></a>  <a href='https://coveralls.io/github/aviabird/gringotts?branch=master'><img src='https://coveralls.io/repos/github/aviabird/gringotts/badge.svg?branch=master' alt='Coverage Status' /></a> <a href=""><img src="https://img.shields.io/hexpm/v/gringotts.svg"/></a> <a href="https://inch-ci.org/github/aviabird/gringotts"><img src="http://inch-ci.org/github/aviabird/gringotts.svg?branch=master" alt="Docs coverage"></img></a> <a href="https://gitter.im/aviabird/gringotts"><img src="https://badges.gitter.im/aviabird/gringotts.svg"/></a>
</p>

A simple and unified API to access dozens of different payment
gateways with very different internal APIs is what Gringotts has to offer you.

## Installation

### From hex.pm

Make the following changes to the `mix.exs` file.

Add gringotts to the list of dependencies.
```elixir
def deps do
  [
    {:gringotts, "~> 1.0"}
  ]
end
```

Add gringotts to the list of applications to be started.
```elixir
def application do
  [
    extra_applications: [:gringotts]
  ]
end
```

## Usage

This simple example demonstrates how a purchase can be made using a person's credit card details.

Add configs in `config/config.exs` file.

```elixir
config :gringotts, Gringotts.Gateways.Stripe,
  adapter: Gringotts.Gateways.Stripe,
  api_key: "YOUR_KEY",
  default_currency: "USD"

```

Copy and paste this code in your module

```elixir
alias Gringotts.Gateways.Stripe
alias Gringotts.{CreditCard, Address, Worker, Gateways}

card = %CreditCard{
  first_name: "John",
  last_name: "Smith",
  number: "4242424242424242",
  year: "2017",
  month: "12",
  cvc: "123"
}

address = %Address{
  street1: "123 Main",
  city: "New York",
  region: "NY",
  country: "US",
  postal_code: "11111"
}

case Gringotts.purchase(:my_gateway, Stripe, 199.95, card, billing_address: address,
                                                   description: "Amazing T-Shirt") do
  {:ok,    %{authorization: authorization}} ->
    IO.puts("Payment authorized #{authorization}")

  {:error, %{code: :declined, reason: reason}} ->
    IO.puts("Payment declined #{reason}")

  {:error, %{code: error}} ->
    IO.puts("Payment error #{error}")
end
```

## Supported Gateways

* [Stripe](https://stripe.com/) - AT, AU, BE, CA, CH, DE, DK, ES, FI, FR, GB, IE, IN, IT, LU, NL, NO, SE, SG, US
* [PAYMILL](https://paymill.com) - AD, AT, BE, BG, CH, CY, CZ, DE, DK, EE, ES, FI, FO, FR, GB, GI, GR, HU, IE, IL, IS, IT, LI, LT, LU, LV, MT, NL, NO, PL, PT, RO, SE, SI, SK, TR, VA
* [Authorize.Net](http://www.authorize.net/) - AD, AT, AU, BE, BG, CA, CH, CY, CZ, DE, DK, ES, FI, FR, GB, GB, GI, GR, HU, IE, IT, LI, LU, MC, MT, NL, NO, PL, PT, RO, SE, SI, SK, SM, TR, US, VA

* [MONEI](http://www.monei.net/) - AD, AT, BE, BG, CA, CH, CY, CZ, DE, DK, EE, ES, FI, FO, FR, GB, GI, GR, HU, IE, IL, IS, IT, LI, LT, LU, LV, MT, NL, NO, PL, PT, RO, SE, SI, SK, TR, US, VA
* [CAMS: Central Account Management System](https://www.centralams.com/) - AU, US
* [Wirecard](http://www.wirecard.com) - AD, CY, GI, IM, MT, RO, CH, AT, DK, GR, IT, MC, SM, TR, BE, EE, HU, LV, NL, SK, GB, BG, FI, IS, LI, NO, SI, VA, FR, IL, LT, PL, ES, CZ, DE, IE, LU, PT, SE


## Road Map

- Support more gateways on an on-going basis.
- Each gateway request is hosted in a worker process and supervised.

## License

MIT
