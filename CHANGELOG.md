# Changelog

## [`v1.1.1-rc`][tag-1_1_1-rc] (2018-06-04)

### Added

* **core:** Remove the protocol implementation for `ex_money` since they
  implement it for us
  [e1cb32](https://github.com/kipcole9/money/commit/e1cb325a28a8318864ff1cbfbbb67574379a82c0)
* **development:** Removed those annoying compiler warnings!
* **docs:** Add docs about the money protocol.

### Changed

Remove support of [Wirecard](http://wirecard.com/) as we failed to implement it completely and it is
not at all usable. It is being archived in
[`wirecard`](https://github.com/aviabird/gringotts/tree/wirecard) branch.

## [`v1.1.0`][tag-1_1_0] (2018-04-22)

### Added

* **api:** Introduces a `Money` protocol ([#71][pr#71])
* **core:** Introduces `Response.t` ([#119][pr#91])
* **development:** Adds a useful mix task `gringotts.new` ([#78][pr#78]) to help
  with adding more gateways!
* **docs:** Adds changelog, contributing guide ([#117][pr#117])

### Changed

* **api:** Deprecates use of `floats` for money amounts, check issue
  [#62][iss#62] ([#71][pr#71])
* **core:** Removes payment worker, no application, no worker now after
  @josevalim [pointed it][joses-feedback] ([#118][pr#118])

[iss#62]: https://github.com/aviabird/gringotts/issues/62
[pr#71]: https://github.com/aviabird/gringotts/pulls/71
[pr#118]: https://github.com/aviabird/gringotts/pulls/118
[pr#91]: https://github.com/aviabird/gringotts/pulls/91
[pr#117]: https://github.com/aviabird/gringotts/pulls/117
[pr#78]:https://github.com/aviabird/gringotts/pulls/78
[pr#86]:https://github.com/aviabird/gringotts/pulls/86
[joses-feedback]:https://elixirforum.com/t/gringotts-a-complete-payment-library-for-elixir-and-phoenix-framework/11054/41

## [`v1.0.2`][tag-1_0_2] (2017-12-27)

### Added

* Gringotts now supports [Trexle](http://trexle.com/) as well :tada:

### Changed

* **api:** Reduced arity of public API calls by 1
  - No need to pass the name of the `worker` as argument.

## [`v1.0.1`][tag-1_0_1] (2017-12-23)

### Added

* **docs:** Improved documentation - made consistent accross gateways
* **tests:** Improved test coverage

## [`v1.0.0`][tag-1_0_0] (2017-12-20)

### Added

* **api:** Initial public API release.
* **core:** Single worker architecture, config fetched from `config.exs`
* **api:** Supported Gateways:
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
