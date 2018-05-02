defmodule Gringotts.Gateways.Checkout do
  @moduledoc """
  [checkout][home] gateway implementation.

  A module for working with the checkout payment gateway.

  Refer the official Checkout [API docs][docs].

  The following set of functions for Checkout have been implemented:

  | Action                                       | Method        |
  | ------                                       | ------        |
  | Authorize a Credit Card                      | `authorize/3` |
  | Capture a previously authorized amount       | `capture/3`   |
  | Charge a Credit Card                         | `purchase/3`  |
  | Refund a transaction                         | `refund/3`    |
  | Void a transaction                           | `void/2`      |

  ## Optional or extra parameters

  Most `Gringotts` API calls accept an optional `Keyword` list `opts` to supply
  optional arguments for transactions with the gateway.
  To know more about these keywords visit [Request and Response][req-resp] tabs for each
  API method.

  [req-resp]: https://beta.docs.checkout.com/docs/payments-quickstart

   ## Registering your checkout account at `Gringotts`

  > Here's how the secrets map to the required configuration parameters for checkout:
  > 
  > | Config parameter | checkout secret   |
  > | --------------   | -----------       |
  > | `:secret_key`    | **SecretKey**     |

  > Your Application config **must include the `[:secret_key]` field(s)** and would look
  > something like this:
  > 
  >     config :gringotts, Gringotts.Gateways.Checkout,
  >         secret_key: "your_secret_secret_key"

  ## Supported currencies and countries

  > * Europe
  > * North America

  ## Following the examples

  1. First, set up a sample application and configure it to work with checkout.
  - You could do that from scratch by following our [Getting Started][gs] guide.
      - To save you time, we recommend [cloning our example
      repo][example] that gives you a pre-configured sample app ready-to-go.
          + You could use the same config or update it the with your "secrets"
          as described [above](#module-registering-your-monei-account-at-checkout).

  2. Run an `iex` session with `iex -S mix` and add some variable bindings and
  aliases to it (to save some time):
  We'll be using these in the examples below.
  ```
  iex> alias Gringotts.{Response, CreditCard, Gateways.Checkout}
  iex> card = %CreditCard{first_name: "Jo",
                          last_name: "Doe",
                          number: "4200000000000000",
                          year: 2099, month: 12,
                          verification_code: "123", brand: "VISA"}
  ```

  We'll be using these in the examples below.

  [docs]: https://beta.docs.checkout.com/docs
  [gs]: https://github.com/aviabird/gringotts/wiki/
  [home]: https://www.checkout.com
  [example]: https://github.com/aviabird/gringotts_example
  """

  # The Base module has the (abstract) public API, and some utility
  # implementations.
  use Gringotts.Gateways.Base

  # The Adapter module provides the `validate_config/1`
  # Add the keys that must be present in the Application config in the
  # `required_config` list
  use Gringotts.Adapter, required_config: [:secret_key]

  import Poison, only: [decode: 1]

  alias Gringotts.{Money, CreditCard, Response}

  @test_url "https://sandbox.checkout.com/api2/v2/"
  @doc """
  Performs a (pre) Authorize operation.
  The authorization validates the `card` details with the banking network,
  places a hold on the transaction `amount` in the customer’s issuing bank.
  Checkout returns an ID string which can be used to:
  * `capture/3` _an_ amount.
  * `void/2` an amount
  ## Example
  ```
  iex> amount = Money.new(42, :USD)
  iex> {:ok, auth_result} = Gringotts.authorize(Gringotts.Gateways.Checkout, amount, card, opts)
  iex> auth_result.id # This is the charge ID
  ```
  """
  @spec authorize(Money.t(), CreditCard.t(), keyword) :: {:ok | :error, Response}
  def authorize(amount, card = %CreditCard{}, opts) do
    {currency, value, _} = Money.to_integer(amount)

    body =
      Poison.encode!(%{
        email: opts[:email],
        currency: currency,
        value: value,
        autoCapture: "n",
        autoCapTime: opts[:autoCapTime],
        shippingDetails: %{
          addressLine1: opts[:address].street1,
          addressLine2: opts[:address].street2,
          city: opts[:address].city,
          state: opts[:address].region,
          country: opts[:address].country,
          postcode: opts[:address].postal_code,
          phone: %{
            countryCode: opts[:countryCode],
            number: opts[:number]
          }
        },
        chargeMode: opts[:chargeMode],
        customerIp: opts[:customerIp],
        customerName: opts[:customerName],
        description: opts[:description],
        descriptor: opts[:descriptor],
        trackId: opts[:trackId],
        card: %{
          number: card.number,
          name: CreditCard.full_name(card),
          cvv: card.verification_code,
          expiryMonth: card.month,
          expiryYear: card.year,
          billingDetails: %{
            addressLine1: opts[:address].street1,
            addressLine2: opts[:address].street2,
            city: opts[:address].city,
            state: opts[:address].region,
            country: opts[:address].country,
            postcode: opts[:address].postal_code,
            phone: %{
              countryCode: opts[:countryCode],
              number: opts[:number]
            }
          }
        }
      })

    commit(:post, "charges/card", body, opts)
  end

  @doc """
  Captures a pre-authorized `amount`.
  `amount` is transferred to the merchant account by Checkout used in the
  pre-authorization referenced by `charge_id`.
  ## Note
  > Checkout **do** support partial captures, but only once per authorized payment.
  ## Example
  ```
  iex> {:ok, capture_result} = Gringotts.capture(Gringotts.Gateways.Checkout, amount, auth_result.id, opts)
  ```
  """
  @spec capture(String.t(), Money.t(), keyword) :: {:ok | :error, Response}
  def capture(payment_id, amount, opts) do
    {currency, value, _} = Money.to_integer(amount)

    body =
      Poison.encode!(%{
        description: opts[:description],
        trackId: opts[:trackId],
        value: value
      })

    commit(:post, "charges/#{payment_id}/capture", body, opts)
  end

  @doc """
  Transfers `amount` from the customer to the merchant.
  Checkout attempts to process a purchase on behalf of the customer, by
  debiting `amount` from the customer's account by charging the customer's
  `card`.
  ## Example
  ```
  iex> amount = Money.new(42, :USD)
  iex> {:ok, purchase_result} = Gringotts.purchase(Gringotts.Gateways.Checkout, amount, card, opts)
  iex> purchase_result.id # This is the charge ID
  """
  @spec purchase(Money.t(), CreditCard.t(), keyword) :: {:ok | :error, Response}
  def purchase(amount, card = %CreditCard{}, opts) do
    {currency, value, _} = Money.to_integer(amount)

    body =
      Poison.encode!(%{
        email: opts[:email],
        currency: currency,
        value: value,
        autoCapTime: opts[:autoCapTime],
        shippingDetails: %{
          addressLine1: opts[:address].street1,
          addressLine2: opts[:address].street2,
          city: opts[:address].city,
          state: opts[:address].region,
          country: opts[:address].country,
          postcode: opts[:address].postal_code,
          phone: %{
            countryCode: opts[:countryCode],
            number: opts[:number]
          }
        },
        chargeMode: opts[:chargeMode],
        customerIp: opts[:customerIp],
        customerName: opts[:customerName],
        description: opts[:description],
        descriptor: opts[:descriptor],
        trackId: opts[:trackId],
        card: %{
          number: card.number,
          name: CreditCard.full_name(card),
          cvv: card.verification_code,
          expiryMonth: card.month,
          expiryYear: card.year,
          billingDetails: %{
            addressLine1: opts[:address].street1,
            addressLine2: opts[:address].street2,
            city: opts[:address].city,
            state: opts[:address].region,
            country: opts[:address].country,
            postcode: opts[:address].postal_code,
            phone: %{
              countryCode: opts[:countryCode],
              number: opts[:number]
            }
          }
        }
      })

    commit(:post, "charges/card", body, opts)
  end

  @doc """
  Voids the referenced payment.
  This method attempts a reversal of a previous transaction referenced by
  `charge_id`.

  ## Note
  > As a consequence, the customer will never see any booking on his statement.
  > Checkout must be in authorized state and **not** in  captured state.
  ## Example
  ```
  iex> {:ok, void_result} = Gringotts.capture(Gringotts.Gateways.Checkout, purchase_result.id, opts)
  ```
  """
  @spec void(String.t(), keyword) :: {:ok | :error, Response}
  def void(payment_id, opts) do
    body =
      Poison.encode!(%{
        description: opts[:description],
        trackId: opts[:trackId]
      })

    commit(:post, "charges/#{payment_id}/void", body, opts)
  end

  @doc """
  Refunds the `amount` to the customer's account with reference to a prior transfer.
  > Refunds are allowed on Captured / purchased transraction.
  ## Note
  * Checkout does support partial refunds, but only once per captured payment.
  ## Example
  ```
  iex> {:ok, refund_result} = Gringotts.refund(Gringotts.Gateways.Checkout, purchase_result.id, amount)
  ```
  """
  @spec refund(Money.t(), String.t(), keyword) :: {:ok | :error, Response}
  def refund(amount, payment_id, opts) do
    {currency, value, _} = Money.to_integer(amount)

    body =
      Poison.encode!(%{
        description: opts[:description],
        trackId: opts[:trackId],
        value: value
      })

    commit(:post, "charges/#{payment_id}/refund", body, opts)
  end

  ###############################################################################
  #                                PRIVATE METHODS                              #
  ###############################################################################

  # Makes the request to checkout's network.
  # For consistency with other gateway implementations, make your (final)
  # network request in here, and parse it using another private method called
  # `respond`.
  @spec commit(atom, String.t(), String.t(), keyword) :: {:ok | :error, Response}
  defp commit(:post, endpoint, body, opts) do
    url = @test_url <> "#{endpoint}"

    headers = [
      {"Content-Type", "application/json;charset=UTF-8"},
      {"Authorization", opts[:config][:secret_key]}
    ]

    HTTPoison.request(:post, url, body, headers)
    |> respond
  end

  # Parses checkout's response and returns a `Gringotts.Response` struct
  # in a `:ok`, `:error` tuple.
  @spec respond(term) :: {:ok | :error, Response}
  defp respond({:ok, %{status_code: code, body: body}}) when code in 200..299 do
    {:ok, parsed} = decode(body)

    id = parsed["id"]
    message = parsed["status"]

    {
      :ok,
      Response.success(id: id, message: message, raw: parsed, status_code: code)
    }
  end

  defp respond({:ok, %{status_code: status_code, body: body}}) do
    {:ok, parsed} = decode(body)
    detail = parsed["error_description"]

    {
      :error,
      Response.error(status_code: status_code, message: detail, raw: body)
    }
  end

  defp respond({:error, %HTTPoison.Error{} = error}) do
    {:error, Response.error(code: error.id, message: "HTTPoison says '#{error.reason}")}
  end
end
