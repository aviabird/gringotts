defmodule Kuber.Hex.Worker do
  use GenServer

  def start_link(gateways, all_config, opts \\ []) do
    GenServer.start_link(__MODULE__, [gateways, all_config], opts)
  end

  def init([gateways, all_config]) do
    {:ok, %{configs: all_config, gateways: gateways}}
  end

  def handle_call({:authorize, gateway, amount, card, opts}, _from, state) do
    {gateway, config} = set_gateway_and_config(gateway)
    response = gateway.authorize(amount, card, [{:config, config} | opts])
    {:reply, response, state}
  end

  def handle_call({:purchase, gateway, amount, card, opts}, _from, state) do
    {gateway, config} = set_gateway_and_config(gateway)
    response = gateway.purchase(amount, card, [{:config, config} | opts])
    {:reply, response, state}
  end

  def handle_call({:capture, gateway, id, amount, opts}, _from, state) do
    {gateway, config} = set_gateway_and_config(gateway)
    response = gateway.capture(id, amount, [{:config, config} | opts])
    {:reply, response, state}
  end

  def handle_call({:void, gateway, id, opts}, _from, state) do
    {gateway, config} = set_gateway_and_config(gateway)
    response = gateway.void(id, [{:config, config} | opts])
    {:reply, response, state}
  end

  def handle_call({:refund, gateway, amount, id, opts}, _from, state) do
    {gateway, config} = set_gateway_and_config(gateway)
    response = gateway.refund(amount, id, [{:config, config} | opts])
    {:reply, response, state}
  end

  def handle_call({:store, gateway, card, opts}, _from, state) do
    {gateway, config} = set_gateway_and_config(gateway)
    response = gateway.store(card, [{:config, config} | opts])
    {:reply, response, state}
  end

  def handle_call({:unstore, gateway, customer_id, card_id, opts}, _from, state) do
    {gateway, config} = set_gateway_and_config(gateway)
    response = gateway.unstore(customer_id, card_id, [{:config, config} | opts])
    {:reply, response, state}
  end

  @doc """
  Sets the gateway module name and config for this gateway
  """
  defp set_gateway_and_config(request_gateway) do
    { request_gateway, Application.get_env(:kuber_hex, request_gateway) }
  end
end
