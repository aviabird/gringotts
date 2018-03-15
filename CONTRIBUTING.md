# Contributing to [`gringotts`][gringotts]

There are many ways to contribute to `gringotts`,

1. [Integrate a new Payment Gateway][wiki-new-gateway].
2. Expanding the feature coverage of (partially) supported gateways.
3. Moving forward on the [roadmap][roadmap] or on tasks being tracked in the
   [milestones][milestones].

We manage our development using [milestones][milestones] and issues so if you're
a first time contributor, look out for the [`good first issue`][first-issues]
and the [`hotlist: community-help`][ch-issues] labels on the [issues][issues]
page.

The docs are hosted on [hexdocs.pm][hexdocs] and are updated for each
release. **You must build the docs locally using `mix docs` to get the bleeding
edge developer docs.**

The article on [Gringott's Architecture][wiki-arch] explains how API calls are
processed.

:exclamation: ***Please base your work on the `dev` branch.***

[roadmap]: https://github.com/aviabird/gringotts/wiki/Roadmap
[wiki-arch]: https://github.com/aviabird/gringotts/wiki/Architecture

### PR submission checklist

Each PR should introduce a *focussed set of changes*, and ideally not span over
unrelated modules.

* [ ] Run the edited files through [credo][credo] and the Elixir
      [formatter][hashrocket-formatter] (new in `v1.6`).
* [ ] Check the test coverage by running `mix coveralls`. 100% coverage is not
      strictly required.
* [ ] If the PR introduces a new Gateway or just Gateway specific changes,
      please format the title like so,\
      `[<gateway-name>] <the-title>`

[gringotts]: https://github.com/aviabird/gringotts
[milestones]: https://github.com/aviabird/gringotts/milestones
[issues]: https://github.com/aviabird/gringotts/issues
[first-issues]: https://github.com/aviabird/gringotts/issues?q=is%3Aissue+is%3Aopen+label%3A"good+first+issue"
[ch-issues]: https://github.com/aviabird/gringotts/issues?q=is%3Aissue+is%3Aopen+label%3A"hotfix%3A+community-help"
[hexdocs]: https://hexdocs.pm/gringotts
[credo]: https://github.com/rrrene/credo
[hashrocket-formatter]: https://hashrocket.com/blog/posts/format-your-elixir-code-now

# Style Guidelines

We use [`credo`][credo] and the elixir formatter for consistent style, so please
use them!

## General Rules

* Keep line length below 120 characters.
* Complex anonymous functions should be extracted into named functions.
* One line functions, should only take up one line!
* Pipes are great, but don't use them, if they are less readable than brackets
  then drop the pipe!

## Writing documentation

All our docs are inline and built using [`ExDocs`][exdocs]. Please take a look
at how the docs are structured for the [MONEI gateway][src-monei] for
inspiration.

[exdocs]: https://github.com/elixir-lang/ex_doc
[src-monei]: https://github.com/aviabird/gringotts/blob/dev/lib/gringotts/gateways/monei.ex

## Writing test cases

> This is WIP.

`gringotts` has mock and integration tests. We have currently used
[`bypass`][bypass] and [`mock`][mock] for mock tests, but we don't recommed
using `mock` as it constrains tests to run serially. Use [`mox`][mox] instead.\
Take a look at [MONEI's mock tests][src-monei-tests] for inspiration.

--------------------------------------------------------------------------------

> **Where to next?**
> Wanna add a new gateway? Head to our [guide][wiki-new-gateway] for that.

[wiki-new-gateway]: https://github.com/aviabird/gringotts/wiki/Adding-a-new-Gateway
[bypass]: https://github.com/pspdfkit-labs/bypass
[mock]: https://github.com/jjh42/mock
[mox]: https://github.com/plataformatec/mox
[src-monei-tests]: https://github.com/aviabird/gringotts/blob/dev/test/gateways/monei_test.exs
[gringotts]: https://github.com/aviabird/gringotts
[docs]: https://hexdocs.pm/gringotts/Gringotts.html
