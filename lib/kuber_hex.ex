defmodule Kuber.Hex do
  import GenServer, only: [call: 2]

  @doc """
  Public API authorize method

  Makes an asynchronous authorize call to the Genserver
  """
  def authorize(worker, amount, card, opts \\ []) do
    validate_config()
    call(worker, {:authorize, amount, card, opts})
  end

  def purchase(worker, amount, card, opts \\ []) do
    validate_config()
    call(worker, {:purchase, amount, card, opts})
  end

  def capture(worker, id, amount, opts \\ []) do 
    validate_config()
    call(worker, {:capture, id, amount, opts})
  end

  def void(worker, id, opts \\ []) do 
    validate_config()
    call(worker, {:void, id, opts})
  end

  def refund(worker, amount, id, opts \\ []) do 
    validate_config()
    call(worker, {:refund, amount, id, opts})
  end

  def store(worker, card, opts \\ []) do 
    validate_config()
    call(worker, {:store, card, opts})
  end

  def unstore(worker, customer_id, card_id, opts \\ []) do 
    validate_config()
    call(worker, {:unstore, customer_id, card_id, opts})
  end

  # TODO: This is runtime error reporing fix this to be compile
  # time error reporting.
  defp validate_config do
    config = Application.get_env(:kuber_hex, Kuber.Hex)
    gateway = config[:adapter]
    gateway.validate_config(config)
  end
end
