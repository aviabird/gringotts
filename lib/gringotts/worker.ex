defmodule Gringotts.Worker do
  @moduledoc ~S"""
  A central supervised worker handling all the calls for different gateways

  It's main task is to re-route the requests to the respective gateway methods.

  State for this worker currently is:-
    * `gateways`:- a list of all the gateways configured in the application.
    * `all_configs`:- All the configurations for all the gateways that are configured.
  """
  use GenServer

  def start_link(gateways, all_config, opts \\ []) do
    GenServer.start_link(__MODULE__, [gateways, all_config], opts)
  end

  def init([gateways, all_config]) do
    {:ok, %{configs: all_config, gateways: gateways}}
  end

  @doc """
  Handles call for `authorize` method
  """
  def handle_call({:authorize, gateway, amount, card, opts}, _from, state) do
    {gateway, config} = set_gateway_and_config(gateway)
    response = gateway.authorize(amount, card, [{:config, config} | opts])
    {:reply, response, state}
  end

  @doc """
  Handles call for `purchase` method
  """
  def handle_call({:purchase, gateway, amount, card, opts}, _from, state) do
    {gateway, config} = set_gateway_and_config(gateway)
    response = gateway.purchase(amount, card, [{:config, config} | opts])
    {:reply, response, state}
  end

  @doc """
  Handles call for `capture` method
  """
  def handle_call({:capture, gateway, id, amount, opts}, _from, state) do
    {gateway, config} = set_gateway_and_config(gateway)
    response = gateway.capture(id, amount, [{:config, config} | opts])
    {:reply, response, state}
  end

  @doc """
  Handles call for `void` method
  """
  def handle_call({:void, gateway, id, opts}, _from, state) do
    {gateway, config} = set_gateway_and_config(gateway)
    response = gateway.void(id, [{:config, config} | opts])
    {:reply, response, state}
  end

  @doc """
  Handles call for 'refund' method
  """
  def handle_call({:refund, gateway, amount, id, opts}, _from, state) do
    {gateway, config} = set_gateway_and_config(gateway)
    response = gateway.refund(amount, id, [{:config, config} | opts])
    {:reply, response, state}
  end

  @doc """
  Handles call for `store` method
  """
  def handle_call({:store, gateway, card, opts}, _from, state) do
    {gateway, config} = set_gateway_and_config(gateway)
    response = gateway.store(card, [{:config, config} | opts])
    {:reply, response, state}
  end

  @doc """
  Handles call for 'unstore' method
  """
  def handle_call({:unstore, gateway, customer_id, opts}, _from, state) do
    {gateway, config} = set_gateway_and_config(gateway)
    response = gateway.unstore(customer_id, [{:config, config} | opts])
    {:reply, response, state}
  end

  defp set_gateway_and_config(request_gateway) do
    global_config = Application.get_env(:gringotts, :global_config) || [mode: :test]
    gateway_config = Application.get_env(:gringotts, request_gateway)
    {request_gateway, Keyword.merge(global_config, gateway_config)}
  end
end
