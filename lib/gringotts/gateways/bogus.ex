defmodule Gringotts.Gateways.Bogus do
  use Gringotts.Gateways.Base

  alias Gringotts.{
    CreditCard,
    Response
  }

  def authorize(_amount, _card_or_id, _opts),
    do: success()

  def purchase(_amount, _card_or_id, _opts),
    do: success()

  def capture(id, amount, _opts),
    do: success(id)

  def void(id, _opts),
    do: success(id)

  def refund(_amount, id, _opts),
    do: success(id)

  def store(_card=%CreditCard{}, _opts),
    do: success()

  def unstore(customer_id, _opts),
    do: success(customer_id)

  defp success,
    do: {:ok, Response.success(authorization: random_string())}

  defp success(id),
    do: {:ok, Response.success(authorization: id)}

  defp random_string(length \\ 10),
    do: 1..length |> Enum.map(&random_char/1) |> Enum.join

  defp random_char(_),
    do: to_string(:rand.uniform(9))
end
