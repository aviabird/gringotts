defmodule Gringotts.Gateways.PaymillTest do
  use ExUnit.Case, async: true

  alias Gringotts.{CreditCard, Response}
  alias Gringotts.Gateways.Paymill, as: Gateway
  alias Plug.{Conn, Parsers}

  setup do
    bypass = Bypass.open()

    opts = %{
      private_key: "merchant_secret_key",
      public_key: "merchant_public_key",
      test_url: "http://localhost:#{bypass.port}/",
      mode: "CONNECTOR_TEST"
    }

    {:ok, bypass: bypass, opts: opts}
  end

  @amount Money.new(10, :USD)
  @amount_4200 Money.new(4200, :EUR)
  @big_amount Money.new(100, :USD)
  @valid_token "tok_d26e611c47d64693a281e8411934"
  @invalid_token "tok_d26e611c47d64693a281e841193"
  @refn_tran_id "tran_de77d38b85d6eee2984accc8b2cc"
  @refn_tran_id_invalid "tran_023d3b5769321c649435"
  @capt_preauth_id "preauth_d654694c8116109af903"
  @capt_preauth_invalid_id "preauth_d654694c8116109af90"
  @capt_preauth_used_id "preauth_d654694c8116109af903"
  @void_success_id "preauth_0bfc975c2858980a6023"

  @auth_success ~s/{ "data":{ "id":"preauth_7f0a5b2787d0acb96db5", "amount":"4200", "currency":"EUR", "description":"description example", "status":"closed", "livemode":false, "created_at":1523890381, "updated_at":1523890383, "app_id":null, "payment":{ "id":"pay_abdd833557398641e9dfcc47", "type":"creditcard", "client":"client_d8b9c9a37b0ecb1bbd83", "card_type":"mastercard", "country":"DE", "expire_month":"12", "expire_year":"2018", "card_holder":"Harry Potter", "last4":"0004", "updated_at":1522922164, "created_at":1522922164, "app_id":null, "is_recurring":true, "is_usable_for_preauthorization":true }, "client":{ "id":"client_d8b9c9a37b0ecb1bbd83", "email":null, "description":null, "app_id":null, "updated_at":1522922164, "created_at":1522922164, "payment":[ "pay_abdd833557398641e9dfcc47" ], "subscription":null }, "transaction":{ "id":"tran_7341c475993e3ddbbff801c47597", "amount":4200, "origin_amount":4200, "status":"preauth", "description":"description example", "livemode":false, "refunds":null, "client":"client_d8b9c9a37b0ecb1bbd83", "currency":"EUR", "created_at":1523890381, "updated_at":1523890383, "response_code":20000, "short_id":null, "is_fraud":false, "invoices":[ ], "app_id":null, "preauthorization":"preauth_7f0a5b2787d0acb96db5", "fees":[ ], "payment":"pay_abdd833557398641e9dfcc47", "mandate_reference":null, "is_refundable":false, "is_markable_as_fraud":true } }, "mode":"test" }/
  @auth_or_purch_invlid_token ~s/{ "error":{ "messages":{ "regexNotMatch":"'tok_d26e611c47d64693a281e841193' does not match against pattern '\/^[a-zA-Z0-9_]{32}$\/'" }, "field":"token" } }/
  @purc_valid_token ~s/{ "data":{ "id":"tran_de77d38b85d6eee2984accc8b2cc", "amount":4200, "origin_amount":4200, "status":"closed", "description":"", "livemode":false, "refunds":null, "client":{ "id":"client_d8b9c9a37b0ecb1bbd83", "email":null, "description":null, "app_id":null, "updated_at":1522922164, "created_at":1522922164, "payment":[ "pay_abdd833557398641e9dfcc47" ], "subscription":null }, "currency":"EUR", "created_at":1524135111, "updated_at":1524135111, "response_code":20000, "short_id":"0000.9999.0000", "is_fraud":false, "invoices":[ ], "app_id":null, "preauthorization":null, "fees":[ ], "payment":{ "id":"pay_abdd833557398641e9dfcc47", "type":"creditcard", "client":"client_d8b9c9a37b0ecb1bbd83", "card_type":"mastercard", "country":"DE", "expire_month":"12", "expire_year":"2018", "card_holder":"Sagar Karwande", "last4":"0004", "updated_at":1522922164, "created_at":1522922164, "app_id":null, "is_recurring":true, "is_usable_for_preauthorization":true }, "mandate_reference":null, "is_refundable":true, "is_markable_as_fraud":true }, "mode":"test" }/
  @refn_success ~s/{ "data":{ "id":"refund_96a0c66456a55ba3e746", "amount":4200, "status":"refunded", "description":null, "livemode":false, "created_at":1524138133, "updated_at":1524138133, "short_id":"0000.9999.0000", "response_code":20000, "reason":null, "app_id":null, "transaction":{ "id":"tran_de77d38b85d6eee2984accc8b2cc", "amount":0, "origin_amount":4200, "status":"refunded", "description":"", "livemode":false, "refunds":[ "refund_96a0c66456a55ba3e746" ], "client":"client_d8b9c9a37b0ecb1bbd83", "currency":"EUR", "created_at":1524135111, "updated_at":1524138134, "response_code":20000, "short_id":"0000.9999.0000", "is_fraud":false, "invoices":[ ], "app_id":null, "preauthorization":null, "fees":[ ], "payment":"pay_abdd833557398641e9dfcc47", "mandate_reference":null, "is_refundable":false, "is_markable_as_fraud":true } }, "mode":"test" }/
  @refn_again ~s/{ "exception":"refund_amount_to_high", "error":"Amount to high" }/
  @refn_trans_not_found ~s/{ "exception":"transaction_not_found", "error":"Transaction not found" }/
  @capt_success ~s/{ "data":{ "id":"tran_2f46c44c4d5219e4ef4b7c6292ba", "amount":4200, "origin_amount":4200, "status":"closed", "description":"", "livemode":false, "refunds":null, "client":{ "id":"client_d8b9c9a37b0ecb1bbd83", "email":null, "description":null, "app_id":null, "updated_at":1522922164, "created_at":1522922164, "payment":[ "pay_abdd833557398641e9dfcc47" ], "subscription":null }, "currency":"EUR", "created_at":1524138666, "updated_at":1524138699, "response_code":20000, "short_id":"0000.9999.0000", "is_fraud":false, "invoices":[ ], "app_id":null, "preauthorization":{ "id":"preauth_d654694c8116109af903", "amount":"4200", "currency":"EUR", "description":"description example", "status":"closed", "livemode":false, "created_at":1524138666, "updated_at":1524138669, "app_id":null, "payment":"pay_abdd833557398641e9dfcc47", "client":"client_d8b9c9a37b0ecb1bbd83", "transaction":"tran_2f46c44c4d5219e4ef4b7c6292ba" }, "fees":[ ], "payment":{ "id":"pay_abdd833557398641e9dfcc47", "type":"creditcard", "client":"client_d8b9c9a37b0ecb1bbd83", "card_type":"mastercard", "country":"DE", "expire_month":"12", "expire_year":"2018", "card_holder":"Sagar Karwande", "last4":"0004", "updated_at":1522922164, "created_at":1522922164, "app_id":null, "is_recurring":true, "is_usable_for_preauthorization":true }, "mandate_reference":null, "is_refundable":true, "is_markable_as_fraud":true }, "mode":"test" }/
  @capt_preauth_not_found ~s/{ "exception":"not_found_transaction_preauthorize", "error":"Preauthorize not found" }/
  @capt_preauth_done_before ~s/{ "exception":"preauthorization_already_used", "error":"Preauthorization has already been used" }/
  @void_success ~s/{ "data":{ "id":"preauth_0bfc975c2858980a6023", "amount":"4200", "currency":"EUR", "description":"description example", "status":"deleted", "livemode":false, "created_at":1524140381, "updated_at":1524140479, "app_id":null, "payment":{ "id":"pay_abdd833557398641e9dfcc47", "type":"creditcard", "client":"client_d8b9c9a37b0ecb1bbd83", "card_type":"mastercard", "country":"DE", "expire_month":"12", "expire_year":"2018", "card_holder":"Sagar Karwande", "last4":"0004", "updated_at":1522922164, "created_at":1522922164, "app_id":null, "is_recurring":true, "is_usable_for_preauthorization":true }, "client":{ "id":"client_d8b9c9a37b0ecb1bbd83", "email":null, "description":null, "app_id":null, "updated_at":1522922164, "created_at":1522922164, "payment":[ "pay_abdd833557398641e9dfcc47" ], "subscription":null }, "transaction":{ "id":"tran_f360d805dce7f84baf07077a7f96", "amount":4200, "origin_amount":4200, "status":"failed", "description":"description example", "livemode":false, "refunds":null, "client":"client_d8b9c9a37b0ecb1bbd83", "currency":"EUR", "created_at":1524140381, "updated_at":1524140479, "response_code":50810, "short_id":null, "is_fraud":false, "invoices":[ ], "app_id":null, "preauthorization":"preauth_0bfc975c2858980a6023", "fees":[ ], "payment":"pay_abdd833557398641e9dfcc47", "mandate_reference":null, "is_refundable":false, "is_markable_as_fraud":true } }, "mode":"test" }/
  @void_done_before ~s/{ "exception":"preauthorization_not_found", "error":"Preauthorization was not found" }/

  describe "authorize" do
    test "when token is valid", %{bypass: bypass, opts: opts} do
      Bypass.expect(bypass, "POST", "/preauthorizations", fn conn ->
        p_conn = parse(conn)
        params = p_conn.body_params
        assert params["amount"] == "420000"
        assert params["currency"] == "EUR"
        assert params["token"] == "tok_d26e611c47d64693a281e8411934"
        Conn.resp(conn, 200, @auth_success)
      end)

      {:ok, response} = Gateway.authorize(@amount_4200, @valid_token, config: opts)
      assert response.gateway_code == 20000
    end

    test "when paymill is down or unreachable", %{bypass: bypass, opts: opts} do
      Bypass.down(bypass)
      {:error, response} = Gateway.authorize(@amount_4200, @valid_token, config: opts)
      assert response.reason == "econnrefused"
      Bypass.up(bypass)
    end

    test "when token is invalid", %{bypass: bypass, opts: opts} do
      Bypass.expect(bypass, "POST", "/preauthorizations", fn conn ->
        p_conn = parse(conn)
        params = p_conn.body_params
        assert params["amount"] == "420000"
        assert params["currency"] == "EUR"
        assert params["token"] == "tok_d26e611c47d64693a281e841193"
        Conn.resp(conn, 400, @auth_or_purch_invlid_token)
      end)

      {:ok, response} = Gateway.authorize(@amount_4200, @invalid_token, config: opts)
      assert response.status_code == 400
    end
  end

  describe "capture" do
    test "when preauthorization is valid", %{bypass: bypass, opts: opts} do
      Bypass.expect(bypass, "POST", "/transactions", fn conn ->
        p_conn = parse(conn)
        params = p_conn.body_params
        assert params["amount"] == "420000"
        assert params["currency"] == "EUR"
        assert params["preauthorization"] == "preauth_d654694c8116109af903"
        Conn.resp(conn, 200, @capt_success)
      end)

      {:ok, response} = Gateway.capture(@capt_preauth_id, @amount_4200, config: opts)
      assert response.gateway_code == 20000
    end

    test "when paymill is down or unreachable", %{bypass: bypass, opts: opts} do
      Bypass.down(bypass)
      {:error, response} = Gateway.capture(@capt_preauth_id, @amount_4200, config: opts)
      assert response.reason == "econnrefused"
      Bypass.up(bypass)
    end

    test "when preauthorization not found", %{bypass: bypass, opts: opts} do
      Bypass.expect(bypass, "POST", "/transactions", fn conn ->
        p_conn = parse(conn)
        params = p_conn.body_params
        assert params["amount"] == "420000"
        assert params["currency"] == "EUR"
        assert params["preauthorization"] == "preauth_d654694c8116109af903"
        Conn.resp(conn, 200, @capt_preauth_not_found)
      end)

      {:ok, response} = Gateway.capture(@capt_preauth_id, @amount_4200, config: opts)
      assert response.status_code == 200
      assert response.reason == "Preauthorize not found"
    end

    test "when preauthorization done before", %{bypass: bypass, opts: opts} do
      Bypass.expect(bypass, "POST", "/transactions", fn conn ->
        p_conn = parse(conn)
        params = p_conn.body_params
        assert params["amount"] == "420000"
        assert params["currency"] == "EUR"
        assert params["preauthorization"] == "preauth_d654694c8116109af903"
        Conn.resp(conn, 200, @capt_preauth_done_before)
      end)

      {:ok, response} = Gateway.capture(@capt_preauth_id, @amount_4200, config: opts)
      assert response.status_code == 200
      assert response.reason == "Preauthorization has already been used"
    end
  end

  describe "purchase" do
    test "when token is valid", %{bypass: bypass, opts: opts} do
      Bypass.expect(bypass, "POST", "/transactions", fn conn ->
        p_conn = parse(conn)
        params = p_conn.body_params
        assert params["amount"] == "420000"
        assert params["currency"] == "EUR"
        assert params["token"] == "tok_d26e611c47d64693a281e841193"
        Conn.resp(conn, 200, @purc_valid_token)
      end)

      {:ok, response} = Gateway.purchase(@amount_4200, @invalid_token, config: opts)
      assert response.gateway_code == 20000
      assert response.fraud_review == true
      assert response.status_code == 200
    end

    test "when paymill is down or unreachable", %{bypass: bypass, opts: opts} do
      Bypass.down(bypass)
      {:error, response} = Gateway.purchase(@amount_4200, @invalid_token, config: opts)
      assert response.reason == "econnrefused"
      Bypass.up(bypass)
    end

    test "when token is invalid", %{bypass: bypass, opts: opts} do
      Bypass.expect(bypass, "POST", "/transactions", fn conn ->
        p_conn = parse(conn)
        params = p_conn.body_params
        assert params["amount"] == "420000"
        assert params["currency"] == "EUR"
        assert params["token"] == "tok_d26e611c47d64693a281e841193"
        Conn.resp(conn, 200, @auth_or_purch_invlid_token)
      end)

      {:ok, response} = Gateway.purchase(@amount_4200, @invalid_token, config: opts)
      assert response.reason["field"] == "token"

      assert response.reason["messages"]["regexNotMatch"] ==
               "'tok_d26e611c47d64693a281e841193' does not match against pattern '\/^[a-zA-Z0-9_]{32}$\/'"

      assert response.status_code == 200
    end
  end

  describe "refund" do
    test "when transaction is valid", %{bypass: bypass, opts: opts} do
      Bypass.expect(bypass, "POST", "/refunds/#{@refn_tran_id}", fn conn ->
        p_conn = parse(conn)
        params = p_conn.body_params
        assert params["amount"] == "420000"
        Conn.resp(conn, 200, @refn_success)
      end)

      {:ok, response} = Gateway.refund(@amount_4200, @refn_tran_id, config: opts)
      assert response.gateway_code == 20000
      assert response.status_code == 200
    end

    test "when paymill is down or unreachable", %{bypass: bypass, opts: opts} do
      Bypass.down(bypass)
      {:error, response} = Gateway.refund(@amount_4200, @refn_tran_id, config: opts)
      assert response.reason == "econnrefused"
      Bypass.up(bypass)
    end

    test "when transaction is used again", %{bypass: bypass, opts: opts} do
      Bypass.expect(bypass, "POST", "/refunds/#{@refn_tran_id}", fn conn ->
        p_conn = parse(conn)
        params = p_conn.body_params
        assert params["amount"] == "420000"
        Conn.resp(conn, 200, @refn_again)
      end)

      {:ok, response} = Gateway.refund(@amount_4200, @refn_tran_id, config: opts)
      assert response.reason == "Amount to high"
      assert response.status_code == 200
    end

    test "when transaction not found", %{bypass: bypass, opts: opts} do
      Bypass.expect(bypass, "POST", "/refunds/#{@refn_tran_id_invalid}", fn conn ->
        p_conn = parse(conn)
        params = p_conn.body_params
        assert params["amount"] == "420000"
        Conn.resp(conn, 200, @refn_trans_not_found)
      end)

      {:ok, response} = Gateway.refund(@amount_4200, @refn_tran_id_invalid, config: opts)
      assert response.reason == "Transaction not found"
      assert response.status_code == 200
    end
  end

  describe "void" do
    test "when preauthorization is valid", %{bypass: bypass, opts: opts} do
      Bypass.expect(bypass, "DELETE", "/preauthorizations/#{@void_success_id}", fn conn ->
        p_conn = parse(conn)
        params = p_conn.body_params
        Conn.resp(conn, 200, @void_success)
      end)

      {:ok, response} = Gateway.void(@void_success_id, config: opts)
      assert response.gateway_code == 50810
    end

    test "when paymill is down or unreachable", %{bypass: bypass, opts: opts} do
      Bypass.down(bypass)
      {:error, response} = Gateway.void(@void_success_id, config: opts)
      assert response.reason == "econnrefused"
      Bypass.up(bypass)
    end

    test "when preauthorization used before", %{bypass: bypass, opts: opts} do
      Bypass.expect(bypass, "DELETE", "/preauthorizations/#{@void_success_id}", fn conn ->
        p_conn = parse(conn)
        params = p_conn.body_params
        Conn.resp(conn, 200, @void_done_before)
      end)

      {:ok, response} = Gateway.void(@void_success_id, config: opts)
      assert response.reason == "Preauthorization was not found"
      assert response.status_code == 200
    end
  end

  def parse(conn, opts \\ []) do
    opts = Keyword.put_new(opts, :parsers, [Parsers.URLENCODED])
    Parsers.call(conn, Parsers.init(opts))
  end
end
