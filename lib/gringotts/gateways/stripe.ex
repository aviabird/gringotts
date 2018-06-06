defmodule Gringotts.Gateways.Stripe do
  @moduledoc """
  Stripe gateway implementation. For reference see [Stripe's API documentation](https://stripe.com/docs/api).
  The following features of Stripe are implemented:

  | Action                       | Method        |
  | ------                       | ------        |
  | Pre-authorize                | `authorize/3` |
  | Capture                      | `capture/3`   |
  | Refund                       | `refund/3`    |
  | Reversal                     | `void/2`      |
  | Debit                        | `purchase/3`  |
  | Store                        | `store/2`     |
  | Unstore                      | `unstore/2`   |

  ## The `opts` argument
  Most `Gringotts` API calls accept an optional `Keyword` list `opts` to supply
  optional arguments for transactions with the Stripe gateway. The following keys
  are supported:

  | Key                    | Status           |
  | ----                   | ----             |
  | `currency`             | **Implemented**  |  
  | `capture`              | **Implemented**  |
  | `description`          | **Implemented**  |
  | `metadata`             | **Implemented**  |
  | `receipt_email`        | **Implemented**  |
  | `shipping`             | **Implemented**  |
  | `customer`             | **Implemented**  |
  | `source`               | **Implemented**  |
  | `statement_descriptor` | **Implemented**  |
  | `charge`               | **Implemented**  |
  | `reason`               | **Implemented**  |
  | `account_balance`      | Not implemented  |
  | `business_vat_id`      | Not implemented  |
  | `coupon`               | Not implemented  |
  | `default_source`       | Not implemented  |
  | `email`                | Not implemented  |
  | `shipping`             | Not implemented  |

  ## Note

  _This module can be used by both PCI-DSS compliant as well as non-compliant
  merchants!_

  ### I'm not PCI-DSS compliant

  No worries, both `authorize/3` and `purchase/3` accept a
  "payment-source-identifier" (a `string`) instead of a `CreditCard.t`
  struct. You'll have to generate this identifier using [Stripe.js and
  Elements][stripe-js] client-side.

  ### I'm PCI-DSS compliant

  In that case, you need not use [Stripe.js or Elements][stripe-js] and can
  directly accept the client's card info and pass the `CreditCard.t` struct to
  this module's functions.

  [stripe-js]: https://stripe.com/docs/sources/cards

  ## Registering your Stripe account at `Gringotts`

  After [making an account on Stripe](https://stripe.com/), head
  to the dashboard and find your account `secrets` in the `API` section.

  ## Here's how the secrets map to the required configuration parameters for Stripe:
  | Config parameter | Stripe secret  |
  | -------          | ----           |
  | `:secret_key`    | **Secret key** |

  Your Application config must look something like this:

      config :gringotts, Gringotts.Gateways.Stripe,
          secret_key: "your_secret_key",
          default_currency: "usd"
  """

  @base_url "https://api.stripe.com/v1"

  use Gringotts.Gateways.Base
  use Gringotts.Adapter, required_config: [:secret_key]

  alias Gringotts.{Address, CreditCard, Money}

  @doc """
  Performs a (pre) Authorize operation.

  The authorization validates the card details with the banking network,
  places a hold on the transaction amount in the customer’s issuing bank and
  also triggers risk management. Funds are not transferred.

  Stripe returns an `charge_id` which should be stored at your side and can be
  used later to:
  * `capture/3` an amount.
  * `void/2` a pre-authorization.

  ## Note
  Uncaptured charges expire in 7 days. For more information, [see authorizing
  charges and settling
  later](https://support.stripe.com/questions/can-i-authorize-a-charge-and-then-wait-to-settle-it-later).

  ## Example
  The following session shows how one would (pre) authorize a payment of $10 on
  a sample `card`.

      iex> card = %CreditCard{
            first_name: "John",
            last_name: "Smith",
            number: "4242424242424242",
            year: "2017",
            month: "12",
            verification_code: "123"
          }

          address = %Address{
            street1: "123 Main",
            city: "New York",
            region: "NY",
            country: "US",
            postal_code: "11111"
          }

      iex> opts = [currency: "usd", address: address]
      iex> amount = 10

      iex> Gringotts.authorize(Gringotts.Gateways.Stripe, amount, card, opts)
  """
  @spec authorize(Money.t(), CreditCard.t() | String.t(), keyword) :: map
  def authorize(amount, payment, opts) do
    params = create_params_for_auth_or_purchase(amount, payment, opts, false)
    commit(:post, "charges", params, opts)
  end

  @doc """
  Transfers amount from the customer to the merchant.

  Stripe attempts to process a purchase on behalf of the customer, by debiting
  amount from the customer's account by charging the customer's card.

  ## Example
  The following session shows how one would process a payment in one-shot,
  without (pre) authorization.

      iex> card = %CreditCard{
            first_name: "John",
            last_name: "Smith",
            number: "4242424242424242",
            year: "2017",
            month: "12",
            verification_code: "123"
          }

          address = %Address{
            street1: "123 Main",
            city: "New York",
            region: "NY",
            country: "US",
            postal_code: "11111"
          }

      iex> opts = [currency: "usd", address: address]
      iex> amount = 5

      iex> Gringotts.purchase(Gringotts.Gateways.Stripe, amount, card, opts)
  """
  @spec purchase(Money.t(), CreditCard.t() | String.t(), keyword) :: map
  def purchase(amount, payment, opts) do
    params = create_params_for_auth_or_purchase(amount, payment, opts)
    commit(:post, "charges", params, opts)
  end

  @doc """
  Captures a pre-authorized amount.

  Amount is transferred to the merchant account by Stripe when it is smaller or
  equal to the amount used in the pre-authorization referenced by `charge_id`.

  ## Note
  Stripe allows partial captures and release the remaining amount back to the
  payment source. Thus, the same pre-authorisation `charge_id` cannot be used to
  perform multiple captures.

  ## Example
  The following session shows how one would (partially) capture a previously
  authorized a payment worth $10 by referencing the obtained `charge_id`.
      
      iex> id = "ch_1BYvGkBImdnrXiZwet3aKkQE"
      iex> amount = 5
      iex> opts = []

      iex> Gringotts.capture(Gringotts.Gateways.Stripe, id, amount, opts)
  """
  @spec capture(String.t(), Money.t(), keyword) :: map
  def capture(id, amount, opts) do
    params = optional_params(opts) ++ amount_params(amount)
    commit(:post, "charges/#{id}/capture", params, opts)
  end

  @doc """
  Voids the referenced payment.

  This method attempts a reversal of the either a previous `purchase/3` or
  `authorize/3` referenced by `charge_id`.
  As a consequence, the customer will never see any booking on his
  statement.

  ## Voiding a previous authorization
  Stripe will reverse the authorization by sending a "reversal request" to the
  payment source (card issuer) to clear the funds held against the
  authorization.

  ## Voiding a previous purchase
  Stripe will reverse the payment, by sending all the amount back to the
  customer. Note that this is not the same as `refund/3`.

  ## Example
  The following session shows how one would void a previous (pre)
  authorization. Remember that our `capture/3` example only did a partial
  capture.
      
      iex> id = "ch_1BYvGkBImdnrXiZwet3aKkQE"
      iex> opts = []

      iex> Gringotts.void(Gringotts.Gateways.Stripe, id, opts)
  """
  @spec void(String.t(), keyword) :: map
  def void(id, opts) do
    params = optional_params(opts)
    commit(:post, "charges/#{id}/refund", params, opts)
  end

  @doc """
  Refunds the amount to the customer's card with reference to a prior transfer.

  Stripe processes a full or partial refund worth `amount`, referencing a
  previous `purchase/3` or `capture/3`.

  ## Example
  The following session shows how one would refund a previous purchase (and
  similarily for captures).
      
      iex> amount = 5
      iex> id = "ch_1BYvGkBImdnrXiZwet3aKkQE"
      iex> opts = []

      iex> Gringotts.refund(Gringotts.Gateways.Stripe, amount, id, opts)
  """
  @spec refund(Money.t(), String.t(), keyword) :: map
  def refund(amount, id, opts) do
    params = optional_params(opts) ++ amount_params(amount)
    commit(:post, "charges/#{id}/refund", params, opts)
  end

  @doc """
  Stores the payment-source data for later use.

  Stripe can store the payment-source details, for example card which can be
  used to effectively to process One-Click and Recurring_ payments, and return a
  `customer_id` for reference.

  ## Example
  The following session shows how one would store a card (a payment-source) for
  future use.
      
      iex> card = %CreditCard{
            first_name: "John",
            last_name: "Smith",
            number: "4242424242424242",
            year: "2017",
            month: "12",
            verification_code: "123"
          }

          address = %Address{
            street1: "123 Main",
            city: "New York",
            region: "NY",
            country: "US",
            postal_code: "11111"
          }

      iex> opts = [address: address]

      iex> Gringotts.store(Gringotts.Gateways.Stripe, card, opts)
  """
  @spec store(CreditCard.t() | String.t(), keyword) :: map
  def store(payment, opts) do
    params = optional_params(opts) ++ source_params(payment, opts)
    commit(:post, "customers", params, opts)
  end

  @doc """
  Deletes previously stored payment-source data.

  Deletes the already stored payment source, so that it cannot be used again for
  capturing payments.

  ## Examples
  The following session shows how one would unstore a already stored payment
  source.

      iex> id = "cus_BwpLX2x4ecEUgD"

      iex> Gringotts.unstore(Gringotts.Gateways.Stripe, id, opts)
  """
  @spec unstore(String.t(), keyword) :: map
  def unstore(id, opts), do: commit(:delete, "customers/#{id}", [], opts)

  # Private methods

  defp create_params_for_auth_or_purchase(amount, payment, opts, capture \\ true) do
    [capture: capture] ++
      optional_params(opts) ++ amount_params(amount) ++ source_params(payment, opts)
  end

  defp create_card_token(params, opts) do
    commit(:post, "tokens", params, opts)
  end

  defp amount_params(amount) do
    {currency, int_value, _} = Money.to_integer(amount)
    [amount: int_value, currency: currency]
  end

  defp source_params(token_or_customer, _) when is_binary(token_or_customer) do
    [head, _] = String.split(token_or_customer, "_")

    case head do
      "tok" -> [source: token_or_customer]
      "cus" -> [customer: token_or_customer]
    end
  end

  defp source_params(%CreditCard{} = card, opts) do
    params = card_params(card) ++ address_params(opts[:address])

    response = create_card_token(params, opts)

    if Map.has_key?(response, "error") do
      []
    else
      response
      |> Map.get("id")
      |> source_params(opts)
    end
  end

  defp source_params(_, _), do: []

  defp card_params(%CreditCard{} = card) do
    [
      "card[name]": CreditCard.full_name(card),
      "card[number]": card.number,
      "card[exp_year]": card.year,
      "card[exp_month]": card.month,
      "card[cvc]": card.verification_code
    ]
  end

  defp card_params(_), do: []

  defp address_params(%Address{} = address) do
    [
      "card[address_line1]": address.street1,
      "card[address_line2]": address.street2,
      "card[address_city]": address.city,
      "card[address_state]": address.region,
      "card[address_zip]": address.postal_code,
      "card[address_country]": address.country
    ]
  end

  defp address_params(_), do: []

  defp commit(method, path, params, opts) do
    auth_token = "Bearer " <> opts[:config][:secret_key]

    headers = [
      {"Content-Type", "application/x-www-form-urlencoded"},
      {"Authorization", auth_token}
    ]

    response = HTTPoison.request(method, "#{@base_url}/#{path}", {:form, params}, headers)
    format_response(response)
  end

  defp optional_params(opts) do
    opts
    |> Keyword.delete(:config)
    |> Keyword.delete(:address)
  end

  defp format_response(response) do
    case response do
      {:ok, %HTTPoison.Response{body: body}} -> body |> Poison.decode!()
      _ -> %{"error" => "something went wrong, please try again later"}
    end
  end
end
