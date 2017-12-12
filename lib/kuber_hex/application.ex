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
          # Current issue with this is named processes cannot be created for multiple 
          # requests for example if we want to process multiple requests simultaneously
          # then named processes is not the way to go.
          # ref: https://www.amberbit.com/blog/2016/5/13/process-name-registration-in-elixir/
          # ref: https://github.com/uwiger/gproc
          # ref: https://m.alphasights.com/process-registry-in-elixir-a-practical-example-4500ee7c0dcc
          # ref: https://medium.com/elixirlabs/registry-in-elixir-1-4-0-d6750fb5aeb
          # ref: http://codeloveandboards.com/blog/2016/03/20/supervising-multiple-genserver-processes/
          
          [name: Application.get_env(:kuber_hex, Kuber.Hex)[:worker_process_name]]

        ])
    ]

    # See http://elixir-lang.org/docs/stable/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Kuber.Hex.Supervisor]
    Supervisor.start_link(children, opts)
  end

end