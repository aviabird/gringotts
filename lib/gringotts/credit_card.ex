defmodule Gringotts.CreditCard do
  @moduledoc """
  Defines a `struct` for (credit) cards and some utilities.
  """

  defstruct [:number, :month, :year, :first_name, :last_name, :verification_code, :brand]

  @typedoc """
  Represents a Credit Card.

  | Field               | Type       | Description                                  |
  | -----               | ----       | -----------                                  |
  | `number`            | `string`   | The card number.                             |
  | `month`             | `integer`  | Month of expiry (a number in the `1..12`\
                                       range).                                      |
  | `year`              | `integer`  | Year of expiry.                              |
  | `first_name`        | `string`   | First name of the card holder (as on card).  |
  | `last_name`         | `string`   | Last name of the card holder (as on card).   |
  | `verification_code` | `string`   | The [Card Verification Code][cvc], usually\
                                       a 3-4 digit number on the back of the card.  |
  | `brand`             | `string`   | The brand name of the card network (in\
                                       some cases also the card issuer) in\
                                       UPPERCASE. Some popular card networks\
                                       are [Visa][visa], [MasterCard][mc],\
                                       [Maestro][mo], [Diner's Club][dc] etc.       |

  [cvc]: https://en.wikipedia.org/wiki/Card_security_code
  [visa]: https://usa.visa.com
  [mc]: https://www.mastercard.us/en-us.html
  [mo]: http://www.maestrocard.com/gateway/index.html
  [dc]: http://www.dinersclub.com/
  """
  @type t :: %__MODULE__{
          number: String.t(),
          month: 1..12,
          year: non_neg_integer,
          first_name: String.t(),
          last_name: String.t(),
          verification_code: String.t(),
          brand: String.t()
        }

  @doc """
  Returns the full name of the card holder.

  Joins `first_name` and `last_name` with a space in between.
  """
  @spec full_name(t) :: String.t()
  def full_name(card) do
    name = "#{card.first_name} #{card.last_name}"
    String.trim(name)
  end
end
