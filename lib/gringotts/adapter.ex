defmodule Gringotts.Adapter do
  @moduledoc """
  Validates the "required" configuration.

  All gateway modules must `use` this module, which provides a run-time
  configuration validator.

  Gringotts picks up the merchant's Gateway authentication secrets from the
  Application config. The configuration validator can be customized by providing
  a list of `required_config` keys. The validator will check if these keys are
  available at run-time, before each call to the Gateway.

  ## Example

  Say a merchant must provide his `secret_user_name` and `secret_password` to
  some Gateway `XYZ`. Then, `Gringotts` expects that the `GatewayXYZ` module
  would use `Adapter` in the following manner:

  ```
  defmodule Gringotts.Gateways.GatewayXYZ do
    
    use Gringotts.Adapter, required_config: [:secret_user_name, :secret_password]
    use Gringotts.Gateways.Base
    
    # the rest of the implentation
  end
  ```

  And, the merchant woud provide these secrets in the Application config,
  possibly via `config/config.exs` like so,
  ```
  # config/config.exs

  config :gringotts, Gringotts.Gateways.GatewayXYZ,
    adapter: Gringotts.Gateways.GatewayXYZ,
    secret_user_name: "some_really_secret_user_name",
    secret_password: "some_really_secret_password"

  ```
  """

  defmacro __using__(opts) do
    quote bind_quoted: [opts: opts] do
      @required_config opts[:required_config] || []

      @doc """
      Catches gateway configuration errors.

      Raises a run-time `ArgumentError` if any of the `required_config` values
      is not available or missing from the Application config.
      """
      def validate_config(config) when is_list(config) do
        missing_keys =
          Enum.reduce(@required_config, [], fn key, missing_keys ->
            if config[key] in [nil, ""], do: [key | missing_keys], else: missing_keys
          end)

        raise_on_missing_config(missing_keys, config)
      end

      def validate_config(config) when is_map(config) do
        config
        |> Enum.into([])
        |> validate_config
      end

      defp raise_on_missing_config([], _config), do: :ok

      defp raise_on_missing_config(key, config) do
        raise ArgumentError, """
        expected #{inspect(key)} to be set, got: #{inspect(config)}
        """
      end
    end
  end
end
