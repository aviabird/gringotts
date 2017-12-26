defmodule Gringotts.Gateways.TrexleTest do
  
  Code.require_file "../mocks/trexle_mock.exs", __DIR__
  use ExUnit.Case, async: false
  alias Gringotts.Gateways.TrexleMock, as: MockResponse
  alias Gringotts.Gateways.Trexle
  
  import Mock

  @valid_card %{
    name: "John Doe",
    number: "5200828282828210",
    expiry_month: 1,
    expiry_year: 2018,
    cvc:  "123",
    address_line1: "456 My Street",
    address_city: "Ottawa",
    address_postcode: "K1C2N6",
    address_state: "ON",
    address_country: "CA"
  }

  @invalid_card %{
    name: "John Doe",
    number: "5200828282828210",
    expiry_month: 1,
    expiry_year: 2010,
    cvc:  "123",
    address_line1: "456 My Street",
    address_city: "Ottawa",
    address_postcode: "K1C2N6",
    address_state: "ON",
    address_country: "CA"
  }

  @amount 100
  @bad_amount 20

  @valid_token "J5RGMpDlFlTfv9mEFvNWYoqHufyukPP4"
  @invalid_token "30"

  @opts [
    config: %{api_key: "J5RGMpDlFlTfv9mEFvNWYoqHufyukPP4",default_currency: "usd"}, 
    email: "john@trexle.com",
    ip_address: "66.249.79.118", 
    description: "Store Purchase 1437598192"
  ]

  @invalid_opts [
    config: %{api_key: "J5RGMpDlFlTfv9mEFvNWYoqHufyukPP4"}, 
    email: "john@trexle.com",
    ip_address: "66.249.79.118", 
    description: "Store Purchase 1437598192"
  ]

  describe "validation arguments check" do
    test "with no currency passed in config" do              
      assert_raise ArgumentError,fn ->
        Trexle.validate_config(@invalid_opts)    
      end
    end
  end

  describe "purchase" do
    test "with valid card" do
      with_mock HTTPoison, 
        [request!: fn(_method, _url, _body, _headers,_options) -> MockResponse.test_for_purchase_with_valid_card end] do
          {:ok, response} = Trexle.purchase(@amount, @valid_card, @opts)
          assert response.status_code == 201
      end
    end  

    test "with invalid card" do
      with_mock HTTPoison,
      [request!: fn(_method, _url, _body, _headers, _options) -> MockResponse.test_for_purchase_with_invalid_card end] do
        {:error, response} = Trexle.purchase(@amount, @invalid_card, @opts)  
        assert response.status_code == 400
      end
    end

    test "with invalid amount" do
      with_mock HTTPoison,
      [request!: fn(_method, _url, _body, _headers, _options) -> MockResponse.test_for_purchase_with_invalid_amount end] do
        {:error, response} = Trexle.purchase(@bad_amount, @valid_card, @opts)  
        assert response.status_code == 400
      end
    end
  end 

  describe "authorize" do
    test "with valid card" do
      with_mock HTTPoison,
      [request!: fn(_method, _url, _body, _headers, _options) -> MockResponse.test_for_authorize_with_valid_card end] do
        {:ok, response} = Trexle.authorize(@amount, @invalid_card, @opts)  
        assert response.status_code == 201
      end
    end

    test "with invalid card" do
      with_mock HTTPoison,
      [request!: fn(_method, _url, _body, _headers, _options) -> MockResponse.test_for_authorize_with_invalid_card end] do
        {:error, response} = Trexle.authorize(@amount, @invalid_card, @opts)  
        assert response.status_code == 400
      end
    end

    test "with invalid amount" do
      with_mock HTTPoison,
      [request!: fn(_method, _url, _body, _headers, _options) -> MockResponse.test_for_authorize_with_invalid_amount end] do
        {:error, response} = Trexle.authorize(@amount, @valid_card, @opts)  
        assert response.status_code == 400
      end
    end
  end

  describe "refund" do
    test "with valid token" do
      with_mock HTTPoison,
      [request!: fn(_method, _url, _body, _headers, _options) -> MockResponse.test_for_authorize_with_valid_card end] do
        {:ok, response} = Trexle.refund(@amount, @valid_token, @opts)  
        assert response.status_code == 201
      end
    end

    test "with invalid token" do
      with_mock HTTPoison,
      [request!: fn(_method, _url, _body, _headers, _options) -> MockResponse.test_for_authorize_with_invalid_amount end] do
        {:error, response} = Trexle.refund(@amount, @invalid_token, @opts)  
        assert response.status_code == 400
      end
    end
  end

  describe "capture" do
    test "with valid chargetoken" do
      with_mock HTTPoison,
      [request!: fn(_method, _url, _body, _headers, _options) -> MockResponse.test_for_capture_with_valid_chargetoken end] do
        {:ok, response} = Trexle.capture(@valid_token, @amount, @opts)  
        assert response.status_code == 200
      end
    end

    test "test_for_capture_with_invalid_chargetoken" do
     with_mock HTTPoison,
     [request!: fn(_method, _url, _body, _headers, _options) -> MockResponse.test_for_capture_with_invalid_chargetoken end] do
       {:error, response} = Trexle.capture(@invalid_token, @amount, @opts)  
       assert response.status_code == 400
     end
    end
  end

  describe "store" do  
    test "with valid card" do
      with_mock HTTPoison,
        [request!: fn(_method, _url, _body, _headers, _options) -> MockResponse.test_for_store_with_valid_card end] do
        {:ok, response} = Trexle.store(@valid_card, @opts)  
        assert response.status_code == 201
      end  
    end
  end

end
