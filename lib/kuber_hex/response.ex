defmodule Kuber.Hex.Response do
  defstruct [:success, :authorization, :code, :reason, :avs_result, :cvc_result, :raw]

  def success(opts \\ []) do
    new(true, opts)
  end

  def error(opts \\ []) do
    new(false, opts)
  end

  defp new(success, opts) do
    Map.merge(%__MODULE__{success: success}, Enum.into(opts, %{}))
  end
end
