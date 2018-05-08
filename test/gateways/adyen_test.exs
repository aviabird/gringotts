defmodule Gringotts.Gateways.AdyenTest do
  use ExUnit.Case, async: true

  alias Gringotts.Gateways.Adyen, as: Gateway
  alias Plug.{Conn, Parsers}

  @amount Money.new(100, :EUR)

  @card %Gringotts.CreditCard{
    brand: "VISA",
    first_name: "John",
    last_name: "Smith",
    number: "4988438843884305",
    month: "08",
    year: "2018",
    verification_code: "737"
  }

  @invalid_card %Gringotts.CreditCard{
    brand: "VISA",
    first_name: "John",
    last_name: "Smith",
    number: "4988438843884300",
    month: "08",
    year: "2018",
    verification_code: "737"
  }
  @auth_success ~s/{"pspReference":"8835254327807747","resultCode":"Authorised","authCode":"52420"}/
  @auth_invalid ~s/{"status":422,"errorCode":"101","message":"Invalid card number","errorType":"validation","pspReference":"8815257539249826"}/
  @void_id "8815252579404498"
  @void_success ~s/{"pspReference":"8815252582789448","response":"[cancel-received]"}/
  @capture_preauth_id "8815252525121717"
  @capture_success ~s/{"pspReference":"8815252583436809","response":"[capture-received]"}/
  @capture_preauth_id_invalid "8815252525121710"
  @capture_invalid ~s/{"status":422,"errorCode":"167","message":"Original pspReference required for this operation","errorType":"validation"}/
  @refund_success_id "8815252579404498"
  @refund_success ~s/{"pspReference":"8815257649545568","response":"[refund-received]"}/
  @refund_invalid_id "8815252579404490"
  @refund_invalid ~s/{"status":422,"errorCode":"167","message":"Original pspReference required for this operation","errorType":"validation"}/

  setup do
    bypass = Bypass.open()

    opts = %{
      username: "your user name",
      password: "your password",
      account: "your account",
      url: "http://localhost:#{bypass.port}/"
    }

    {:ok, bypass: bypass, opts: opts}
  end

  describe "authorize" do
    test "when card is valid", %{bypass: bypass, opts: opts} do
      Bypass.expect(bypass, "POST", "/authorise", fn conn ->
        p_conn = parse(conn)
        params = p_conn.body_params
        assert params["card"]["cvc"] == "737"
        assert params["card"]["expiryMonth"] == "08"
        assert params["card"]["expiryYear"] == "2018"
        assert params["card"]["holderName"] == "John Smith"
        assert params["card"]["number"] == "4988438843884305"
        assert params["amount"]["value"] == 10000
        assert params["amount"]["currency"] == "EUR"
        assert params["merchantAccount"] == "your account"
        Conn.resp(conn, 200, @auth_success)
      end)

      {:ok, response} = Gateway.authorize(@amount, @card, config: opts)
      assert response.status_code == 200
      assert response.id == "8835254327807747"
      assert response.message == "Authorised"
    end

    test "when adyen is down or unreachable", %{bypass: bypass, opts: opts} do
      Bypass.down(bypass)
      {:error, response} = Gateway.authorize(@amount, @card, config: opts)
      assert response.reason == "network related failure"
      Bypass.up(bypass)
    end

    test "when card is invalid", %{bypass: bypass, opts: opts} do
      Bypass.expect(bypass, "POST", "/authorise", fn conn ->
        p_conn = parse(conn)
        params = p_conn.body_params
        assert params["card"]["cvc"] == "737"
        assert params["card"]["expiryMonth"] == "08"
        assert params["card"]["expiryYear"] == "2018"
        assert params["card"]["holderName"] == "John Smith"
        assert params["card"]["number"] == "4988438843884300"
        assert params["amount"]["value"] == 10000
        assert params["amount"]["currency"] == "EUR"
        assert params["merchantAccount"] == "your account"
        Conn.resp(conn, 422, @auth_invalid)
      end)

      {:error, response} = Gateway.authorize(@amount, @invalid_card, config: opts)
      assert response.status_code == 422
      assert response.message == "Invalid card number"
    end
  end

  describe "capture" do
    test "when authorise is valid", %{bypass: bypass, opts: opts} do
      Bypass.expect(bypass, "POST", "/capture", fn conn ->
        p_conn = parse(conn)
        params = p_conn.body_params
        assert params["modificationAmount"]["value"] == 10000
        assert params["modificationAmount"]["currency"] == "EUR"
        assert params["merchantAccount"] == "your account"
        Conn.resp(conn, 200, @capture_success)
      end)

      {:ok, response} = Gateway.capture(@capture_preauth_id, @amount, config: opts)
      assert response.id == "8815252583436809"
      assert response.message == "[capture-received]"
      assert response.status_code == 200
    end

    test "capture when adyen is down or unreachable", %{bypass: bypass, opts: opts} do
      Bypass.down(bypass)
      {:error, response} = Gateway.capture(@capture_preauth_id, @amount, config: opts)
      assert response.reason == "network related failure"
      Bypass.up(bypass)
    end

    test "when authorise not found", %{bypass: bypass, opts: opts} do
      Bypass.expect(bypass, "POST", "/capture", fn conn ->
        p_conn = parse(conn)
        params = p_conn.body_params
        assert params["modificationAmount"]["value"] == 10000
        assert params["modificationAmount"]["currency"] == "EUR"
        assert params["merchantAccount"] == "your account"
        Conn.resp(conn, 422, @capture_invalid)
      end)

      {:error, response} = Gateway.capture(@capture_preauth_id_invalid, @amount, config: opts)
      assert response.message == "Original pspReference required for this operation"
      assert response.status_code == 422
    end
  end

  describe "purchase" do
    test "when card is valid", %{bypass: bypass, opts: opts} do
      Bypass.expect(bypass, "POST", "/authorise", fn conn ->
        p_conn = parse(conn)
        params = p_conn.body_params
        assert params["card"]["cvc"] == "737"
        assert params["card"]["expiryMonth"] == "08"
        assert params["card"]["expiryYear"] == "2018"
        assert params["card"]["holderName"] == "John Smith"
        assert params["card"]["number"] == "4988438843884305"
        assert params["amount"]["value"] == 10000
        assert params["amount"]["currency"] == "EUR"
        assert params["merchantAccount"] == "your account"
        Conn.resp(conn, 200, @auth_success)
      end)

      Bypass.expect(bypass, "POST", "/capture", fn conn ->
        p_conn = parse(conn)
        params = p_conn.body_params
        assert params["modificationAmount"]["value"] == 10000
        assert params["modificationAmount"]["currency"] == "EUR"
        assert params["merchantAccount"] == "your account"
        Conn.resp(conn, 200, @capture_success)
      end)

      {:ok, response} = Gateway.purchase(@amount, @card, config: opts)
      assert response.id == "8815252583436809"
      assert response.message == "[capture-received]"
      assert response.status_code == 200
    end

    test "purchase when adyen is down or unreachable", %{bypass: bypass, opts: opts} do
      Bypass.down(bypass)
      {:error, response} = Gateway.purchase(@amount, @card, config: opts)
      assert response.reason == "network related failure"
      Bypass.up(bypass)
    end

    test "when card is invalid", %{bypass: bypass, opts: opts} do
      Bypass.expect(bypass, "POST", "/authorise", fn conn ->
        p_conn = parse(conn)
        params = p_conn.body_params
        assert params["card"]["cvc"] == "737"
        assert params["card"]["expiryMonth"] == "08"
        assert params["card"]["expiryYear"] == "2018"
        assert params["card"]["holderName"] == "John Smith"
        assert params["card"]["number"] == "4988438843884300"
        assert params["amount"]["value"] == 10000
        assert params["amount"]["currency"] == "EUR"
        assert params["merchantAccount"] == "your account"
        Conn.resp(conn, 422, @auth_invalid)
      end)

      {:error, response} = Gateway.purchase(@amount, @invalid_card, config: opts)
      assert response.status_code == 422
      assert response.message == "Invalid card number"
    end
  end

  describe "refund" do
    test "when transaction is valid", %{bypass: bypass, opts: opts} do
      Bypass.expect(bypass, "POST", "/refund", fn conn ->
        p_conn = parse(conn)
        params = p_conn.body_params
        assert params["modificationAmount"]["value"] == 10000
        assert params["modificationAmount"]["currency"] == "EUR"
        assert params["merchantAccount"] == "your account"
        assert params["originalReference"] == "8815252579404498"
        Conn.resp(conn, 200, @refund_success)
      end)

      {:ok, response} = Gateway.refund(@amount, @refund_success_id, config: opts)
      assert response.status_code == 200
    end

    test "refund when adyen is down or unreachable", %{bypass: bypass, opts: opts} do
      Bypass.down(bypass)
      {:error, response} = Gateway.refund(@amount, @refund_success_id, config: opts)
      assert response.reason == "network related failure"
      Bypass.up(bypass)
    end

    test "when transaction not found", %{bypass: bypass, opts: opts} do
      Bypass.expect(bypass, "POST", "/refund", fn conn ->
        p_conn = parse(conn)
        params = p_conn.body_params
        assert params["modificationAmount"]["value"] == 10000
        assert params["modificationAmount"]["currency"] == "EUR"
        assert params["merchantAccount"] == "your account"
        assert params["originalReference"] == "8815252579404490"
        Conn.resp(conn, 422, @refund_invalid)
      end)

      {:error, response} = Gateway.refund(@amount, @refund_invalid_id, config: opts)
      assert response.status_code == 422
    end
  end

  describe "void" do
    test "when authorise is valid", %{bypass: bypass, opts: opts} do
      Bypass.expect(bypass, "POST", "/cancel", fn conn ->
        p_conn = parse(conn)
        params = p_conn.body_params
        assert params["merchantAccount"] == "your account"
        assert params["originalReference"] == "8815252579404498"
        Conn.resp(conn, 200, @void_success)
      end)

      {:ok, response} = Gateway.void(@void_id, config: opts)
      assert response.status_code == 200
      assert response.message == "[cancel-received]"
      assert response.id == "8815252582789448"
    end

    test "void when adyen is down or unreachable", %{bypass: bypass, opts: opts} do
      Bypass.down(bypass)
      {:error, response} = Gateway.void(@void_id, config: opts)
      assert response.reason == "network related failure"
      Bypass.up(bypass)
    end
  end

  def parse(conn, opts \\ []) do
    opts = Keyword.put_new(opts, :parsers, [Parsers.JSON])
    opts = Keyword.put_new(opts, :json_decoder, Poison)
    Parsers.call(conn, Parsers.init(opts))
  end
end
