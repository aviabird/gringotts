defmodule Gringotts.Gateways.Base do
  @moduledoc """
  Dummy implementation of the Gringotts API

  All gateway implementations must `use` this module as it provides (pseudo)
  implementations for the all methods of the Gringotts API.

  In case `GatewayXYZ` does not implement `unstore`, the following call would
  not raise an error:
  ```
  Gringotts.unstore(GatewayXYZ, "some_registration_id")
  ```
  because this module provides an implementation.
  """

  alias Gringotts.Response

  defmacro __using__(_) do
    quote location: :keep do
      @doc false
      def purchase(_amount, _card_or_id, _opts) do
        not_implemented()
      end

      @doc false
      def authorize(_amount, _card_or_id, _opts) do
        not_implemented()
      end

      @doc false
      def capture(_id, _amount, _opts) do
        not_implemented()
      end

      @doc false
      def void(_id, _opts) do
        not_implemented()
      end

      @doc false
      def refund(_amount, _id, _opts) do
        not_implemented()
      end

      @doc false
      def store(_card, _opts) do
        not_implemented()
      end

      @doc false
      def unstore(_customer_id, _opts) do
        not_implemented()
      end

      @doc false
      defp not_implemented do
        {:error, Response.error(code: :not_implemented)}
      end

      defoverridable purchase: 3,
                     authorize: 3,
                     capture: 3,
                     void: 2,
                     refund: 3,
                     store: 2,
                     unstore: 2
    end
  end
end
