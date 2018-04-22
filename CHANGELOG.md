# [`v1.1.0`][tag-1_1_0] (2018-04-22)

## Added

* **api** Introduces a `Money` protocol ([#71][pr#71])
* **core** Introduces Response.t ([#119][pr#91])
* **development** Adds a useful mix task gringotts.new ([#78][pr#78]) 
* **docs** Adds changelog, contributing guide ([#117][pr#117])

## Changed

* **api** Deprecates use of `floats` for money amounts, check issue [#62][iss#62] ([#71][pr#71])
* **core** Removes payment worker, no application, no worker now after josevalim [pointed it][jose-feedback] ([#118][pr#118]) 

[iss#62]: https://github.com/aviabird/gringotts/issues/62
[pr#71]: https://github.com/aviabird/gringotts/pulls/71
[pr#118]: https://github.com/aviabird/gringotts/pulls/118
[pr#91]: https://github.com/aviabird/gringotts/pulls/91
[pr#117]: https://github.com/aviabird/gringotts/pulls/117
[pr#78]:https://github.com/aviabird/gringotts/pulls/78
[pr#86]:https://github.com/aviabird/gringotts/pulls/86
[jose-feedback]:https://elixirforum.com/t/gringotts-a-complete-payment-library-for-elixir-and-phoenix-framework/11054/41

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
  - CAMSa

[tag-1_1_0]: https://github.com/aviabird/gringotts/compare/1.1.0...1.0.2
[tag-1_0_2]: https://github.com/aviabird/gringotts/compare/1.0.2...1.0.1
[tag-1_0_1]: https://github.com/aviabird/gringotts/compare/1.0.1...1.0.0
[tag-1_0_0]: https://github.com/aviabird/gringotts/releases/tag/v1.0.0
