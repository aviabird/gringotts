defmodule Gringotts.Application do
  @moduledoc ~S"""
  Has the supervision tree which monitors all the workers
  that are handling the payments.
  """
  use Application

  def start(_type, _args) do
    import Supervisor.Spec, warn: false
    app_config = Application.get_all_env(:gringotts)
    adapters = Enum.filter(app_config, fn({key, klist}) -> klist != [] end)
                |> Enum.map(fn({key, klist}) -> Keyword.get(klist, :adapter) end)

    children = [
      # Define workers and child supervisors to be supervised
      # worker(Gringotts.Worker, [arg1, arg2, arg3])
      worker(
        Gringotts.Worker,
        [
          adapters,       # gateways
          app_config,     # options(config from application)
          # Since we just have one worker handling all the incoming 
          # requests so this name remains fixed
          [name: :payment_worker]
        ])
    ]

    # See http://elixir-lang.org/docs/stable/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Gringotts.Supervisor]
    Supervisor.start_link(children, opts)
  end
end