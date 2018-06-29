defmodule Gringotts.Gateways.TrexleTest do
  use ExUnit.Case, async: false

  alias Gringotts.{Address, CreditCard, FakeMoney}
  alias Gringotts.Gateways.Trexle
  alias Gringotts.Money
  alias Plug.{Conn, Parsers}

  @valid_card %CreditCard{
    first_name: "Harry",
    last_name: "Potter",
    number: "4000056655665556",
    year: 2068,
    month: 12,
    verification_code: "123",
    brand: "VISA"
  }

  @invalid_card %CreditCard{
    first_name: "Harry",
    last_name: "Potter",
    number: "4000056655665556",
    year: 2010,
    month: 12,
    verification_code: "123",
    brand: "VISA"
  }

  @address %Address{
    street1: "301, Gryffindor",
    street2: "Hogwarts School of Witchcraft and Wizardry, Hogwarts Castle",
    city: "Highlands",
    region: "SL",
    country: "GB",
    postal_code: "11111",
    phone: "(555)555-5555"
  }

  # $2.99
  @amount FakeMoney.new("2.99", :USD)
  # 50 US cents, trexle does not work with amount smaller than 50 cents.
  @bad_amount FakeMoney.new("0.49", :USD)

  @valid_token "some_valid_token"
  @invalid_token "some_invalid_token"

  @auth %{api_key: "some_api_key"}
  @opts [
    config: @auth,
    email: "masterofdeath@ministryofmagic.gov",
    ip_address: "127.0.0.1",
    billing_address: @address,
    description: "For our valued customer, Mr. Potter"
  ]

  @invalid_amount_response ~s/{"error":"Payment failed","detail":"Amount must be at least 50 cents"}/
  @invalid_card_response ~s/{"error":"Payment failed","detail":"Your card's expiration year is invalid."}/
  @valid_request_response ~s/{"response":{"token":"charge_3e89c6f073606ac1efe62e76e22dd7885441dc72","success":true,"captured":false}}/
  @invalid_token_response ~s/{"error":"Capture failed","detail":"invalid token"}/
  @valid_token_response ~s/{"response":{"token":"#{@valid_token}","success":true,"captured":true,"amount":299,"status_message":"Transaction approved"}}/
  @invalid_token_response_for_refund ~s/{"error":"Refund failed","detail":"invalid token"}/
  @unauthorized_access_response ~s/{reason: "Unauthorized access.", message: "Unauthorized access", raw: ""}/

  setup do
    bypass = Bypass.open()
    opts = @opts ++ [test_url: "http://localhost:#{bypass.port}/api/v1/"]
    {:ok, bypass: bypass, opts: opts}
  end

  describe "Store" do
    test "with valid card", %{bypass: bypass, opts: opts} do
      Bypass.expect_once(bypass, "POST", "/api/v1/customers", fn conn ->
        p_conn = parse(conn)
        params = p_conn.body_params
        assert params["email"] == @opts[:email]
        assert params["ip_address"] == nil
        assert params["description"] == nil
        assert params["card"]["name"] == "#{@valid_card.first_name} #{@valid_card.last_name}"
        assert params["card"]["number"] == @valid_card.number
        assert params["card"]["address_line1"] == @address.street1
        assert params["card"]["address_city"] == @address.city
        Conn.resp(conn, 201, @invalid_token_response_for_refund)
      end)

      {:ok, response} = Trexle.store(@valid_card, opts)
      assert response.status_code == 201
    end
  end

  describe "Refund" do
    test "with invalid token.", %{bypass: bypass, opts: opts} do
      Bypass.expect_once(bypass, "POST", "/api/v1/charges/#{@invalid_token}/refunds", fn conn ->
        p_conn = parse(conn)
        params = p_conn.body_params
        {_, money, _} = Money.to_integer(@amount)
        assert params["amount"] == "#{money}"
        Conn.resp(conn, 400, @invalid_token_response_for_refund)
      end)

      {:error, response} = Trexle.refund(@amount, @invalid_token, opts)
      assert response.status_code == 400
      assert response.reason == "invalid token"
    end

    test "with valid charge token", %{bypass: bypass, opts: opts} do
      Bypass.expect_once(bypass, "POST", "/api/v1/charges/#{@valid_token}/refunds", fn conn ->
        p_conn = parse(conn)
        params = p_conn.body_params
        {_, money, _} = Money.to_integer(@amount)
        assert params["amount"] == "#{money}"
        Conn.resp(conn, 200, @valid_token_response)
      end)

      {:ok, response} = Trexle.refund(@amount, @valid_token, opts)
      assert response.status_code == 200
      assert response.id == @valid_token
      assert response.message == "Transaction approved"
    end
  end

  describe "Capture" do
    test "with invalid charge token", %{bypass: bypass, opts: opts} do
      Bypass.expect_once(bypass, "PUT", "/api/v1/charges/#{@invalid_token}/capture", fn conn ->
        p_conn = parse(conn)
        params = p_conn.body_params
        {_, money, _} = Money.to_integer(@amount)
        assert params["amount"] == "#{money}"
        Conn.resp(conn, 400, @invalid_token_response)
      end)

      {:error, response} = Trexle.capture(@invalid_token, @amount, opts)
      assert response.status_code == 400
      assert response.reason == "invalid token"
    end

    test "with valid charge token", %{bypass: bypass, opts: opts} do
      Bypass.expect_once(bypass, "PUT", "/api/v1/charges/#{@valid_token}/capture", fn conn ->
        p_conn = parse(conn)
        params = p_conn.body_params
        {_, money, _} = Money.to_integer(@amount)
        assert params["amount"] == "#{money}"
        Conn.resp(conn, 200, @valid_token_response)
      end)

      {:ok, response} = Trexle.capture(@valid_token, @amount, opts)
      assert response.status_code == 200
      assert response.id == @valid_token
      assert response.message == "Transaction approved"
    end
  end

  describe "Authorize" do
    test "with invalid amount.", %{bypass: bypass, opts: opts} do
      Bypass.expect_once(bypass, "POST", "/api/v1/charges", fn conn ->
        p_conn = parse(conn)
        params = p_conn.body_params
        assert params["capture"] == "false"
        {currency, money, _} = Money.to_integer(@bad_amount)
        assert params["amount"] == "#{money}"
        assert params["currency"] == Atom.to_string(currency)
        assert params["email"] == @opts[:email]
        assert params["ip_address"] == @opts[:ip_address]
        assert params["description"] == @opts[:description]
        assert params["card"]["name"] == "#{@valid_card.first_name} #{@valid_card.last_name}"
        assert params["card"]["number"] == @valid_card.number

        Conn.resp(conn, 400, @invalid_amount_response)
      end)

      {:error, response} = Trexle.authorize(@bad_amount, @valid_card, opts)
      assert response.status_code == 400
      assert response.reason == "Amount must be at least 50 cents"
    end

    test "with invalid card.", %{bypass: bypass, opts: opts} do
      Bypass.expect_once(bypass, "POST", "/api/v1/charges", fn conn ->
        p_conn = parse(conn)
        params = p_conn.body_params
        assert params["capture"] == "false"
        {currency, money, _} = Money.to_integer(@amount)
        assert params["amount"] == "#{money}"
        assert params["currency"] == Atom.to_string(currency)
        assert params["email"] == @opts[:email]
        assert params["ip_address"] == @opts[:ip_address]
        assert params["description"] == @opts[:description]
        assert params["card"]["name"] == "#{@invalid_card.first_name} #{@invalid_card.last_name}"
        assert params["card"]["number"] == @invalid_card.number

        Conn.resp(conn, 400, @invalid_card_response)
      end)

      {:error, response} = Trexle.authorize(@amount, @invalid_card, opts)
      assert response.status_code == 400
      assert response.reason == "Your card's expiration year is invalid."
    end

    test "when trexle is down or unreachable", %{bypass: bypass, opts: opts} do
      Bypass.down(bypass)
      {:error, response} = Trexle.authorize(@amount, @valid_card, opts)
      assert response.reason == "network related failure"
      Bypass.up(bypass)
    end

    test "when the request is valid", %{bypass: bypass, opts: opts} do
      Bypass.expect_once(bypass, "POST", "/api/v1/charges", fn conn ->
        p_conn = parse(conn)
        params = p_conn.body_params
        assert params["capture"] == "false"
        {currency, money, _} = Money.to_integer(@amount)
        assert params["amount"] == "#{money}"
        assert params["currency"] == Atom.to_string(currency)
        assert params["email"] == @opts[:email]
        assert params["ip_address"] == @opts[:ip_address]
        assert params["description"] == @opts[:description]
        assert params["card"]["name"] == "#{@valid_card.first_name} #{@valid_card.last_name}"
        assert params["card"]["number"] == @valid_card.number

        Conn.resp(conn, 200, @valid_request_response)
      end)

      {:ok, results} = Trexle.authorize(@amount, @valid_card, opts)
      assert results.id == "charge_3e89c6f073606ac1efe62e76e22dd7885441dc72"
      assert results.status_code == 200
    end

    test "with unauthorized access.", %{bypass: bypass, opts: opts} do
      Bypass.expect_once(bypass, "POST", "/api/v1/charges", fn conn ->
        Conn.resp(conn, 401, @unauthorized_access_response)
      end)

      {:error, response} = Trexle.authorize(@amount, @valid_card, opts)
      assert response.reason == "Unauthorized access."
    end
  end

  describe "Purchase" do
    test "with invalid amount.", %{bypass: bypass, opts: opts} do
      Bypass.expect_once(bypass, "POST", "/api/v1/charges", fn conn ->
        p_conn = parse(conn)
        params = p_conn.body_params
        assert params["capture"] == "true"
        {currency, money, _} = Money.to_integer(@bad_amount)
        assert params["amount"] == "#{money}"
        assert params["currency"] == Atom.to_string(currency)
        assert params["email"] == @opts[:email]
        assert params["ip_address"] == @opts[:ip_address]
        assert params["description"] == @opts[:description]
        assert params["card"]["name"] == "#{@valid_card.first_name} #{@valid_card.last_name}"
        assert params["card"]["number"] == @valid_card.number

        Conn.resp(conn, 400, @invalid_amount_response)
      end)

      {:error, response} = Trexle.purchase(@bad_amount, @valid_card, opts)
      assert response.status_code == 400
      assert response.reason == "Amount must be at least 50 cents"
    end

    test "with invalid card.", %{bypass: bypass, opts: opts} do
      Bypass.expect_once(bypass, "POST", "/api/v1/charges", fn conn ->
        p_conn = parse(conn)
        params = p_conn.body_params
        assert params["capture"] == "true"
        {currency, money, _} = Money.to_integer(@amount)
        assert params["amount"] == "#{money}"
        assert params["currency"] == Atom.to_string(currency)
        assert params["email"] == @opts[:email]
        assert params["ip_address"] == @opts[:ip_address]
        assert params["description"] == @opts[:description]
        assert params["card"]["name"] == "#{@invalid_card.first_name} #{@invalid_card.last_name}"
        assert params["card"]["number"] == @invalid_card.number

        Conn.resp(conn, 400, @invalid_card_response)
      end)

      {:error, response} = Trexle.purchase(@amount, @invalid_card, opts)
      assert response.status_code == 400
      assert response.reason == "Your card's expiration year is invalid."
    end

    test "when trexle is down or unreachable", %{bypass: bypass, opts: opts} do
      Bypass.down(bypass)
      {:error, response} = Trexle.purchase(@amount, @valid_card, opts)
      assert response.reason == "network related failure"
      Bypass.up(bypass)
    end

    test "when the request is valid", %{bypass: bypass, opts: opts} do
      Bypass.expect_once(bypass, "POST", "/api/v1/charges", fn conn ->
        p_conn = parse(conn)
        params = p_conn.body_params
        assert params["capture"] == "true"
        {currency, money, _} = Money.to_integer(@amount)
        assert params["amount"] == "#{money}"
        assert params["currency"] == Atom.to_string(currency)
        assert params["email"] == @opts[:email]
        assert params["ip_address"] == @opts[:ip_address]
        assert params["description"] == @opts[:description]
        assert params["card"]["name"] == "#{@valid_card.first_name} #{@valid_card.last_name}"
        assert params["card"]["number"] == @valid_card.number

        Conn.resp(conn, 200, @valid_request_response)
      end)

      {:ok, results} = Trexle.purchase(@amount, @valid_card, opts)
      assert results.id == "charge_3e89c6f073606ac1efe62e76e22dd7885441dc72"
      assert results.status_code == 200
    end
  end

  defp parse(conn, opts \\ []) do
    opts = Keyword.put_new(opts, :parsers, [Parsers.URLENCODED])
    Parsers.call(conn, Parsers.init(opts))
  end
end
