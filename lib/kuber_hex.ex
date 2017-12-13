defmodule Kuber.Hex do
  import GenServer, only: [call: 2]

  @doc """
  Public API authorize method

  Makes an asynchronous authorize call to the Genserver
  """
  def authorize(worker, gateway, amount, card, opts \\ []) do
    validate_config(gateway)
    call(worker, {:authorize, gateway, amount, card, opts})
  end

  def purchase(worker, gateway, amount, card, opts \\ []) do
    validate_config(gateway)
    call(worker, {:purchase, gateway, amount, card, opts})
  end

  def capture(worker, gateway, id, amount, opts \\ []) do 
    validate_config(gateway)
    call(worker, {:capture, gateway, id, amount, opts})
  end

  def void(worker, gateway, id, opts \\ []) do 
    validate_config(gateway)
    call(worker, {:void, gateway, id, opts})
  end

  def refund(worker, gateway, amount, id, opts \\ []) do 
    validate_config(gateway)
    call(worker, {:refund, gateway, amount, id, opts})
  end

  def store(worker, gateway, card, opts \\ []) do 
    validate_config(gateway)
    call(worker, {:store, gateway, card, opts})
  end

  def unstore(worker, gateway, customer_id, card_id, opts \\ []) do 
    validate_config(gateway)
    call(worker, {:unstore, gateway, customer_id, card_id, opts})
  end

  # TODO: This is runtime error reporing fix this to be compile
  # time error reporting.
  defp validate_config(gateway) do
    # Keep the key name and adapter the same in the config in application
    config = Application.get_env(:kuber_hex, gateway)
    gateway.validate_config(config)
  end
end
