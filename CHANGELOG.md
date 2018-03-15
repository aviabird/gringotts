# [`v1.1.0-alpha`][tag-1_1_0_alpha]

## Added

* [`ISS`][iss#80] [`PR`][pr#78]
Add a `Mix` task that generates a barebones gateway implementation and test suite.

## Changed

* [`ISS`][iss#62] [`PR`][pr#71] [`PR`][pr#86]
Deprecate use of `floats` for money amounts, introduce the `Gringotts.Money` protocol.

[iss#62]: https://github.com/aviabird/gringotts/issues/62
[iss#80]: https://github.com/aviabird/gringotts/issues/80

[pr#71]: https://github.com/aviabird/gringotts/pulls/71
[pr#78]:https://github.com/aviabird/gringotts/pulls/78
[pr#86]:https://github.com/aviabird/gringotts/pulls/86

# [`v1.0.2`][tag-1_0_2]

## Added

* New Gateway: **Trexle**

## Changed

* Reduced arity of public API calls by 1
  - No need to pass the name of the `worker` as argument.

# [`v1.0.1`][tag-1_0_1]

## Added

* Improved documentation - made consistent accross gateways
* Improved test coverage

# [`v1.0.0`][tag-1_0_0]

* Initial public API release.
* Single worker architecture, config fetched from `config.exs`
* Supported Gateways:
  - Stripe
  - MONEI
  - Paymill
  - WireCard
  - CAMS

[tag-1_1_0_alpha]: https://github.com/aviabird/gringotts/releases/tag/v1.1.0-alpha
[tag-1_0_2]: https://github.com/aviabird/gringotts/releases/tag/v1.0.2
[tag-1_0_1]: https://github.com/aviabird/gringotts/releases/tag/v1.0.1
[tag-1_0_0]: https://github.com/aviabird/gringotts/releases/tag/v1.0.0
