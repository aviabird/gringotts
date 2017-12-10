defmodule Kuber.Hex.Gateways.MoneiTest do
  use ExUnit.Case, async: true

  alias Kuber.Hex.{
    CreditCard,
  }
  alias Kuber.Hex.Gateways.Monei, as: Gateway

  @card %CreditCard{
    name: "Jo Doe",
    number: "4200000000000000",
    expiration: {2099, 12},
    cvc:  "123",
    brand: "VISA"
  }

  @bad_card %CreditCard{
    name: "Jo Doe",
    number: "4200000000000000",
    expiration: {2000, 12},
    cvc:  "123",
    brand: "VISA"
  }

  @auth_success ~s[
    {"id": "8a82944a603b12d001603c1a1c2d5d90",
     "result": {
       "code": "000.100.110",
       "description": "Request successfully processed in 'Merchant in
       Integrator Test Mode'"}
    }]

  # A new Bypass instance is needed per test, so that we can do parallel tests
  setup do
    bypass = Bypass.open
    auth = %{userId: "8a829417539edb400153c1eae83932ac",
             password: "6XqRtMGS2N",
             entityId: "8a829417539edb400153c1eae6de325e",
             test_url: "http://localhost:#{bypass.port}"}
    {:ok, bypass: bypass, auth: auth}
  end


  test "core      | when config/auth-info is absent." do
    {:error, response} = Gateway.authorize(52.00, @card, [config: nil])
    assert response.reason == "Authorization fields missing"
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
    {:error, _response} = Gateway.authorize(52.00, @bad_card, [config: auth])
  end

  test "purchase  | when all is good.", %{bypass: bypass, auth: auth} do
    Bypass.expect_once bypass, "POST", "/v1/payments", fn conn ->
      Plug.Conn.resp(conn, 200, @auth_success)
    end
    {:ok, response} = Gateway.purchase(52.00, @card, [config: auth])
    assert response.code == "000.100.110"
  end

end

defmodule Kuber.Hex.Gateways.MoneiDocTest do
  use ExUnit.Case, async: true
  alias Kuber.Hex.{
    CreditCard,
    Gateways.Monei
  }

  doctest Kuber.Hex.Gateways.Monei
end
