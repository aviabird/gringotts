defmodule Gringotts.Adapter do
  @moduledoc ~S"""
  Adapter module is currently holding the validation part.

  This modules is being `used` by all the payment gateways and raises a run-time 
  error for the missing configurations which are passed by the gateways to 
  `validate_config` method.

  Raises an exception `ArgumentError` if the config is not as per the `@required_config`
  """

  defmacro __using__(opts) do
    quote bind_quoted: [opts: opts] do
      @required_config opts[:required_config] || []

      @doc """
      Validates the config dynamically depending on what is the value of `required_config`
      """
      def validate_config(config) do
        missing_keys = Enum.reduce(@required_config, [], fn(key, missing_keys) ->
          if config[key] in [nil, ""], do: [key | missing_keys], else: missing_keys
        end)
        raise_on_missing_config(missing_keys, config)
      end

      defp raise_on_missing_config([], _config), do: :ok
      defp raise_on_missing_config(key, config) do
        raise ArgumentError, """
        expected #{inspect key} to be set, got: #{inspect config}
        """
      end
    end
  end
end