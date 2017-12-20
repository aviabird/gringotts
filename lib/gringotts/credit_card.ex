defmodule Gringotts.CreditCard do
  @moduledoc ~S"""
  CreditCard module defines the struct for the credit cards. 

  It mostly has such as:-
    * `number`: Credit card number
    * `month`: Expiry month
    * `year`: Expiration year
    * `first_name`: First name of the card holder
    * `last_name`: Last of the card holder
    * `verification_code`: 3/4 digit code at the back of the card
    * `brand`: VISA/MASTERCARD/MAESTRO/RUPAY etc.
  """

  defstruct [:number, :month, :year, :first_name, :last_name, :verification_code, :brand]
end
