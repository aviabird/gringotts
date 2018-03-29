defmodule Gringotts.Gateways.Bogus do
  @moduledoc false

  use Gringotts.Gateways.Base

  alias Gringotts.{
    CreditCard,
    Response
  }

  @some_authorization_id "14a62fff80f24a25f775eeb33624bbb3"

  def authorize(_amount, _card_or_id, _opts), do: success()

  def purchase(_amount, _card_or_id, _opts), do: success()

  def capture(_id, _amount, _opts), do: success()

  def void(_id, _opts), do: success()

  def refund(_amount, _id, _opts), do: success()

  def store(%CreditCard{} = _card, _opts), do: success()

  def unstore(_customer_id, _opts), do: success()

  defp success, do: {:ok, Response.success(id: @some_authorization_id)}
end
