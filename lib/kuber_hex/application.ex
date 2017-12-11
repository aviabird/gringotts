defmodule Kuber.Hex.Application do
  @moduledoc ~S"""
  Has the supervision tree which monitors all the workers
  that are handling the payments.
  """

  use Application


  def start(_type, _args) do
    import Supervisor.Spec, warn: false

    children = [
      # Define workers and child supervisors to be supervised
      # worker(Kuber.Hex.Worker, [arg1, arg2, arg3])
      worker(
        Kuber.Hex.Worker,
        [
          Application.get_env(:kuber_hex, Kuber.Hex)[:adapter], # gateway
          Application.get_env(:kuber_hex, Kuber.Hex),           # options(config from application)
          # Experimental
          # TODO: This is exposed from the config and is later used to call methods of the lib.
          [name: Application.get_env(:kuber_hex, Kuber.Hex)[:worker_process_name]]
        ])
    ]

    # See http://elixir-lang.org/docs/stable/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Kuber.Hex.Supervisor]
    Supervisor.start_link(children, opts)
  end

end