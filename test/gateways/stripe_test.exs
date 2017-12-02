defmodule Kuber.Hex.Gateways.StripeTest do
  use ExUnit.Case, async: false

  import Mock

  alias Kuber.Hex.{
    CreditCard,
    Address,
    Response
  }
  alias Kuber.Hex.Gateways.Stripe, as: Gateway

  defmacrop with_post(url, {status, response}, statement, do: block) do
    quote do
      {:ok, agent} = Agent.start_link(fn -> nil end)

      requestFn = fn(:post, unquote(url), params, [{"Content-Type", "application/x-www-form-urlencoded"}], [hackney: [basic_auth: {'user', 'pass'}]]) ->
        Agent.update(agent, fn(_) -> params end)
        {:ok, %{status_code: unquote(status), body: unquote(response)}}
      end

      with_mock HTTPoison, [request: requestFn] do
        unquote(statement)
        var!(params) = Agent.get(agent, &(URI.decode_query(&1)))

        unquote(block)

        Agent.stop(agent)
      end
    end
  end

  defmacrop with_delete(url, {status, response}, do: block) do
    quote do
      requestFn = fn(:delete, unquote(url), params, [{"Content-Type", "application/x-www-form-urlencoded"}], [hackney: [basic_auth: {'user', 'pass'}]]) ->
        {:ok, %{status_code: unquote(status), body: unquote(response)}}
      end

      with_mock HTTPoison, [request: requestFn], do: unquote(block)
    end
  end

  setup do
    config = %{credentials: {'user', 'pass'}, default_currency: "USD"}
    {:ok, config: config}
  end

  test "authorize success with credit card", %{config: config} do
    raw = ~S/
      {
        "id": "1234",
        "card": {
          "cvc_check": "pass",
          "address_line1_check": "unchecked",
          "address_zip_check": "pass"
        }
      }
    /
    card = %CreditCard{name: "John Smith", number: "123456", cvc: "123", expiration: {2015, 11}}
    address = %Address{street1: "123 Main", street2: "Suite 100", city: "New York", region: "NY", country: "US", postal_code: "11111"}

    with_post "https://api.stripe.com/v1/charges", {200, raw},
        response = Gateway.authorize(10.95, card, billing_address: address, config: config) do

      {:ok, %Response{authorization: authorization, success: success,
                      avs_result: avs_result, cvc_result: cvc_result}} = response

      assert success
      assert params["capture"] == "false"
      assert params["currency"] == "USD"
      assert params["amount"] == "1095"
      assert params["card[name]"] == "John Smith"
      assert params["card[number]"] == "123456"
      assert params["card[exp_month]"] == "11"
      assert params["card[exp_year]"] == "2015"
      assert params["card[cvc]"] == "123"
      assert params["card[address_line1]"] == "123 Main"
      assert params["card[address_line2]"] == "Suite 100"
      assert params["card[address_city]"] == "New York"
      assert params["card[address_state]"] == "NY"
      assert params["card[address_country]"] == "US"
      assert params["card[address_zip]"] == "11111"
      assert authorization == "1234"
      assert avs_result == "P"
      assert cvc_result == "M"
    end
  end

  test "purchase success with credit card", %{config: config} do
    raw = ~S/
      {
        "id": "1234",
        "card": {
          "cvc_check": "pass",
          "address_line1_check": "unchecked",
          "address_zip_check": "pass"
        }
      }
    /
    card = %CreditCard{name: "John Smith", number: "123456", cvc: "123", expiration: {2015, 11}}
    address = %Address{street1: "123 Main", street2: "Suite 100", city: "New York", region: "NY", country: "US", postal_code: "11111"}

    with_post "https://api.stripe.com/v1/charges", {200, raw},
        response = Gateway.purchase(10.95, card, billing_address: address, config: config) do

      {:ok, %Response{authorization: authorization, success: success,
                      avs_result: avs_result, cvc_result: cvc_result}} = response

      assert success
      assert params["capture"] == "true"
      assert params["currency"] == "USD"
      assert params["amount"] == "1095"
      assert params["card[name]"] == "John Smith"
      assert params["card[number]"] == "123456"
      assert params["card[exp_month]"] == "11"
      assert params["card[exp_year]"] == "2015"
      assert params["card[cvc]"] == "123"
      assert params["card[address_line1]"] == "123 Main"
      assert params["card[address_line2]"] == "Suite 100"
      assert params["card[address_city]"] == "New York"
      assert params["card[address_state]"] == "NY"
      assert params["card[address_country]"] == "US"
      assert params["card[address_zip]"] == "11111"
      assert authorization == "1234"
      assert avs_result == "P"
      assert cvc_result == "M"
    end
  end

  test "purchase success with credit card to a Connect account", %{config: config} do
    raw = ~S/
      {
        "id": "1234",
        "card": {
          "cvc_check": "pass",
          "address_line1_check": "unchecked",
          "address_zip_check": "pass"
        }
      }
    /
    card = %CreditCard{name: "John Smith", number: "123456", cvc: "123", expiration: {2015, 11}}
    address = %Address{street1: "123 Main", street2: "Suite 100", city: "New York", region: "NY", country: "US", postal_code: "11111"}
    destination = "stripe_id"
    application_fee = 123

    with_post "https://api.stripe.com/v1/charges", {200, raw},
        response = Gateway.purchase(10.95, card, billing_address: address, config: config, destination: destination, application_fee: application_fee) do

      {:ok, %Response{authorization: authorization, success: success,
                      avs_result: avs_result, cvc_result: cvc_result}} = response

      assert success
      assert params["capture"] == "true"
      assert params["currency"] == "USD"
      assert params["amount"] == "1095"
      assert params["card[name]"] == "John Smith"
      assert params["card[number]"] == "123456"
      assert params["card[exp_month]"] == "11"
      assert params["card[exp_year]"] == "2015"
      assert params["card[cvc]"] == "123"
      assert params["card[address_line1]"] == "123 Main"
      assert params["card[address_line2]"] == "Suite 100"
      assert params["card[address_city]"] == "New York"
      assert params["card[address_state]"] == "NY"
      assert params["card[address_country]"] == "US"
      assert params["card[address_zip]"] == "11111"
      assert params["destination"] == destination
      assert params["application_fee"] == "123"
      assert authorization == "1234"
      assert avs_result == "P"
      assert cvc_result == "M"
    end
  end

  test "capture success", %{config: config} do
    raw = ~S/{"id": "1234"}/

    with_post "https://api.stripe.com/v1/charges/1234/capture", {200, raw},
        response = Gateway.capture(1234, amount: 19.95, config: config) do

      {:ok, %Response{authorization: authorization, success: success}} = response

      assert success
      assert params["amount"] == "1995"
      assert authorization == "1234"
    end
  end

  test "void success", %{config: config} do
    raw = ~S/{"id": "1234"}/

    with_post "https://api.stripe.com/v1/charges/1234/refund", {200, raw},
        response = Gateway.void(1234, config: config) do

      {:ok, %Response{authorization: authorization, success: success}} = response

      assert success
      assert params["amount"] == nil
      assert authorization == "1234"
    end
  end

  test "refund success", %{config: config} do
    raw = ~S/{"id": "1234"}/

    with_post "https://api.stripe.com/v1/charges/1234/refund", {200, raw},
        response = Gateway.refund(19.95, 1234, config: config) do

      {:ok, %Response{authorization: authorization, success: success}} = response

      assert success
      assert params["amount"] == "1995"
      assert authorization == "1234"
    end
  end

  test "store credit card without customer", %{config: config} do
    raw = ~S/{"id": "1234"}/
    card = %CreditCard{name: "John Smith", number: "123456", cvc: "123", expiration: {2015, 11}}

    with_post "https://api.stripe.com/v1/customers", {200, raw},
        response = Gateway.store(card, config: config) do

      {:ok, %Response{authorization: authorization, success: success}} = response

      assert success
      assert params["card[name]"] == "John Smith"
      assert params["card[number]"] == "123456"
      assert params["card[exp_month]"] == "11"
      assert params["card[exp_year]"] == "2015"
      assert params["card[cvc]"] == "123"
      assert authorization == "1234"
    end
  end

  test "store credit card with customer", %{config: config} do
    raw = ~S/{"id": "1234"}/
    card = %CreditCard{name: "John Smith", number: "123456", cvc: "123", expiration: {2015, 11}}

    with_post "https://api.stripe.com/v1/customers/1234/card", {200, raw},
        response = Gateway.store(card, customer_id: 1234, config: config) do

      {:ok, %Response{authorization: authorization, success: success}} = response

      assert success
      assert params["card[name]"] == "John Smith"
      assert params["card[number]"] == "123456"
      assert params["card[exp_month]"] == "11"
      assert params["card[exp_year]"] == "2015"
      assert params["card[cvc]"] == "123"
      assert authorization == "1234"
    end
  end

  test "unstore credit card", %{config: config} do
    with_delete "https://api.stripe.com/v1/customers/123/456", {200, "{}"} do
      {:ok, %Response{success: success}} = Gateway.unstore(123, 456, config: config)

      assert success
    end
  end

  test "unstore customer", %{config: config} do
    with_delete "https://api.stripe.com/v1/customers/123", {200, "{}"} do
      {:ok, %Response{success: success}} = Gateway.unstore(123, nil, config: config)

      assert success
    end
  end
end
