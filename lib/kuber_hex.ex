defmodule Kuber.Hex do
  import GenServer, only: [call: 2]

  @doc """
  Public API authorize method

  Makes an asynchronous authorize call to the Genserver
  """
  def authorize(worker, amount, card, opts \\ []),
    do: call(worker, {:authorize, amount, card, opts})

  def purchase(worker, amount, card, opts \\ []),
    do: call(worker, {:purchase, amount, card, opts})

  def capture(worker, id, opts \\ []),
    do: call(worker, {:capture, id, opts})

  def void(worker, id, opts \\ []),
    do: call(worker, {:void, id, opts})

  def refund(worker, amount, id, opts \\ []),
    do: call(worker, {:refund, amount, id, opts})

  def store(worker, card, opts \\ []),
    do: call(worker, {:store, card, opts})

  def unstore(worker, customer_id, card_id, opts \\ []),
    do: call(worker, {:unstore, customer_id, card_id, opts})
end
