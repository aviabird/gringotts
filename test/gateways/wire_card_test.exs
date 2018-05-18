defmodule Gringotts.Gateways.WireCardTest do
  use ExUnit.Case, async: false
  Code.require_file("../mocks/wirecard_mock.exs", __DIR__)
  import Mock

  # TEST_AUTHORIZATION_GUWID = 'C822580121385121429927'
  # TEST_PURCHASE_GUWID =      'C865402121385575982910'
  # TEST_CAPTURE_GUWID =       'C833707121385268439116'

  alias Gringotts.CreditCard
  alias Gringotts.Gateways.WireCard
  alias Gringotts.Gateways.WireCardMock, as: MockResponse

  @test_authorization_guwid "C822580121385121429927"
  @test_purchase_guwid "C865402121385575982910"

  @amount Money.new(1, :EUR)
  @bad_amount Money.new("0.9", :EUR)

  @card %CreditCard{
    number: "4200000000000000",
    month: 12,
    year: 2018,
    first_name: "Longbob",
    last_name: "Longsen",
    verification_code: "123",
    brand: "visa"
  }

  @declined_card %CreditCard{
    number: "4000300011112220",
    month: 12,
    year: 2018,
    first_name: "Longbob",
    last_name: "Longsen",
    verification_code: "123",
    brand: "visa"
  }

  @address %{
    name: "Jim Smith",
    address1: "456 My Street",
    address2: "Apt 1",
    company: "Widgets Inc",
    city: "Ottawa",
    state: "ON",
    zip: "K1C2N6",
    country: "CA",
    phone: "(555)555-5555",
    fax: "(555)555-6666"
  }

  @options [
    order_id: 1,
    billing_address: @address,
    description: 'Wirecard remote test purchase',
    email: "soleone@example.com",
    ip: "127.0.0.1",
    test: true
  ]

  describe "authorize/3" do
    test "with successful authorization" do
      with_mock HTTPoison,
        request: fn _method, _url, _body, _headers ->
          MockResponse.successful_authorization_response()
        end do
        {:ok, response} = WireCard.authorize(@amount, @card, @options)

        response_guwid =
          response["WIRECARD_BXML"]["W_RESPONSE"]["W_JOB"]["FNC_CC_PREAUTHORIZATION"][
            "CC_TRANSACTION"
          ]["PROCESSING_STATUS"]["GuWID"]

        assert response_guwid == @test_authorization_guwid
      end
    end

    test "with successful reference authorization" do
      with_mock HTTPoison,
        request: fn _method, _url, _body, _headers ->
          MockResponse.successful_authorization_response()
        end do
        {:ok, response} = WireCard.authorize(@amount, "709678", @options)

        response_guwid =
          response["WIRECARD_BXML"]["W_RESPONSE"]["W_JOB"]["FNC_CC_PREAUTHORIZATION"][
            "CC_TRANSACTION"
          ]["PROCESSING_STATUS"]["GuWID"]

        assert response_guwid == @test_authorization_guwid
      end
    end

    test "with wrong credit card authorization" do
      with_mock HTTPoison,
        request: fn _method, _url, _body, _headers ->
          MockResponse.wrong_creditcard_authorization_response()
        end do
        {:ok, response} = WireCard.authorize(@amount, @declined_card, @options)

        response_error =
          response["WIRECARD_BXML"]["W_RESPONSE"]["W_JOB"]["FNC_CC_PREAUTHORIZATION"][
            "CC_TRANSACTION"
          ]["PROCESSING_STATUS"]["ERROR"]

        assert "24997" === response_error["Number"]
        assert "DATA_ERROR" === response_error["Type"]
      end
    end
  end

  describe "purchase/3" do
    test "with successful purchase" do
      with_mock HTTPoison,
        request: fn _method, _url, _body, _headers ->
          MockResponse.successful_purchase_response()
        end do
        {:ok, response} = WireCard.purchase(@amount, @card, @options)

        response_guwid =
          response["WIRECARD_BXML"]["W_RESPONSE"]["W_JOB"]["FNC_CC_PURCHASE"]["CC_TRANSACTION"][
            "PROCESSING_STATUS"
          ]["GuWID"]

        assert response_guwid == @test_purchase_guwid
      end
    end

    test "with successful reference purchase" do
      with_mock HTTPoison,
        request: fn _method, _url, _body, _headers ->
          MockResponse.successful_purchase_response()
        end do
        {:ok, response} = WireCard.purchase(@amount, "12345", @options)

        response_guwid =
          response["WIRECARD_BXML"]["W_RESPONSE"]["W_JOB"]["FNC_CC_PURCHASE"]["CC_TRANSACTION"][
            "PROCESSING_STATUS"
          ]["GuWID"]

        assert response_guwid == @test_purchase_guwid
      end
    end
  end

  describe "authorize/3 and capture/3" do
    # This is Integration testing
    test "with successful authorization and capture" do
      # Authorize first
      response_guwid =
        with_mock HTTPoison,
          request: fn _method, _url, _body, _headers ->
            MockResponse.successful_authorization_response()
          end do
          {:ok, response} = WireCard.authorize(@amount, @card, @options)

          response_guwid =
            response["WIRECARD_BXML"]["W_RESPONSE"]["W_JOB"]["FNC_CC_PREAUTHORIZATION"][
              "CC_TRANSACTION"
            ]["PROCESSING_STATUS"]["GuWID"]

          assert response_guwid == @test_authorization_guwid
          response_guwid
        end

      # capture
      with_mock HTTPoison,
        request: fn _method, _url, _body, _headers ->
          MockResponse.successful_authorization_response()
        end do
        {:ok, response} = WireCard.capture(response_guwid, @amount, @options)

        response_message =
          response["WIRECARD_BXML"]["W_RESPONSE"]["W_JOB"]["FNC_CC_PREAUTHORIZATION"][
            "CC_TRANSACTION"
          ]["PROCESSING_STATUS"]["Info"]

        assert response_message =~ "THIS IS A DEMO TRANSACTION"
      end
    end

    test "with successful authorization and partial capture" do
      # Authorize first
      response_guwid =
        with_mock HTTPoison,
          request: fn _method, _url, _body, _headers ->
            MockResponse.successful_authorization_response()
          end do
          {:ok, response} = WireCard.authorize(@amount, @card, @options)

          response_guwid =
            response["WIRECARD_BXML"]["W_RESPONSE"]["W_JOB"]["FNC_CC_PREAUTHORIZATION"][
              "CC_TRANSACTION"
            ]["PROCESSING_STATUS"]["GuWID"]

          assert response_guwid == @test_authorization_guwid
          response_guwid
        end

      # capture
      with_mock HTTPoison,
        request: fn _method, _url, _body, _headers ->
          MockResponse.successful_authorization_response()
        end do
        {:ok, response} = WireCard.capture(response_guwid, @bad_amount, @options)

        response_message =
          response["WIRECARD_BXML"]["W_RESPONSE"]["W_JOB"]["FNC_CC_PREAUTHORIZATION"][
            "CC_TRANSACTION"
          ]["PROCESSING_STATUS"]["Info"]

        assert response_message =~ "THIS IS A DEMO TRANSACTION"
      end
    end

    test "with unauthorized capture" do
      with_mock HTTPoison,
        request: fn _method, _url, _body, _headers ->
          MockResponse.unauthorized_capture_response()
        end do
        {:ok, response} = WireCard.capture("1234567890123456789012", @amount, @options)

        response_message =
          response["WIRECARD_BXML"]["W_RESPONSE"]["W_JOB"]["FNC_CC_CAPTURE"]["CC_TRANSACTION"][
            "PROCESSING_STATUS"
          ]["ERROR"]["Message"]

        assert response_message =~
                 "Could not find referenced transaction for GuWID 1234567890123456789012."
      end
    end
  end

  describe "refund/3" do
    test "with successful refund" do
      with_mock HTTPoison,
        request: fn _method, _url, _body, _headers ->
          MockResponse.successful_refund_response()
        end do
        {:ok, response} = WireCard.refund(@bad_amount, @test_purchase_guwid, @options)

        response_message =
          response["WIRECARD_BXML"]["W_RESPONSE"]["W_JOB"]["FNC_CC_BOOKBACK"]["CC_TRANSACTION"][
            "PROCESSING_STATUS"
          ]["Info"]

        assert response_message =~ "All good!"
      end
    end

    test "with failed refund" do
      with_mock HTTPoison,
        request: fn _method, _url, _body, _headers -> MockResponse.failed_refund_response() end do
        {:ok, response} = WireCard.refund(@bad_amount, "TheIdentifcation", @options)

        response_message =
          response["WIRECARD_BXML"]["W_RESPONSE"]["W_JOB"]["FNC_CC_BOOKBACK"]["CC_TRANSACTION"][
            "PROCESSING_STATUS"
          ]["ERROR"]["Message"]

        assert response_message =~ "Not prudent"
      end
    end
  end

  describe "void/2" do
    test "with successful void" do
      with_mock HTTPoison,
        request: fn _method, _url, _body, _headers -> MockResponse.successful_void_response() end do
        {:ok, response} = WireCard.void(@test_purchase_guwid, @options)

        response_message =
          response["WIRECARD_BXML"]["W_RESPONSE"]["W_JOB"]["FNC_CC_REVERSAL"]["CC_TRANSACTION"][
            "PROCESSING_STATUS"
          ]["Info"]

        assert response_message =~ "Nice one!"
      end
    end

    test "with failed void" do
      with_mock HTTPoison,
        request: fn _method, _url, _body, _headers -> MockResponse.failed_void_response() end do
        {:ok, response} = WireCard.void(@test_purchase_guwid, @options)

        response_message =
          response["WIRECARD_BXML"]["W_RESPONSE"]["W_JOB"]["FNC_CC_REVERSAL"]["CC_TRANSACTION"][
            "PROCESSING_STATUS"
          ]["ERROR"]["Message"]

        assert response_message =~ "Not gonna do it"
      end
    end
  end

  describe "store/2" do
    @tag :pending
    test "with store sets recurring transaction type to initial" do
    end

    @tag :pending
    test "with store sets amount to amount from options" do
    end
  end

  describe "scrubbing/1" do
    @tag :pending
    test "with transcript scrubbing" do
    end
  end

  describe "testing response for different request scenarios" do
    @tag :pending
    test "with no error if no state is provided in address" do
    end

    @tag :pending
    test "with no error if no address provided" do
    end

    @tag :pending
    test "with failed avs response message" do
    end

    @tag :pending
    test "with failed amex avs response code" do
    end

    @tag :pending
    # Not sure what is this need to check
    test "with commerce type option" do
    end

    @tag :pending
    test "with authorization using reference sets proper elements" do
    end

    @tag :pending
    test "with purchase using reference sets proper elements" do
    end

    @tag :pending
    test "with authorization with recurring transaction type initial" do
    end

    @tag :pending
    test "with purchase using with recurring transaction type initial" do
    end

    @tag :pending
    test "with description trucated to 32 chars in authorize" do
    end

    @tag :pending
    test "with description trucated to 32 chars in purchase" do
    end

    @tag :pending
    test "with description is ascii encoded since wirecard does not like utf 8" do
    end
  end

  describe "testing system error in response in differnt request scenarios" do
    @tag :pending
    test "with system error response" do
    end

    @tag :pending
    test "with system error response without job" do
    end
  end
end
