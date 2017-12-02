defmodule Kuber.Hex do
  use Application

  import GenServer, only: [call: 2]

  # See http://elixir-lang.org/docs/stable/elixir/Application.html
  # for more information on OTP Applications
  def start(_type, _args) do
    import Supervisor.Spec, warn: false

    children = [
      # Define workers and child supervisors to be supervised
      # worker(Kuber.Hex.Worker, [arg1, arg2, arg3])
    ]

    # See http://elixir-lang.org/docs/stable/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Kuber.Hex.Supervisor]
    Supervisor.start_link(children, opts)
  end

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
