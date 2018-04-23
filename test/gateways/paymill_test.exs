defmodule Gringotts.Gateways.PaymillTest do
  use ExUnit.Case, async: true

  alias Gringotts.Gateways.Paymill, as: Gateway
  alias Gringotts.Gateways.PaymillMock, as: Mock
  alias Plug.{Conn, Parsers}

  setup do
    bypass = Bypass.open()

    opts = %{
      private_key: "merchant_secret_key",
      public_key: "merchant_public_key",
      test_url: "http://localhost:#{bypass.port}/"
    }

    {:ok, bypass: bypass, opts: opts}
  end

  @amount_42 Money.new(42, :EUR)
  @valid_token "tok_d26e611c47d64693a281e8411934"
  @invalid_token "tok_d26e611c47d64693a281e841193"

  @transaction_id "tran_de77d38b85d6eee2984accc8b2cc"
  @invalid_transaction_id "tran_023d3b5769321c649435"
  @capture_preauth_id "preauth_d654694c8116109af903"
  @void_id "preauth_0bfc975c2858980a6023"

  describe "authorize" do
    test "when token is valid", %{bypass: bypass, opts: opts} do
      Bypass.expect(bypass, "POST", "/preauthorizations", fn conn ->
        p_conn = parse(conn)
        params = p_conn.body_params
        assert params["amount"] == "4200"
        assert params["currency"] == "EUR"
        assert params["token"] == "tok_d26e611c47d64693a281e8411934"
        Conn.resp(conn, 200, Mock.auth_success())
      end)

      {:ok, response} = Gateway.authorize(@amount_42, @valid_token, config: opts)
      assert response.gateway_code == 20000
    end

    test "when paymill is down or unreachable", %{bypass: bypass, opts: opts} do
      Bypass.down(bypass)
      {:error, response} = Gateway.authorize(@amount_42, @valid_token, config: opts)
      assert response.reason == "network related failure"
      Bypass.up(bypass)
    end

    test "when token is invalid", %{bypass: bypass, opts: opts} do
      Bypass.expect(bypass, "POST", "/preauthorizations", fn conn ->
        p_conn = parse(conn)
        params = p_conn.body_params
        assert params["amount"] == "4200"
        assert params["currency"] == "EUR"
        assert params["token"] == "tok_d26e611c47d64693a281e841193"
        Conn.resp(conn, 400, Mock.auth_purchase_invalid_token())
      end)

      {:error, response} = Gateway.authorize(@amount_42, @invalid_token, config: opts)
      assert response.status_code == 400
    end
  end

  describe "capture" do
    test "when preauthorization is valid", %{bypass: bypass, opts: opts} do
      Bypass.expect(bypass, "POST", "/transactions", fn conn ->
        p_conn = parse(conn)
        params = p_conn.body_params
        assert params["amount"] == "4200"
        assert params["currency"] == "EUR"
        assert params["preauthorization"] == "preauth_d654694c8116109af903"
        Conn.resp(conn, 200, Mock.capture_success())
      end)

      {:ok, response} = Gateway.capture(@capture_preauth_id, @amount_42, config: opts)
      assert response.gateway_code == 20000
    end

    test "when preauthorization not found", %{bypass: bypass, opts: opts} do
      Bypass.expect(bypass, "POST", "/transactions", fn conn ->
        p_conn = parse(conn)
        params = p_conn.body_params
        assert params["amount"] == "4200"
        assert params["currency"] == "EUR"
        assert params["preauthorization"] == "preauth_d654694c8116109af903"
        Conn.resp(conn, 200, Mock.bad_preauth())
      end)

      {:error, response} = Gateway.capture(@capture_preauth_id, @amount_42, config: opts)
      assert response.status_code == 200
      assert response.reason == "Preauthorize not found"
    end

    test "when preauthorization done before", %{bypass: bypass, opts: opts} do
      Bypass.expect(bypass, "POST", "/transactions", fn conn ->
        p_conn = parse(conn)
        params = p_conn.body_params
        assert params["amount"] == "4200"
        assert params["currency"] == "EUR"
        assert params["preauthorization"] == "preauth_d654694c8116109af903"
        Conn.resp(conn, 200, Mock.capture_preauth_done_before())
      end)

      {:error, response} = Gateway.capture(@capture_preauth_id, @amount_42, config: opts)
      assert response.status_code == 200
      assert response.reason == "Preauthorization has already been used"
    end
  end

  describe "purchase" do
    test "when token is valid", %{bypass: bypass, opts: opts} do
      Bypass.expect(bypass, "POST", "/transactions", fn conn ->
        p_conn = parse(conn)
        params = p_conn.body_params
        assert params["amount"] == "4200"
        assert params["currency"] == "EUR"
        assert params["token"] == "tok_d26e611c47d64693a281e841193"
        Conn.resp(conn, 200, Mock.purchase_valid_token())
      end)

      {:ok, response} = Gateway.purchase(@amount_42, @invalid_token, config: opts)
      assert response.gateway_code == 20000
      assert response.fraud_review == true
      assert response.status_code == 200
    end

    test "when token is invalid", %{bypass: bypass, opts: opts} do
      Bypass.expect(bypass, "POST", "/transactions", fn conn ->
        p_conn = parse(conn)
        params = p_conn.body_params
        assert params["amount"] == "4200"
        assert params["currency"] == "EUR"
        assert params["token"] == "tok_d26e611c47d64693a281e841193"
        Conn.resp(conn, 200, Mock.auth_purchase_invalid_token())
      end)

      {:error, response} = Gateway.purchase(@amount_42, @invalid_token, config: opts)
      assert response.reason["field"] == "token"

      assert response.reason["messages"]["regexNotMatch"] ==
               "'tok_d26e611c47d64693a281e841193' does not match against pattern '\/^[a-zA-Z0-9_]{32}$\/'"

      assert response.status_code == 200
    end
  end

  describe "refund" do
    test "when transaction is valid", %{bypass: bypass, opts: opts} do
      Bypass.expect(bypass, "POST", "/refunds/#{@transaction_id}", fn conn ->
        p_conn = parse(conn)
        params = p_conn.body_params
        assert params["amount"] == "4200"
        Conn.resp(conn, 200, Mock.refund_success())
      end)

      {:ok, response} = Gateway.refund(@amount_42, @transaction_id, config: opts)
      assert response.gateway_code == 20000
      assert response.status_code == 200
    end

    test "when transaction is used again", %{bypass: bypass, opts: opts} do
      Bypass.expect(bypass, "POST", "/refunds/#{@transaction_id}", fn conn ->
        p_conn = parse(conn)
        params = p_conn.body_params
        assert params["amount"] == "4200"
        Conn.resp(conn, 200, Mock.refund_again())
      end)

      {:error, response} = Gateway.refund(@amount_42, @transaction_id, config: opts)
      assert response.reason == "Amount to high"
      assert response.status_code == 200
    end

    test "when transaction not found", %{bypass: bypass, opts: opts} do
      Bypass.expect(bypass, "POST", "/refunds/#{@invalid_transaction_id}", fn conn ->
        p_conn = parse(conn)
        params = p_conn.body_params
        assert params["amount"] == "4200"
        Conn.resp(conn, 200, Mock.refund_bad_transaction())
      end)

      {:error, response} = Gateway.refund(@amount_42, @invalid_transaction_id, config: opts)
      assert response.reason == "Transaction not found"
      assert response.status_code == 200
    end
  end

  describe "void" do
    test "when preauthorization is valid", %{bypass: bypass, opts: opts} do
      Bypass.expect(bypass, "DELETE", "/preauthorizations/#{@void_id}", fn conn ->
        Conn.resp(conn, 200, Mock.void_success())
      end)

      {:ok, response} = Gateway.void(@void_id, config: opts)
      assert response.gateway_code == 50810
    end

    test "when preauthorization used before", %{bypass: bypass, opts: opts} do
      Bypass.expect(bypass, "DELETE", "/preauthorizations/#{@void_id}", fn conn ->
        Conn.resp(conn, 200, Mock.void_done_before())
      end)

      {:error, response} = Gateway.void(@void_id, config: opts)
      assert response.reason == "Preauthorization was not found"
      assert response.status_code == 200
    end
  end

  def parse(conn, opts \\ []) do
    opts = Keyword.put_new(opts, :parsers, [Parsers.URLENCODED])
    Parsers.call(conn, Parsers.init(opts))
  end
end
