defmodule Gringotts.Gateways.GlobalCollectTest do
  Code.require_file("../mocks/global_collect_mock.exs", __DIR__)
  use ExUnit.Case, async: false
  alias Gringotts.Gateways.GlobalCollectMock, as: MockResponse
  alias Gringotts.Gateways.GlobalCollect

  alias Gringotts.{
    CreditCard
  }

  import Mock

  @amount Money.new("500", :USD)

  @bad_amount Money.new("50.3", :USD)

  @shipping_address %{
    street: "Desertroad",
    houseNumber: "1",
    additionalInfo: "Suite II",
    zip: "84536",
    city: "Monument Valley",
    state: "Utah",
    countryCode: "US"
  }

  @valid_card %CreditCard{
    number: "4567350000427977",
    month: 12,
    year: 18,
    first_name: "John",
    last_name: "Doe",
    verification_code: "123",
    brand: "VISA"
  }

  @invalid_card %CreditCard{
    number: "4567350000427977",
    month: 12,
    year: 10,
    first_name: "John",
    last_name: "Doe",
    verification_code: "123",
    brand: "VISA"
  }

  @billing_address %{
    street: "Desertroad",
    houseNumber: "13",
    additionalInfo: "b",
    zip: "84536",
    city: "Monument Valley",
    state: "Utah",
    countryCode: "US"
  }

  @invoice %{
    invoiceNumber: "000000123",
    invoiceDate: "20140306191500"
  }

  @name %{
    title: "Miss",
    firstName: "Road",
    surname: "Runner"
  }

  @valid_token "charge_cb17a0c34e870a479dfa13bd873e7ce7e090ec9b"

  @invalid_token 30

  @options [
    config: %{
      secret_api_key: "some_secret_api_key",
      api_key_id: "some_api_key_id",
      merchant_id: "some_merchant_id"
    },
    description: "Store Purchase 1437598192",
    merchantCustomerId: "234",
    customer_name: "John Doe",
    dob: "19490917",
    company: "asma",
    email: "johndoe@gmail.com",
    phone: "7468474533",
    order_id: "2323",
    invoice: @invoice,
    billingAddress: @billing_address,
    shippingAddress: @shipping_address,
    name: @name,
    skipAuthentication: "true"
  ]

  describe "purchase" do
    test "with valid card" do
      with_mock HTTPoison,
        request: fn _method, _url, _body, _headers ->
          MockResponse.test_for_purchase_with_valid_card()
        end do
        {:ok, response} = GlobalCollect.purchase(@amount, @valid_card, @options)
        assert response.status_code == 201
        assert response.success == true
        assert response.raw["payment"]["statusOutput"]["isAuthorized"] == true
      end
    end

    test "with invalid amount" do
      with_mock HTTPoison,
        request: fn _method, _url, _body, _headers ->
          MockResponse.test_for_purchase_with_invalid_amount()
        end do
        {:error, response} = GlobalCollect.purchase(@bad_amount, @valid_card, @options)
        assert response.status_code == 400
        assert response.success == false
        assert response.message == "INVALID_VALUE: '50.3' is not a valid value for field 'amount'"
      end
    end
  end

  describe "authorize" do
    test "with valid card" do
      with_mock HTTPoison,
        request: fn _method, _url, _body, _headers ->
          MockResponse.test_for_authorize_with_valid_card()
        end do
        {:ok, response} = GlobalCollect.authorize(@amount, @valid_card, @options)
        assert response.status_code == 201
        assert response.success == true
        assert response.raw["payment"]["statusOutput"]["isAuthorized"] == true
      end
    end

    test "with invalid card" do
      with_mock HTTPoison,
        request: fn _method, _url, _body, _headers ->
          MockResponse.test_for_authorize_with_invalid_card()
        end do
        {:error, response} = GlobalCollect.authorize(@amount, @invalid_card, @options)
        assert response.status_code == 400
        assert response.success == false

        assert response.message ==
                 "cardPaymentMethodSpecificInput.card.expiryDate (1210) IS IN THE PAST OR NOT IN CORRECT MMYY FORMAT"
      end
    end

    test "with invalid amount" do
      with_mock HTTPoison,
        request: fn _method, _url, _body, _headers ->
          MockResponse.test_for_authorize_with_invalid_amount()
        end do
        {:error, response} = GlobalCollect.authorize(@bad_amount, @valid_card, @options)
        assert response.status_code == 400
        assert response.success == false
        assert response.message == "INVALID_VALUE: '50.3' is not a valid value for field 'amount'"
      end
    end
  end

  describe "refund" do
    test "with refund not enabled for the respective account" do
      with_mock HTTPoison,
        request: fn _method, _url, _body, _headers -> MockResponse.test_for_refund() end do
        {:error, response} = GlobalCollect.refund(@amount, @valid_token, @options)
        assert response.status_code == 400
        assert response.success == false
        assert response.message == "ORDER WITHOUT REFUNDABLE PAYMENTS"
      end
    end
  end

  describe "capture" do
    test "with valid payment id" do
      with_mock HTTPoison,
        request: fn _method, _url, _body, _headers ->
          MockResponse.test_for_capture_with_valid_paymentid()
        end do
        {:ok, response} = GlobalCollect.capture(@valid_token, @amount, @options)
        assert response.status_code == 200
        assert response.success == true
        assert response.raw["payment"]["status"] == "CAPTURE_REQUESTED"
      end
    end

    test "with invalid payment id" do
      with_mock HTTPoison,
        request: fn _method, _url, _body, _headers ->
          MockResponse.test_for_capture_with_invalid_paymentid()
        end do
        {:error, response} = GlobalCollect.capture(@invalid_token, @amount, @options)
        assert response.status_code == 404
        assert response.success == false
        assert response.message == "UNKNOWN_PAYMENT_ID"
      end
    end
  end

  describe "void" do
    test "with valid card" do
      with_mock HTTPoison,
        request: fn _method, _url, _body, _headers ->
          MockResponse.test_for_void_with_valid_card()
        end do
        {:ok, response} = GlobalCollect.void(@valid_token, @options)
        assert response.status_code == 200
        assert response.raw["payment"]["status"] == "CANCELLED"
      end
    end
  end

  describe "network failure" do
    test "with authorization" do
      with_mock HTTPoison,
        request: fn _method, _url, _body, _headers -> MockResponse.test_for_network_failure() end do
        {:error, response} = GlobalCollect.authorize(@amount, @valid_card, @options)
        assert response.success == false
        assert response.reason == :network_fail?
      end
    end
  end
end
