defmodule Gringotts.Gateways.MoneiTest do
  use ExUnit.Case, async: false

  alias Gringotts.{
    CreditCard,
  }
  alias Gringotts.Gateways.Monei, as: Gateway

  @card %CreditCard{
    first_name: "Jo",
    last_name: "Doe",
    number: "4200000000000000",
    year: 2099,
    month: 12,
    verification_code: "123",
    brand: "VISA"
  }

  @bad_card %CreditCard{
    first_name: "Jo",
    last_name: "Doe",
    number: "4200000000000000",
    year: 2000,
    month: 12,
    verification_code: "123",
    brand: "VISA"
  }

  @bad_currency Money.new(42, :INR)

  @auth_success ~s[
    {"id": "8a82944a603b12d001603c1a1c2d5d90",
     "result": {
       "code": "000.100.110",
       "description": "Request successfully processed in 'Merchant in Integrator Test Mode'"}
    }]

  @register_success ~s[
    {"id": "8a82944960e073640160e92da2204743",
     "registrationId": "8a82944a60e09c550160e92da144491e",
     "result": {
       "code": "000.100.110",
       "description": "Request successfully processed in 'Merchant in Integrator Test Mode'"}
    }]
  
  @store_success ~s[
    {"result":{
        "code":"000.100.110",
        "description":"Request successfully processed in 'Merchant in Integrator Test Mode'"
     },
     "card":{
       "bin":"420000",
       "last4Digits":"0000",
       "holder":"Jo Doe",
       "expiryMonth":"12",
       "expiryYear":"2099"
     }
    }]

  # A new Bypass instance is needed per test, so that we can do parallel tests
  setup do
    bypass = Bypass.open
    auth = %{
      userId: "8a829417539edb400153c1eae83932ac",
      password: "6XqRtMGS2N",
      entityId: "8a829417539edb400153c1eae6de325e",
      test_url: "http://localhost:#{bypass.port}"
    }
    {:ok, bypass: bypass, auth: auth}
  end

  describe "core" do
    test "with unsupported currency.",
      %{auth: auth} do
      {:error, response} = Gateway.authorize(@bad_currency, @card, [config: auth])
      assert response.description == "Invalid currency"
    end

    test "when MONEI is down or unreachable.",
      %{bypass: bypass, auth: auth} do
      Bypass.expect_once  bypass, fn conn ->
        Plug.Conn.resp(conn, 200, @auth_success)
      end
      Bypass.down bypass
      {:error, response} = Gateway.authorize(Money.new(42, :USD), @card, [config: auth])
      assert response.reason == "network related failure"

      Bypass.up bypass
      {:ok, _} = Gateway.authorize(Money.new(42, :USD), @card, [config: auth])
    end
  end

  describe "authorize" do
    test "when all is good.", %{bypass: bypass, auth: auth} do
      Bypass.expect bypass, "POST", "/v1/payments", fn conn ->
        Plug.Conn.resp(conn, 200, @auth_success)
      end
      {:ok, response} = Gateway.authorize(Money.new(42, :USD), @card, [config: auth])
      assert response.code == "000.100.110"
    end

    test "when we get non-json.", %{bypass: bypass, auth: auth} do
      Bypass.expect_once bypass, "POST", "/v1/payments", fn conn ->
        Plug.Conn.resp(conn, 400, "<html></html>")
      end
      {:error, _} = Gateway.authorize(Money.new(42, :USD), @card, [config: auth])
    end

    test "when card has expired.", %{bypass: bypass, auth: auth} do
      Bypass.expect_once bypass, "POST", "/v1/payments", fn conn ->
        Plug.Conn.resp(conn, 400, "")
      end
      {:error, _response} = Gateway.authorize(Money.new(42, :USD), @bad_card, [config: auth])
    end
  end

  describe "purchase" do
    test "when all is good.", %{bypass: bypass, auth: auth} do
      Bypass.expect_once bypass, "POST", "/v1/payments", fn conn ->
        Plug.Conn.resp(conn, 200, @auth_success)
      end
      {:ok, response} = Gateway.purchase(Money.new(42, :USD), @card, [config: auth])
      assert response.code == "000.100.110"
    end

    test "with createRegistration.", %{bypass: bypass, auth: auth} do
      Bypass.expect_once bypass, "POST", "/v1/payments", fn conn ->
        conn_ = parse(conn)
        assert conn_.body_params["createRegistration"] == "true"
        Plug.Conn.resp(conn, 200, @register_success)
      end
      {:ok, response} = Gateway.purchase(Money.new(42, :USD), @card, [config: auth, register: true])
      assert response.code == "000.100.110"
      assert response.token == "8a82944a60e09c550160e92da144491e"
    end
  end

  describe "store" do
    test "when all is good.", %{bypass: bypass, auth: auth} do
      Bypass.expect_once bypass, "POST", "/v1/registrations", fn conn ->
        Plug.Conn.resp(conn, 200, @store_success)
      end
      {:ok, response} = Gateway.store(@card, [config: auth])
      assert response.code == "000.100.110"
      assert response.raw["card"]["holder"] == "Jo Doe"
    end
  end

  describe "capture" do
    test "when all is good.", %{bypass: bypass, auth: auth} do
      Bypass.expect_once(
        bypass,
        "POST",
        "/v1/payments/7214344242e11af79c0b9e7b4f3f6234",
        fn conn ->
          Plug.Conn.resp(conn, 200, @auth_success)
        end)
      {:ok, response} = Gateway.capture(Money.new(42, :USD), "7214344242e11af79c0b9e7b4f3f6234", [config: auth])
      assert response.code == "000.100.110"
    end

    test "with createRegistration that is ignored", %{bypass: bypass, auth: auth} do
      Bypass.expect_once(
        bypass,
        "POST",
        "/v1/payments/7214344242e11af79c0b9e7b4f3f6234",
        fn conn ->
          conn_ = parse(conn)
          assert :error == Map.fetch conn_.body_params, "createRegistration"
          Plug.Conn.resp(conn, 200, @auth_success)
        end)
      {:ok, response} = Gateway.capture(Money.new(42, :USD), "7214344242e11af79c0b9e7b4f3f6234", [config: auth, register: true])
      assert response.code == "000.100.110"
    end
  end

  describe "refund" do
    test "when all is good.", %{bypass: bypass, auth: auth} do
      Bypass.expect_once(
        bypass,
        "POST",
        "/v1/payments/7214344242e11af79c0b9e7b4f3f6234",
        fn conn ->
          Plug.Conn.resp(conn, 200, @auth_success)
        end)
      {:ok, response} = Gateway.refund(Money.new(3, :USD), "7214344242e11af79c0b9e7b4f3f6234", [config: auth])
      assert response.code == "000.100.110"
    end
  end
  
  describe "unstore" do
    test "when all is good.", %{bypass: bypass, auth: auth} do
      Bypass.expect_once(
        bypass,
        "DELETE",
        "/v1/registrations/7214344242e11af79c0b9e7b4f3f6234",
        fn conn ->
          Plug.Conn.resp(conn, 200, "<html></html>")
        end)
      {:error, response} = Gateway.unstore("7214344242e11af79c0b9e7b4f3f6234", [config: auth])
      assert response.code == :undefined_response_from_monei
    end
  end

  describe "void" do
    test "when all is good", %{bypass: bypass, auth: auth} do
      Bypass.expect_once(
        bypass,
        "POST",
        "/v1/payments/7214344242e11af79c0b9e7b4f3f6234",
        fn conn ->
          Plug.Conn.resp(conn, 200, @auth_success)
        end)
      {:ok, response} = Gateway.void("7214344242e11af79c0b9e7b4f3f6234", [config: auth])
      assert response.code == "000.100.110"
    end
  end

  @tag :skip
  test "respond various scenarios, can't test a private function." do
    json_200 = %HTTPoison.Response{body: @auth_success, status_code: 200}
    json_not_200 = %HTTPoison.Response{body: @auth_success, status_code: 300}
    html_200 = %HTTPoison.Response{body: ~s[<html></html>\n], status_code: 200}
    html_not_200 = %HTTPoison.Response{body: ~s[<html></html?], status_code: 300}
    all = [json_200, json_not_200, html_200, html_not_200]
    then = Enum.map(all, &Gateway.respond({:ok, &1}))
    assert Keyword.keys(then) == [:ok, :error, :error, :error]
  end

  def parse(conn, opts \\ []) do
    opts = Keyword.put_new(opts, :parsers, [Plug.Parsers.URLENCODED])
    Plug.Parsers.call(conn, Plug.Parsers.init(opts))
  end
end

defmodule Gringotts.Gateways.MoneiDocTest do
  use ExUnit.Case, async: true

  # doctest Gringotts.Gateways.Monei
  # doctests will never work. Track progress: https://github.com/aviabird/gringotts/issues/37
end
