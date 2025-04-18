# Changelog

## [`v1.1.1`](https://github.com/aviabird/gringotts/compare/v1.1.0...v1.1.1) (2023-02-19)

### Deps
Updates elixir dep to 1.14 with erlang otp 25. Compiled time warnings have been removed.

### Core
Remove the protocol implementation for `ex_money` since they implement it for us
[e1cb32](https://github.com/kipcole9/money/commit/e1cb325a28a8318864ff1cbfbbb67574379a82c0).

### Gateways
- Refactored `Paymill`. Added missing API functions.
- Remove support of [Wirecard](http://wirecard.com/) as it fails to meet the
  standards of this library and it is not at all usable. It is being archived
  in [`wirecard`](https://github.com/aviabird/gringotts/tree/wirecard) branch.

## [`v1.1.0`][tag-1_1_0] (2018-04-22)

### Core
* Introduces the `Gringotts.Money` protocol ([#71][pr#71])
  - Deprecates use of `floats` for money amounts, see [#62][iss#62] for
    motivation.
* Removes payment worker! No application, no worker as per the community's
  [suggestion][joses-feedback] ([#118][pr#118]).

### Miscellaneous
* Introduces `Response.t` ([#119][pr#91]).
* Adds a useful mix task `gringotts.new` ([#78][pr#78]) to help with adding more
  gateways!
* Adds changelog, contributing guide ([#117][pr#117]).


[iss#62]: https://github.com/aviabird/gringotts/issues/62
[pr#71]: https://github.com/aviabird/gringotts/pulls/71
[pr#118]: https://github.com/aviabird/gringotts/pulls/118
[pr#91]: https://github.com/aviabird/gringotts/pulls/91
[pr#117]: https://github.com/aviabird/gringotts/pulls/117
[pr#78]:https://github.com/aviabird/gringotts/pulls/78
[pr#86]:https://github.com/aviabird/gringotts/pulls/86
[joses-feedback]:https://elixirforum.com/t/gringotts-a-complete-payment-library-for-elixir-and-phoenix-framework/11054/41

## [`v1.0.2`][tag-1_0_2] (2017-12-27)

### Core
* Reduced arity of public API calls by 1
  - No need to pass the name of the `worker` as argument.

### Gateways
* Gringotts now supports [Trexle](http://trexle.com/) as well :tada:

## [`v1.0.1`][tag-1_0_1] (2017-12-23)

### Core

* Improved documentation by making them consistent across gateways.
* Improved test coverage, though tests need some more :heart:

## [`v1.0.0`][tag-1_0_0] (2017-12-20)

### Initial public API release

### Core
* Single worker architecture, config fetched from `config.exs`.

### Gateways
- [Stripe](http://stripe.com/)
- [MONEI](http://monei.net/)
- [Paymill](https://www.paymill.com/en/)
- [WireCard](http://wirecard.com/)
- [CAMS](http://www.centralams.com/)

[tag-1_1_1_rc]: https://github.com/aviabird/gringotts/releases/tag/v1.1.1-rc
[tag-1_1_0]: https://github.com/aviabird/gringotts/compare/1.1.0...1.0.2
[tag-1_0_2]: https://github.com/aviabird/gringotts/compare/1.0.2...1.0.1
[tag-1_0_1]: https://github.com/aviabird/gringotts/compare/1.0.1...1.0.0
[tag-1_0_0]: https://github.com/aviabird/gringotts/releases/tag/v1.0.0
