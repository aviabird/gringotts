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
    verification_code:  "123",
    brand: "VISA"
  }

  @auth_success ~s[
    {"id": "8a82944a603b12d001603c1a1c2d5d90",
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

  @tag :skip
  test "core      | with unsupported currency.",
    %{bypass: bypass, auth: auth} do
    Bypass.expect_once bypass, "POST", "/v1/payments", fn conn ->
      Plug.Conn.resp(conn, 400, "<html></html>")
    end
    {:error, response} = Gateway.authorize(52, @card, [config: auth,
                                                       currency: "INR"])
    assert response.code == :unsupported_currency
  end

  test "core      | when MONEI is down or unreachable.",
    %{bypass: bypass, auth: auth} do
    Bypass.expect_once  bypass, fn conn ->
      Plug.Conn.resp(conn, 200, @auth_success)
    end
    Bypass.down bypass
    {:error, response} = Gateway.authorize(52.00, @card, [config: auth])
    assert response.reason == :network_fail?

    Bypass.up bypass
    {:ok, _} = Gateway.authorize(52.00, @card, [config: auth])
  end

  test "authorize | when all is good.", %{bypass: bypass, auth: auth} do
    Bypass.expect bypass, "POST", "/v1/payments", fn conn ->
      Plug.Conn.resp(conn, 200, @auth_success)
    end
    {:ok, response} = Gateway.authorize(52.00, @card, [config: auth])
    assert response.code == "000.100.110"
  end

  test "authorize | when we get non-json.", %{bypass: bypass, auth: auth} do
    Bypass.expect_once bypass, "POST", "/v1/payments", fn conn ->
      Plug.Conn.resp(conn, 400, "<html></html>")
    end
    {:error, _} = Gateway.authorize(52.00, @card, [config: auth])
  end

  test "authorize | when card has expired.", %{bypass: bypass, auth: auth} do
    Bypass.expect_once bypass, "POST", "/v1/payments", fn conn ->
      Plug.Conn.resp(conn, 400, "")
    end
    {:error, _response} = Gateway.authorize(52, @bad_card, [config: auth])
  end

  test "purchase  | when all is good.", %{bypass: bypass, auth: auth} do
    Bypass.expect_once bypass, "POST", "/v1/payments", fn conn ->
      Plug.Conn.resp(conn, 200, @auth_success)
    end
    {:ok, response} = Gateway.purchase(15, @card, [config: auth])
    assert response.code == "000.100.110"
  end

  test "store     | when all is good.", %{bypass: bypass, auth: auth} do
    Bypass.expect_once bypass, "POST", "/v1/registrations", fn conn ->
      Plug.Conn.resp(conn, 200, @store_success)
    end
    {:ok, response} = Gateway.store(@card, [config: auth])
    assert response.code == "000.100.110"
    assert response.raw["card"]["holder"] == "Jo Doe"
  end

  test "capture   | when all is good.", %{bypass: bypass, auth: auth} do
    Bypass.expect_once(
      bypass,
      "POST",
      "/v1/payments/7214344252e11af79c0b9e7b4f3f6234",
      fn conn ->
        Plug.Conn.resp(conn, 200, @auth_success)
      end)
    {:ok, response} = Gateway.capture(4000, "7214344252e11af79c0b9e7b4f3f6234", [config: auth])
    assert response.code == "000.100.110"
  end

  test "refund    | when all is good.", %{bypass: bypass, auth: auth} do
    Bypass.expect_once(
      bypass,
      "POST",
      "/v1/payments/7214344252e11af79c0b9e7b4f3f6234",
      fn conn ->
        Plug.Conn.resp(conn, 200, @auth_success)
      end)
    {:ok, response} = Gateway.refund(3, "7214344252e11af79c0b9e7b4f3f6234", [config: auth])
    assert response.code == "000.100.110"
  end
  
  test "unstore   | when all is good.", %{bypass: bypass, auth: auth} do
    Bypass.expect_once(
      bypass,
      "DELETE",
      "/v1/registrations/7214344252e11af79c0b9e7b4f3f6234",
      fn conn ->
        Plug.Conn.resp(conn, 200, "<html></html>")
      end)
    {:error, response} = Gateway.unstore("7214344252e11af79c0b9e7b4f3f6234", [config: auth])
    assert response.code == :undefined_response_from_monei
  end

  test "void      | when all is good", %{bypass: bypass, auth: auth} do
    Bypass.expect_once(
      bypass,
      "POST",
      "/v1/payments/7214344252e11af79c0b9e7b4f3f6234",
      fn conn ->
        Plug.Conn.resp(conn, 200, @auth_success)
      end)
    {:ok, response} = Gateway.void("7214344252e11af79c0b9e7b4f3f6234", [config: auth])
    assert response.code == "000.100.110"
  end

  @tag :skip
  test "respond   | various scenarios, can't test a private function." do
    json_200 = %HTTPoison.Response{body: @auth_success, status_code: 200}
    json_not_200 = %HTTPoison.Response{body: @auth_success, status_code: 300}
    html_200 = %HTTPoison.Response{body: ~s[<html></html>\n], status_code: 200}
    html_not_200 = %HTTPoison.Response{body: ~s[<html></html?], status_code: 300}
    all = [json_200, json_not_200, html_200, html_not_200]
    then = Enum.map(all, &Gateway.respond({:ok, &1}))
    assert Keyword.keys(then) == [:ok, :error, :error, :error]
  end
end

defmodule Gringotts.Gateways.MoneiDocTest do
  use ExUnit.Case, async: true

  # doctest Gringotts.Gateways.Monei
  # doctests will never work. Track progress: https://github.com/aviabird/gringotts/issues/37
end
