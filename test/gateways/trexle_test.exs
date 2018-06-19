defmodule Gringotts.Gateways.TrexleTest do
  use ExUnit.Case, async: false

  alias Gringotts.{Address, CreditCard, FakeMoney}
  alias Gringotts.Gateways.TrexleMock, as: MockResponse
  alias Gringotts.Gateways.Trexle
  alias Plug.{Conn, Parsers}

  import Mock

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

  describe "core" do
    setup do
      bypass = Bypass.open()
      opts = @opts ++ [test_url: "http://localhost:#{bypass.port}/api/v1/"]
      {:ok, bypass: bypass, opts: opts}
    end

    test "with invalid amount.", %{bypass: bypass, opts: opts} do
      Bypass.expect_once(bypass, "POST", "/api/v1/charges", fn conn ->
        p_conn = parse(conn)
        params = p_conn.body_params
        assert params["capture"] == "false"
        {currency, money, _} = Gringotts.Money.to_integer(@bad_amount)
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
        {currency, money, _} = Gringotts.Money.to_integer(@amount)
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
        {currency, money, _} = Gringotts.Money.to_integer(@amount)
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
  end

  describe "purchase" do
    test "with valid card" do
      with_mock HTTPoison,
        request: fn _method, _url, _body, _headers, _options ->
          MockResponse.test_for_purchase_with_valid_card()
        end do
        assert {:ok, _response} = Trexle.purchase(@amount, @valid_card, @opts)
      end
    end

    test "with invalid card" do
      with_mock HTTPoison,
        request: fn _method, _url, _body, _headers, _options ->
          MockResponse.test_for_purchase_with_invalid_card()
        end do
        assert {:error, response} = Trexle.purchase(@amount, @invalid_card, @opts)
        assert response.reason == "Your card's expiration year is invalid."
      end
    end

    test "with invalid amount" do
      with_mock HTTPoison,
        request: fn _method, _url, _body, _headers, _options ->
          MockResponse.test_for_purchase_with_invalid_amount()
        end do
        assert {:error, response} = Trexle.purchase(@bad_amount, @valid_card, @opts)
        assert response.status_code == 400
        assert response.reason == "Amount must be at least 50 cents"
      end
    end
  end

  describe "authorize" do
    test "with unauthorized access." do
      {:error, response} = Trexle.authorize(@amount, @valid_card, @opts)
      assert response.reason == "Unauthorized access."
    end

    test "with valid card" do
      with_mock HTTPoison,
        request: fn _method, _url, _body, _headers, _options ->
          MockResponse.test_for_authorize_with_valid_card()
        end do
        assert {:ok, response} = Trexle.authorize(@amount, @valid_card, @opts)
        assert response.status_code == 201
      end
    end
  end

  describe "refund" do
    test "with valid token" do
      with_mock HTTPoison,
        request: fn _method, _url, _body, _headers, _options ->
          MockResponse.test_for_authorize_with_valid_card()
        end do
        assert {:ok, response} = Trexle.refund(@amount, @valid_token, @opts)
        assert response.status_code == 201
      end
    end
  end

  describe "capture" do
    test "with valid charge token" do
      with_mock HTTPoison,
        request: fn _method, _url, _body, _headers, _options ->
          MockResponse.test_for_capture_with_valid_chargetoken()
        end do
        assert {:ok, response} = Trexle.capture(@valid_token, @amount, @opts)
        # Why 200 here?? It's 201 everywhere lese. Check trexle docs.
        assert response.status_code == 200
      end
    end

    test "with invalid charge token" do
      with_mock HTTPoison,
        request: fn _method, _url, _body, _headers, _options ->
          MockResponse.test_for_capture_with_invalid_chargetoken()
        end do
        assert {:error, response} = Trexle.capture(@invalid_token, @amount, @opts)
        assert response.status_code == 400
        assert response.reason == "invalid token"
      end
    end
  end

  describe "store" do
    test "with valid card" do
      with_mock HTTPoison,
        request: fn _method, _url, _body, _headers, _options ->
          MockResponse.test_for_store_with_valid_card()
        end do
        assert {:ok, response} = Trexle.store(@valid_card, @opts)
        assert response.status_code == 201
      end
    end
  end

  describe "network failure" do
    test "with authorization" do
      with_mock HTTPoison,
        request: fn _method, _url, _body, _headers, _options ->
          MockResponse.test_for_network_failure()
        end do
        {:error, response} = Trexle.authorize(@amount, @valid_card, @opts)

        assert response.message ==
                 "HTTPoison says 'some_hackney_error' [ID: some_hackney_error_id]"
      end
    end
  end

  def parse(conn, opts \\ []) do
    opts = Keyword.put_new(opts, :parsers, [Parsers.URLENCODED])
    Parsers.call(conn, Parsers.init(opts))
  end
end
