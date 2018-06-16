defmodule Gringotts.Gateways.WePay do
  @moduledoc """
  [wepay][home] gateway implementation.

  A module for working with the WePay payment gateway.

  Refer the official WePay [API docs][docs].

  The following set of functions for WePay have been implemented:

  | Action                                       | Method        |
  | ------                                       | ------        |
  | Authorize a Credit Card                      | `authorize/3` |
  | Capture a previously authorized amount       | `capture/3`   |
  | Charge a Credit Card                         | `purchase/3`  |
  | Refund a transaction                         | `refund/3`    |
  | Void a transaction                           | `void/2`      |
  | Create Customer Profile                      | `store/2`     |
  | Delete Customer Profile                      | `unstore/2`   |

  ## Optional or extra parameters

  Most `Gringotts` API calls accept an optional `Keyword` list `opts` to supply
  optional arguments for transactions with the gateway.

  To know more about these keywords visit [Request and Response][req-resp] tabs for each
  API method.

  [docs]: hhttps://developer.wepay.com/
  [req-resp]: https://developer.wepay.com/api/reference/structures

  ## Supported currencies and countries

  WePay supports the countries listed [here][all-country-list]

  [all-country-list]: [https://support.wepay.com/hc/en-us/articles/203611643-Is-WePay-International-]

  ## Following the examples

  1. First, set up a sample application and configure it to work with WePay.
  - You could do that from scratch by following our [Getting Started][gs] guide.
      - To save you time, we recommend [cloning our example
      repo][example] that gives you a pre-configured sample app ready-to-go.
          + You could use the same config or update it the with your "secrets"
          as described [above](#module-registering-your-monei-account-at-wepay).

  2. Run an `iex` session with `iex -S mix` and add some variable bindings and
  aliases to it (to save some time):
  ```
  iex> alias Gringotts.{Response, CreditCard, Gateways.WePay}
  iex> card = %CreditCard{first_name: "Jo",
                          last_name: "Doe",
                          number: "4200000000000000",
                          year: 2099, month: 12,
                          verification_code: "123", brand: "VISA"}
  ```
  We'll be using these in the examples below.

  [gs]: https://github.com/aviabird/gringotts/wiki/
  [home]: https://go.wepay.com
  [example]: https://github.com/aviabird/gringotts_example

  """

  # The Base module has the (abstract) public API, and some utility
  # implementations.
  use Gringotts.Gateways.Base

  # The Adapter module provides the `validate_config/1`
  # Add the keys that must be present in the Application config in the
  # `required_config` list
  use Gringotts.Adapter, required_config: [:access_token]

  import Poison, only: [decode: 1]

  alias Gringotts.{CreditCard, Money, Response}

  @test_url "https://stage.wepayapi.com/v2"

  @doc """
  Performs a (pre) Authorize operation.

  The authorization validates the `card` details with the banking network,
  places a hold on the transaction `amount` in the customer’s issuing bank.

  WePay returns an ID string which can be used to:

  * `capture/3` _an_ amount.

  ## Example
  ```
  iex> amount = Money.new(42, :USD)
  iex> {:ok, auth_result} = Gringotts.authorize(Gringotts.Gateways.WePay, amount, card, opts)
  iex> auth_result.id # This is the authorization ID
  ```
  """

  @spec authorize(Money.t(), CreditCard.t(), keyword) :: {:ok | :error, Response}
  def authorize(amount, card = %CreditCard{}, opts) do
    {currency, value, _} = Money.to_integer(amount)

    with {:ok, card_token_response} <- store(card, opts),
         {:ok, card_token} <- extract_card_token(card_token_response) do
      body =
        build(value, currency, opts)
        |> Map.merge(%{
          payment_method: %{
            type: "credit_card",
            credit_card: %{
              id: card_token,
              auto_capture: false
            }
          }
        })
        |> Poison.encode!()

      commit(:post, "/checkout/create/", body, opts)
    end
  end

  # authorize with card token.
  def authorize(amount, card_token, opts) do
    {currency, value, _} = Money.to_integer(amount)

    body =
      build(value, currency, opts)
      |> Map.merge(%{
        payment_method: %{
          type: "credit_card",
          credit_card: %{
            id: card_token,
            auto_capture: false
          }
        }
      })
      |> Poison.encode!()

    commit(:post, "/checkout/create/", body, opts)
  end

  @doc """
  Captures a pre-authorized `amount`.

  `amount` is transferred to the merchant account by wepay used in the
  pre-authorization referenced by `payment_id`.

  ## Note

  > WePay **do not** support partial captures. 

  ## Example
  ```
  iex> {:ok, capture_result} = Gringotts.capture(Gringotts.Gateways.WePay, amount, auth_result.id, opts)
  ```
  """
  @spec capture(String.t(), Money.t(), keyword) :: {:ok | :error, Response}
  def capture(payment_id, amount, opts) do
    body =
      Poison.encode!(%{
        checkout_id: payment_id
      })

    commit(:post, "/checkout/capture/", body, opts)
  end

  @doc """
  Transfers `amount` from the customer to the merchant.

  wepay attempts to process a purchase on behalf of the customer, by
  debiting `amount` from the customer's account by charging the customer's
  `card`.

  ## Example
  ```
  iex> amount = Money.new(42, :USD)
  iex> {:ok, purchase_result} = Gringotts.purchase(Gringotts.Gateways.WePay, amount, card, opts)
  iex> purchase_result.id # This is the checkout ID
  ```
  """
  @spec purchase(Money.t(), CreditCard.t(), keyword) :: {:ok | :error, Response}
  def purchase(amount, card = %CreditCard{}, opts) do
    {currency, value, _} = Money.to_integer(amount)

    with {:ok, card_token_response} <- store(card, opts),
         {:ok, card_token} <- extract_card_token(card_token_response) do
      body =
        build(value, currency, opts)
        |> Map.merge(%{
          payment_method: %{
            type: "credit_card",
            credit_card: %{
              id: card_token
            }
          }
        })
        |> Poison.encode!()

      commit(:post, "/checkout/create/", body, opts)
    end
  end

  # purchase with card token.
  def purchase(amount, card_token, opts) do
    {currency, value, _} = Money.to_integer(amount)

    body =
      build(value, currency, opts)
      |> Map.merge(%{
        payment_method: %{
          type: "credit_card",
          credit_card: %{
            id: card_token
          }
        }
      })
      |> Poison.encode!()

    commit(:post, "/checkout/create/", body, opts)
  end

  @doc """
  Voids the referenced payment.

  This method attempts a reversal of a previous transaction referenced by
  `payment_id`.

  > As a consequence, the customer will never see any booking on his statement.

  ## Note
  > As a consequence, the customer will never see any booking on his statement.
  > Checkout must be in purchased or captured state.

  ## Example
  ```
  iex> {:ok, void_result} = Gringotts.capture(Gringotts.Gateways.WePay, purchase_result.id, opts)
  ```
  """
  @spec void(String.t(), keyword) :: {:ok | :error, Response}
  def void(payment_id, opts) do
    body =
      Poison.encode!(%{
        checkout_id: payment_id,
        cancel_reason: opts[:cancel_reason]
      })

    commit(:post, "/checkout/cancel/", body, opts)
  end

  @doc """
  Refunds the `amount` to the customer's account with reference to a prior transfer.

  > Refunds are allowed on Captured / purchased transraction.

  ## Note

  * It is recommended to refund the transraction after 5 to 10 min.
  * WePay does not support partial refunds.

  ## Example
  ```
  iex> {:ok, refund_result} = Gringotts.refund(Gringotts.Gateways.WePay, purchase_result.id, amount)
  ```
  """
  @spec refund(Money.t(), String.t(), keyword) :: {:ok | :error, Response}
  def refund(amount, payment_id, opts) do
    {currency, value, _} = Money.to_integer(amount)

    body =
      Poison.encode!(%{
        checkout_id: payment_id,
        amount: value,
        refund_reason: opts[:refund_reason]
      })

    commit(:post, "/checkout/refund/", body, opts)
  end

  @doc """
  Stores the payment-source data for later use.

  ## Example
  ```
  iex> {:ok, store_result} = Gringotts.store(Gringotts.Gateways.WePay, card, opts)
  iex> store_result.token #card token
  ```
  """
  @spec store(CreditCard.t(), keyword) :: {:ok | :error, Response}
  def store(%CreditCard{} = card, opts) do
    body =
      Poison.encode!(%{
        client_id: opts[:config][:client_id],
        cc_number: card.number,
        user_name: CreditCard.full_name(card),
        email: opts[:email],
        cvv: card.verification_code,
        expiration_month: card.month,
        expiration_year: card.year,
        original_ip: opts[:original_ip],
        original_device: opts[:original_device],
        reference_id: opts[:reference_id],
        address: %{
          address1: opts[:address].street1,
          address2: opts[:address].street2,
          city: opts[:address].city,
          region: opts[:address].region,
          country: opts[:address].country,
          postal_code: opts[:address].postal_code
        }
      })

    commit(:post, "/credit_card/create/", body, opts)
  end

  @doc """
  Removes card or payment info that was previously `store/2`d

  Deletes previously stored payment-source data.

  ## Example
  ```
  iex> {:ok, store_result} = Gringotts.unstore(Gringotts.Gateways.WePay, store_result.token, opts)
  ```
  """
  @spec unstore(String.t(), keyword) :: {:ok | :error, Response}
  def unstore(registration_id, opts) do
    body =
      Poison.encode!(%{
        client_id: opts[:config][:client_id],
        client_secret: opts[:config][:client_secret],
        credit_card_id: registration_id
      })

    commit(:post, "/credit_card/delete/", body, opts)
  end

  ###############################################################################
  #                                PRIVATE METHODS                              #
  ###############################################################################

  # Makes the request to wepay's network.
  # For consistency with other gateway implementations, make your (final)
  # network request in here, and parse it using another private method called
  # `respond`.
  @spec commit(atom, String.t(), String.t(), keyword) :: {:ok | :error, Response}
  defp commit(:post, endpoint, body, opts) do
    url = @test_url <> "#{endpoint}"

    headers = [
      {"Content-Type", "application/json"},
      {"Authorization", "Bearer " <> opts[:config][:access_token]}
    ]

    HTTPoison.request(:post, url, body, headers)
    |> respond
  end

  defp extract_card_token(%{token: token}) do
    {:ok, token}
  end

  defp build(value, currency, opts) do
    %{
      account_id: opts[:config][:account_id],
      short_description: opts[:short_description],
      type: opts[:type],
      amount: value,
      currency: currency,
      long_description: opts[:long_description],
      callback_uri: opts[:callback_uri],
      auto_release: true,
      unique_id: opts[:unique_id],
      reference_id: opts[:reference_id],
      delivery_type: opts[:delivery_type]
    }
  end

  # Parses wepay's response and returns a `Gringotts.Response` struct
  # in a `:ok`, `:error` tuple.
  @spec respond(term) :: {:ok | :error, Response}
  defp respond({:ok, %{status_code: code, body: body}}) when code in 200..299 do
    {:ok, parsed} = decode(body)
    token = parsed["credit_card_id"]
    id = parsed["checkout_id"]
    message = parsed["state"]

    {
      :ok,
      %Response{id: id, message: message, token: token, raw: parsed, status_code: code}
    }
  end

  defp respond({:ok, %{status_code: status_code, body: body}}) do
    {:ok, parsed} = decode(body)
    detail = parsed["error_description"]

    {
      :error,
      %Response{status_code: status_code, message: detail, raw: body}
    }
  end

  defp respond({:error, %HTTPoison.Error{} = error}) do
    {:error, %Response{status_code: 400, message: "HTTPoison says '#{error.reason}"}}
  end
end
