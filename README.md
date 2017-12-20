<p align="center">
  <a href="" target='_blank'>
    <img alt="Gringotts Logo" title="Gringotts Logo" src="https://res.cloudinary.com/ashish173/image/upload/v1513770454/gringotts_logo.png" width="200">
  </a>
</p>

<p align="center">
  Gringotts is a payment processing library in Elixir integrating various payment gateways, this draws motivation for shopify's [activemerchant](https://github.com/activemerchant/active_merchant) gem.
</p>
<p align="center">
  [![Build](https://travis-ci.org/aviabird/gringotts.svg?branch=master)](https://travis-ci.org/aviabird/gringotts) [![Coverage](https://coveralls.io/repos/github/aviabird/gringotts/badge.svg?branch=master)](https://coveralls.io/github/aviabird/gringotts?branch=master)
</p>

A simple and unified API to access dozens of different payment
gateways with very different internal APIs is what Gringotts has to offer you.

## Installation

### From hex.pm
TODO: add this once the api is hosted on hexpm

## Usage

This simple example demonstrates how a purchase can be made using a person's credit card details.

Add configs in `config/config.exs` file.

```elixir
config :Gringotts, Gringotts.Gateways.Stripe,
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
