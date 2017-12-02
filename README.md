Kuber.Hex
=================

[![CircleCI](https://circleci.com/bb/aviabird/kuber_hex/tree/master.svg?style=svg)](https://circleci.com/bb/aviabird/kuber_hex/tree/master)

Payment processing library for Elixir. Based on [Shopify's](http://shopify.com) [ActiveMerchant](http://github.com/Shopify/active_merchant) ruby gem

An open source initiative of [Aviabird Technologies](https://aviabird.com)

## Supported Gateways

- Bogus
- Stripe

## Advantages of Elixir

- **Fault tolerant**: Each worker is supervised, so a new worker is started in the event of errors. Network errors are caught and payment is retried (not yet working).
- **Distributed**: Run workers on different machines.
- **Scalable**: Run multiple workers and adjust number of workers as needed.
- **Throughput**: Takes advantage of all cores. For example on my laptop with 4 cores (2 threads per core), I can do 100 authorizations with Stripe in 10 seconds. Thats 864,000 transactions per day. ebay does 1.4M/day.
- **Hot code swap**: Update code while the system is running

## Card processing example

```elixir
alias Kuber.Hex
alias Billing.{CreditCard, Address, Worker, Gateways}

config = %{credentials: {"sk_test_BQokikJOvBiI2HlWgH4olfQ2", ""},
           default_currency: "USD"}

Worker.start_link(Gateways.Stripe, config, name: :my_gateway)

card = %CreditCard{
  name: "John Smith",
  number: "4242424242424242",
  expiration: {2017, 12},
  cvc: "123"
}

address = %Address{
  street1: "123 Main",
  city: "New York",
  region: "NY",
  country: "US",
  postal_code: "11111"
}

case Billing.authorize(:my_gateway, 199.95, card, billing_address: address,
                                                   description: "Amazing T-Shirt") do
  {:ok,    %{authorization: authorization}} ->
    IO.puts("Payment authorized #{authorization}")

  {:error, %{code: :declined, reason: reason}} ->
    IO.puts("Payment declined #{reason}")

  {:error, %{code: error}} ->
    IO.puts("Payment error #{error}")
end
```

## Road Map

- Support multiple gateways (PayPal, Stripe, Authorize.net, Braintree etc..)
- Support gateways that bill directly and those that use html integrations.
- Support recurring billing
- Each gateway is hosted in a worker process and supervised.
- Workers can be pooled. (using poolboy)
- Workers can be spread on multiple nodes
- The gateway is selected by first calling the "Gateway Factory" process. The "Gateway Factory" decides which gateway to use. Usually it will just be one type based on configuration setting in mix.exs (i.e. Stripe), but the Factory can be replaced with something fancier. It will enable scenarios like:
    - Use one gateway for visa another for mastercard
    - Use primary gateway (i.e PayPal), but when PayPal is erroring switch to secondary/backup gateway (i.e. Authorize.net)
    - Currency specific gateway, i.e. use one gateway type for USD another for CAD
- Retry on network failure

## License

MIT
