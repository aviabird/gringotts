defmodule Gringotts.Gateways.WePayTest do
  # The file contains mocked tests for WePay

  # We recommend using [mock][1] for this, you can place the mock responses from
  # the Gateway in `test/mocks/we_pay_mock.exs` file, which has also been
  # generated for you.
  #
  # [1]: https://github.com/jjh42/mock

  # Load the mock response file before running the tests.
  #Code.require_file("../mocks/we_pay_mock.exs", __DIR__)

  use ExUnit.Case, async: true
  alias Gringotts.Gateways.WePay, as: Gateway
  alias Plug.{Conn, Parsers}
  alias Gringotts.{
    CreditCard,Address
  }
  @amount Money.new(420, :USD)

  @store_success ~s[
{
  "credit_card_id": 337717419,
  "state": "new"
}]

@void_success ~s[%{"checkout_id": 952793410,
 "state": "cancelled"}]


  @bad_card1 %CreditCard{
    first_name: "Harry",
    last_name: "Potter",
    number: "4100000000000001",
    year: 2009,
    month: 12,
    verification_code: "123",
    brand: "VISA"
  }

  @good_card %CreditCard{
    first_name: "Harry",
    last_name: "Potter",
    number: "4200000000000000",
    year: 2029,
    month: 12,
    verification_code: "123",
    brand: "VISA"
  }

  @add %Address{
    street1: "OBH",
    street2: "AIT",
    city: "PUNE",
    region: "MH",
    country: "IN",
    postal_code: "411015",
    phone: "8007810916"
  }

  @opts [
    client_id: 113_167,
    email: "hi@hello.com",
    original_ip: "1.1.1.1",
    client_secret: "e9d1d9af6c",
    account_id: 1_145_345_748,
    short_description: "test payment",
    type: "service",
    refund_reason: "the product was defective",
    cancel_reason: "the product was defective, i don't want",
    config: [
      access_token: "STAGE_a24e062d0fc2d399412ea0ff1c1e748b04598b341769b3797d3bd207ff8cf6b2"
    ],
    address: @add
  ]

  setup do
    bypass = Bypass.open()

    auth = %{
      config: [
      access_token: "STAGE_a24e062d0fc2d399412ea0ff1c1e748b04598b341769b3797d3bd207ff8cf6b2"
    ],
      test_url: "http://localhost:#{bypass.port}",
      address: @add
    }

    {:ok, bypass: bypass, auth: auth}
  end



  describe "store" do
    test "[Store] with CreditCard", %{bypass: bypass, auth: auth} do
      Bypass.expect(bypass, "POST", "/credit_card/create/", fn conn ->
        p_conn = parse(conn)
        params = p_conn.body_params
        assert params["number"] == "4200000000000000"
        assert params["year"] == "2019"
        assert params["month"] == "12"
        assert params["verification_code"] == "123"
        Conn.resp(conn, 200, @store_success)
      end)
      
      {:ok, response} = Gateway.store(@good_card, auth)
      assert response.status_code == 200
    end

   
  end

  describe "authorize" do
    
    end

    test "[authorize] with bad CreditCard" do
      
  end

  describe "purchase" do
    
    
  end

  describe "capture" do
    
  end

  describe "Void" do
    
    test "[void] ", %{bypass: bypass, auth: auth} do
      Bypass.expect(bypass, "POST", "/checkout/cancel/", fn conn ->
        p_conn = parse(conn)
        params = p_conn.body_params
        assert params["id"] == "952793410"
        
        Conn.resp(conn, 200, @void_success)
      end)
      
      {:ok, response} = Gateway.void(952793410, auth)
      assert response.status_code == 200
    end
    
  end

  describe "Unstore" do
    
  end
  

  def parse(conn, opts \\ []) do
    opts = Keyword.put_new(opts, :parsers, [Parsers.URLENCODED])
    Parsers.call(conn, Parsers.init(opts))
  end

 
end
