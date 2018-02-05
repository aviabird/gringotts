defmodule Gringotts.Gateways.MoneiTest do
  use ExUnit.Case, async: true

  alias Gringotts.{
    CreditCard
  }

  alias Gringotts.Gateways.Monei, as: Gateway

  @amount42 Money.new(42, :USD)
  @amount3 Money.new(3, :USD)
  @bad_currency Money.new(42, :INR)

  @card %CreditCard{
    first_name: "Harry",
    last_name: "Potter",
    number: "4200000000000000",
    year: 2099,
    month: 12,
    verification_code: "123",
    brand: "VISA"
  }

  @bad_card %CreditCard{
    first_name: "Harry",
    last_name: "Potter",
    number: "4200000000000000",
    year: 2000,
    month: 12,
    verification_code: "123",
    brand: "VISA"
  }

  @customer %{
    givenName: "Harry",
    surname: "Potter",
    merchantCustomerId: "the_boy_who_lived",
    sex: "M",
    birthDate: "1980-07-31",
    mobile: "+15252525252",
    email: "masterofdeath@ministryofmagic.gov",
    ip: "1.1.1",
    status: "NEW"
  }
  @merchant %{
    name: "Ollivanders",
    city: "South Side",
    street: "Diagon Alley",
    state: "London",
    country: "GB",
    submerchantId: "Makers of Fine Wands since 382 B.C."
  }
  @billing %{
    street1: "301, Gryffindor",
    street2: "Hogwarts School of Witchcraft and Wizardry, Hogwarts Castle",
    city: "Highlands",
    state: "Scotland",
    country: "GB"
  }
  @shipping Map.merge(
              %{method: "SAME_DAY_SERVICE", comment: "For our valued customer, Mr. Potter"},
              @billing
            )

  @extra_opts [
    customer: @customer,
    merchant: @merchant,
    billing: @billing,
    shipping: @shipping,
    shipping_customer: @customer,
    category: "EC",
    register: true,
    custom: %{"voldemort" => "he who must not be named"}
  ]

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
    bypass = Bypass.open()

    auth = %{
      userId: "some_secret_user_id",
      password: "some_secret_password",
      entityId: "some_secret_entity_id",
      test_url: "http://localhost:#{bypass.port}"
    }

    {:ok, bypass: bypass, auth: auth}
  end

  describe "core" do
    test "with unsupported currency.", %{auth: auth} do
      {:error, response} = Gateway.authorize(@bad_currency, @card, config: auth)
      assert response.reason == "Invalid currency"
    end

    test "when MONEI is down or unreachable.", %{bypass: bypass, auth: auth} do
      Bypass.expect_once(bypass, fn conn ->
        Plug.Conn.resp(conn, 200, @auth_success)
      end)

      Bypass.down(bypass)
      {:error, response} = Gateway.authorize(@amount42, @card, config: auth)
      assert response.reason == "network related failure"

      Bypass.up(bypass)
      {:ok, _} = Gateway.authorize(@amount42, @card, config: auth)
    end

    test "with all extra_params.", %{bypass: bypass, auth: auth} do
      randoms = [
        invoice_id: Base.encode16(:crypto.hash(:md5, :crypto.strong_rand_bytes(32))),
        transaction_id: Base.encode16(:crypto.hash(:md5, :crypto.strong_rand_bytes(32)))
      ]

      Bypass.expect_once(bypass, "POST", "/v1/payments", fn conn ->
        conn_ = parse(conn)
        assert conn_.body_params["createRegistration"] == "true"
        assert conn_.body_params["customParameters"] == @extra_opts[:custom]
        assert conn_.body_params["merchantInvoiceId"] == randoms[:invoice_id]
        assert conn_.body_params["merchantTransactionId"] == randoms[:transaction_id]
        assert conn_.body_params["transactionCategory"] == @extra_opts[:category]
        assert conn_.body_params["customer.merchantCustomerId"] == @customer[:merchantCustomerId]

        assert conn_.body_params["shipping.customer.merchantCustomerId"] ==
                 @customer[:merchantCustomerId]

        assert conn_.body_params["merchant.submerchantId"] == @merchant[:submerchantId]
        assert conn_.body_params["billing.city"] == @billing[:city]
        assert conn_.body_params["shipping.method"] == @shipping[:method]
        Plug.Conn.resp(conn, 200, @register_success)
      end)

      opts = randoms ++ @extra_opts ++ [config: auth]
      {:ok, response} = Gateway.purchase(@amount42, @card, opts)
      assert response.gateway_code == "000.100.110"
      assert response.token == "8a82944a60e09c550160e92da144491e"
    end

    test "when card has expired.", %{bypass: bypass, auth: auth} do
      Bypass.expect_once(bypass, "POST", "/v1/payments", fn conn ->
        Plug.Conn.resp(conn, 400, "<html></html>")
      end)

      {:error, _} = Gateway.authorize(@amount42, @bad_card, config: auth)
    end
  end

  describe "authorize" do
    test "when all is good.", %{bypass: bypass, auth: auth} do
      Bypass.expect(bypass, "POST", "/v1/payments", fn conn ->
        Plug.Conn.resp(conn, 200, @auth_success)
      end)

      {:ok, response} = Gateway.authorize(@amount42, @card, config: auth)
      assert response.gateway_code == "000.100.110"
    end
  end

  describe "purchase" do
    test "when all is good.", %{bypass: bypass, auth: auth} do
      Bypass.expect_once(bypass, "POST", "/v1/payments", fn conn ->
        Plug.Conn.resp(conn, 200, @auth_success)
      end)

      {:ok, response} = Gateway.purchase(@amount42, @card, config: auth)
      assert response.gateway_code == "000.100.110"
    end

    test "with createRegistration.", %{bypass: bypass, auth: auth} do
      Bypass.expect_once(bypass, "POST", "/v1/payments", fn conn ->
        conn_ = parse(conn)
        assert conn_.body_params["createRegistration"] == "true"
        Plug.Conn.resp(conn, 200, @register_success)
      end)

      {:ok, response} = Gateway.purchase(@amount42, @card, register: true, config: auth)
      assert response.gateway_code == "000.100.110"
      assert response.token == "8a82944a60e09c550160e92da144491e"
    end
  end

  describe "store" do
    test "when all is good.", %{bypass: bypass, auth: auth} do
      Bypass.expect_once(bypass, "POST", "/v1/registrations", fn conn ->
        Plug.Conn.resp(conn, 200, @store_success)
      end)

      {:ok, response} = Gateway.store(@card, config: auth)
      assert response.gateway_code == "000.100.110"
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
        end
      )

      {:ok, response} =
        Gateway.capture("7214344242e11af79c0b9e7b4f3f6234", @amount42, config: auth)

      assert response.gateway_code == "000.100.110"
    end

    test "with createRegistration that is ignored", %{bypass: bypass, auth: auth} do
      Bypass.expect_once(
        bypass,
        "POST",
        "/v1/payments/7214344242e11af79c0b9e7b4f3f6234",
        fn conn ->
          conn_ = parse(conn)
          assert :error == Map.fetch(conn_.body_params, "createRegistration")
          Plug.Conn.resp(conn, 200, @auth_success)
        end
      )

      {:ok, response} =
        Gateway.capture(
          "7214344242e11af79c0b9e7b4f3f6234",
          @amount42,
          register: true,
          config: auth
        )

      assert response.gateway_code == "000.100.110"
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
        end
      )

      {:ok, response} = Gateway.refund(@amount3, "7214344242e11af79c0b9e7b4f3f6234", config: auth)

      assert response.gateway_code == "000.100.110"
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
        end
      )

      {:error, response} = Gateway.unstore("7214344242e11af79c0b9e7b4f3f6234", config: auth)
      assert response.reason == "undefined response from monei"
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
        end
      )

      {:ok, response} = Gateway.void("7214344242e11af79c0b9e7b4f3f6234", config: auth)
      assert response.gateway_code == "000.100.110"
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
  # doctests can work. Track progress: https://github.com/aviabird/gringotts/issues/37
end
