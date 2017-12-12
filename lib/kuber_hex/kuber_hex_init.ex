defmodule Kuber.Hex.Init do
  @doc """
  Module sets otp app name and configs
  """

  defmacro __using__(opts) do
    quote bind_quoted: [opts: opts] do
      @otp_app Keyword.fetch!(opts, :otp_app)
      @adapter_config opts
    end
  end
end