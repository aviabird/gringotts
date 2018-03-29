defmodule Gringotts.Response do
  @moduledoc """
  Defines the Response `struct` and some utilities.

  All `Gringotts` public API calls will return a `Response.t` wrapped in an
  `:ok` or `:error` `tuple`. It is guaranteed that an `:ok` will be returned
  only when the request succeeds at the gateway, ie, no error occurs.
  """

  defstruct [
    :success,
    :id,
    :token,
    :status_code,
    :gateway_code,
    :reason,
    :message,
    :avs_result,
    :cvc_result,
    :raw,
    :fraud_review
  ]

  @typedoc """
  The standard Response from `Gringotts`.

  | Field          | Type              | Description                           |
  |----------------|-------------------|---------------------------------------|
  | `success`      | `boolean`         | Indicates the status of the\
                                         transaction.                          |
  | `id`           | `String.t`        | Gateway supplied identifier of the\
                                         transaction.                          |
  | `token`        | `String.t`        | Gateway supplied `token`. _This is\
                                         different from `Response.id`_.        |
  | `status_code`  | `non_neg_integer` | `HTTP` response code.                 |
  | `gateway_code` | `String.t`        | Gateway's response code "as-is".      |
  | `message`      | `String.t`        | String describing the response status.|
  | `avs_result`   | `map`             | Address Verification Result.\
                                         Schema: `%{street: String.t,\
                                         zip_code: String.t}`                  |
  | `cvc_result`   | `String.t`        | Result of the [CVC][cvc] validation.  |
  | `reason`       | `String.t`        | Explain the `reason` of error, in\
                                         case of error. `nil` otherwise.       |
  | `raw`          | `String.t`        | Raw response from the gateway.        |
  | `fraud_review` | `term`            | Gateway's risk assessment of the\
                                         transaction.                          |

  ## Notes

  1. It is not guaranteed that all fields will be populated for all calls, and
     some gateways might insert non-standard fields. Please refer the Gateways'
     docs for that information.

  2. `success` is deprecated in `v1.1.0` and will be removed in `v1.2.0`.

  3. For some actions the Gateway returns an additional token, say as reponse to
     a customer tokenization/registration. In such cases the `id` is not
     useable because it refers to the transaction, the `token` is.

  > On the other hand for authorizations or captures, there's no `token`.

  4. The schema of `fraud_review` is Gateway specific.

  [cvc]: https://en.wikipedia.org/wiki/Card_security_code
  """
  @type t :: %__MODULE__{
          success: boolean,
          id: String.t(),
          token: String.t(),
          status_code: non_neg_integer,
          gateway_code: String.t(),
          reason: String.t(),
          message: String.t(),
          avs_result: %{street: String.t(), zip_code: String.t()},
          cvc_result: String.t(),
          raw: String.t(),
          fraud_review: term
        }

  def success(opts \\ []) do
    new(true, opts)
  end

  def error(opts \\ []) do
    new(false, opts)
  end

  defp new(success, opts) do
    Map.merge(%__MODULE__{success: success}, Enum.into(opts, %{}))
  end
end
