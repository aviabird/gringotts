defmodule Kuber.Hex.Worker do
  use GenServer

  def start_link(gateway, config, opts \\ []) do
    GenServer.start_link(__MODULE__, [gateway, config], opts)
  end

  def init([gateway, config]) do
    {:ok, %{config: config, gateway: gateway}}
  end

  def handle_call({:authorize, amount, card, opts}, _from, state) do
    response = state.gateway.authorize(amount, card, [{:config, state.config} | opts])
    {:reply, response, state}
  end

  def handle_call({:purchase, amount, card, opts}, _from, state) do
    response = state.gateway.purchase(amount, card, [{:config, state.config} | opts])
    {:reply, response, state}
  end

  def handle_call({:capture, id, opts}, _from, state) do
    response = state.gateway.capture(id, [{:config, state.config} | opts])
    {:reply, response, state}
  end

  def handle_call({:void, id, opts}, _from, state) do
    response = state.gateway.void(id, [{:config, state.config} | opts])
    {:reply, response, state}
  end

  def handle_call({:refund, amount, id, opts}, _from, state) do
    response = state.gateway.refund(amount, id, [{:config, state.config} | opts])
    {:reply, response, state}
  end

  def handle_call({:store, card, opts}, _from, state) do
    response = state.gateway.store(card, [{:config, state.config} | opts])
    {:reply, response, state}
  end

  def handle_call({:unstore, customer_id, card_id, opts}, _from, state) do
    response = state.gateway.unstore(customer_id, card_id, [{:config, state.config} | opts])
    {:reply, response, state}
  end
end
