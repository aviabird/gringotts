defmodule Gringotts.Gateways.Base do
  alias Gringotts.Response

  defmacro __using__(_) do
    quote location: :keep do
      @doc false
      def purchase(_amount, _card_or_id, _opts)  do
        not_implemented()
      end

      @doc false
      def authorize(_amount, _card_or_id, _opts)  do
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

      defp http(method, path, params \\ [], opts \\ []) do
        credentials = Keyword.get(opts, :credentials)
        headers     = [{"Content-Type", "application/x-www-form-urlencoded"}]
        data        = params_to_string(params)

        HTTPoison.request(method, path, data, headers, [hackney: [basic_auth: credentials]])
      end

      defp money_to_cents(amount) when is_float(amount) do
        trunc(amount * 100)
      end

      defp money_to_cents(amount) do
        amount * 100
      end

      defp params_to_string(params) do
        params |> Enum.filter(fn {_k, v} -> v != nil end)
               |> URI.encode_query
      end

      @doc false
      defp not_implemented do
        {:error, Response.error(code: :not_implemented)}
      end

      defoverridable [purchase: 3, authorize: 3, capture: 3, void: 2, refund: 3, store: 2, unstore: 2]
    end
  end
end
