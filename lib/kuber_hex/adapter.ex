defmodule Kuber.Hex.Adapter do
  defmacro __using__(opts) do
    quote bind_quoted: [opts: opts] do
      @required_config opts[:required_config] || []

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