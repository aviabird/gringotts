defmodule Gringotts.Gateways.GlobalCollectMock do
  def test_for_purchase_with_valid_card do
    {:ok, %HTTPoison.Response{
      body:
        ~s/"{\n   creationOutput : {\n      additionalReference : 00000012260000000074,\n      externalReference : 000000122600000000740000100001\n   },\n   payment : {\n      id : 000000122600000000740000100001,\n      paymentOutput : {\n         amountOfMoney : {\n            amount : 500,\n            currencyCode : USD\n         },\n         references : {\n            paymentReference : 0\n         },\n         paymentMethod : card,\n         cardPaymentMethodSpecificOutput : {\n            paymentProductId : 1,\n            authorisationCode : OK1131,\n            fraudResults : {\n               fraudServiceResult : no-advice,\n               avsResult : 0,\n               cvvResult : 0\n            },\n            card : {\n               cardNumber : ************7977,\n               expiryDate : 1218\n            }\n         }\n      },\n      status : PENDING_APPROVAL,\n      statusOutput : {\n         isCancellable : true,\n         statusCategory : PENDING_MERCHANT,\n         statusCode : 600,\n         statusCodeChangeDateTime : 20180118135349,\n         isAuthorized : true,\n         isRefundable : false\n      }\n   }\n}"/,
      headers: [
        {"Date", "Thu, 18 Jan 2018 12:53:49 GMT"},
        {"Server", "Apache/2.4.27 (Unix) OpenSSL/1.0.2l"},
        {
          "Location",
          "https://api-sandbox.globalcollect.com:443/v1/1226/payments/000000122600000000740000100001"
        },
        {"X-Powered-By", "Servlet/3.0 JSP/2.2"},
        {"Transfer-Encoding", "chunked"},
        {"Content-Type", "application/json"}
      ],
      request_url: "https://api-sandbox.globalcollect.com/v1/1226/payments",
      status_code: 201
    }}
  end

  def test_for_purchase_with_invalid_card do
    {:ok, %HTTPoison.Response{
      body:
        ~s/"{\n   errorId : 363899bd-acfb-4452-bbb0-741c0df6b4b8,\n   errors : [ {\n      code : 21000120,\n      requestId : 980825,\n      propertyName : cardPaymentMethodSpecificInput.card.expiryDate,\n      message : cardPaymentMethodSpecificInput.card.expiryDate (1210) IS IN THE PAST OR NOT IN CORRECT MMYY FORMAT,\n      httpStatusCode : 400\n   } ],\n   paymentResult : {\n      creationOutput : {\n         additionalReference : 00000012260000000075,\n         externalReference : 000000122600000000750000100001\n      },\n      payment : {\n         id : 000000122600000000750000100001,\n         paymentOutput : {\n            amountOfMoney : {\n               amount : 500,\n               currencyCode : USD\n            },\n            references : {\n               paymentReference : 0\n            },\n            paymentMethod : card,\n            cardPaymentMethodSpecificOutput : {\n               paymentProductId : 1\n            }\n         },\n         status : REJECTED,\n         statusOutput : {\n            errors : [ {\n               code : 21000120,\n               requestId : 546247,\n               propertyName : cardPaymentMethodSpecificInput.card.expiryDate,\n               message : cardPaymentMethodSpecificInput.card.expiryDate (1210) IS IN THE PAST OR NOT IN CORRECT MMYY FORMAT,\n               httpStatusCode : 400\n            } ],\n            isCancellable : false,\n            statusCategory : UNSUCCESSFUL,\n            statusCode : 100,\n            statusCodeChangeDateTime : 20180118135651,\n            isAuthorized : false,\n            isRefundable : false\n         }\n      }\n   }\n}"/,
      headers: [
        {"Date", "Thu, 18 Jan 2018 12:56:51 GMT"},
        {"Server", "Apache/2.4.27 (Unix) OpenSSL/1.0.2l"},
        {"X-Powered-By", "Servlet/3.0 JSP/2.2"},
        {"Connection", "close"},
        {"Transfer-Encoding", "chunked"},
        {"Content-Type", "application/json"}
      ],
      request_url: "https://api-sandbox.globalcollect.com/v1/1226/payments",
      status_code: 400
    }}
  end

  def test_for_purchase_with_invalid_amount do
    {:ok, %HTTPoison.Response{
      body:
        ~s/"{\n   errorId : 8c34dc0b-776c-44e3-8cd4-b36222960153,\n   errors : [ {\n      code : 1099,\n      id : INVALID_VALUE,\n      category : CONNECT_PLATFORM_ERROR,\n      message : INVALID_VALUE: '50.3' is not a valid value for field 'amount',\n      httpStatusCode : 400\n   } ]\n}"/,
      headers: [
        {"Date", "Wed, 24 Jan 2018 07:16:06 GMT"},
        {"Server", "Apache/2.4.27 (Unix) OpenSSL/1.0.2l"},
        {"X-Powered-By", "Servlet/3.0 JSP/2.2"},
        {"Connection", "close"},
        {"Transfer-Encoding", "chunked"},
        {"Content-Type", "application/json"}
      ],
      request_url: "https://api-sandbox.globalcollect.com/v1/1226/payments",
      status_code: 400
    }}
  end

  def test_for_authorize_with_valid_card do
    {:ok, %HTTPoison.Response{
      body:
        ~s/"{\n   creationOutput : {\n      additionalReference : 00000012260000000065,\n      externalReference : 000000122600000000650000100001\n   },\n   payment : {\n      id : 000000122600000000650000100001,\n      paymentOutput : {\n         amountOfMoney : {\n            amount : 500,\n            currencyCode : USD\n         },\n         references : {\n            paymentReference : 0\n         },\n         paymentMethod : card,\n         cardPaymentMethodSpecificOutput : {\n            paymentProductId : 1,\n            authorisationCode : OK1131,\n            fraudResults : {\n               fraudServiceResult : no-advice,\n               avsResult : 0,\n               cvvResult : 0\n            },\n            card : {\n               cardNumber : ************7977,\n               expiryDate : 1218\n            }\n         }\n      },\n      status : PENDING_APPROVAL,\n      statusOutput : {\n         isCancellable : true,\n         statusCategory : PENDING_MERCHANT,\n         statusCode : 600,\n         statusCodeChangeDateTime : 20180118110419,\n         isAuthorized : true,\n         isRefundable : false\n      }\n   }\n}"/,
      headers: [
        {"Date", "Thu, 18 Jan 2018 10:04:19 GMT"},
        {"Server", "Apache/2.4.27 (Unix) OpenSSL/1.0.2l"},
        {
          "Location",
          "https://api-sandbox.globalcollect.com:443/v1/1226/payments/000000122600000000650000100001"
        },
        {"X-Powered-By", "Servlet/3.0 JSP/2.2"},
        {"Transfer-Encoding", "chunked"},
        {"Content-Type", "application/json"}
      ],
      request_url: "https://api-sandbox.globalcollect.com/v1/1226/payments",
      status_code: 201
    }}
  end

  def test_for_authorize_with_invalid_card do
    {:ok, %HTTPoison.Response{
      body:
        ~s/"{\n   errorId : dcdf5c8d-e475-4fbc-ac57-76123c1640a2,\n   errors : [ {\n      code : 21000120,\n      requestId : 978754,\n      propertyName : cardPaymentMethodSpecificInput.card.expiryDate,\n      message : cardPaymentMethodSpecificInput.card.expiryDate (1210) IS IN THE PAST OR NOT IN CORRECT MMYY FORMAT,\n      httpStatusCode : 400\n   } ],\n   paymentResult : {\n      creationOutput : {\n         additionalReference : 00000012260000000066,\n         externalReference : 000000122600000000660000100001\n      },\n      payment : {\n         id : 000000122600000000660000100001,\n         paymentOutput : {\n            amountOfMoney : {\n               amount : 500,\n               currencyCode : USD\n            },\n            references : {\n               paymentReference : 0\n            },\n            paymentMethod : card,\n            cardPaymentMethodSpecificOutput : {\n               paymentProductId : 1\n            }\n         },\n         status : REJECTED,\n         statusOutput : {\n            errors : [ {\n               code : 21000120,\n               requestId : 978755,\n               propertyName : cardPaymentMethodSpecificInput.card.expiryDate,\n               message : cardPaymentMethodSpecificInput.card.expiryDate (1210) IS IN THE PAST OR NOT IN CORRECT MMYY FORMAT,\n               httpStatusCode : 400\n            } ],\n            isCancellable : false,\n            statusCategory : UNSUCCESSFUL,\n            statusCode : 100,\n            statusCodeChangeDateTime : 20180118111508,\n            isAuthorized : false,\n            isRefundable : false\n         }\n      }\n   }\n}"/,
      headers: [
        {"Date", "Thu, 18 Jan 2018 10:15:08 GMT"},
        {"Server", "Apache/2.4.27 (Unix) OpenSSL/1.0.2l"},
        {"X-Powered-By", "Servlet/3.0 JSP/2.2"},
        {"Connection", "close"},
        {"Transfer-Encoding", "chunked"},
        {"Content-Type", "application/json"}
      ],
      request_url: "https://api-sandbox.globalcollect.com/v1/1226/payments",
      status_code: 400
    }}
  end

  def test_for_authorize_with_invalid_amount do
    {:ok, %HTTPoison.Response{
      body:
        ~s/"{\n   errorId : 1dbef568-ed86-4c8d-a3c3-74ced258d5a2,\n   errors : [ {\n      code : 1099,\n      id : INVALID_VALUE,\n      category : CONNECT_PLATFORM_ERROR,\n      message : INVALID_VALUE: '50.3' is not a valid value for field 'amount',\n      httpStatusCode : 400\n   } ]\n}"/,
      headers: [
        {"Date", "Tue, 23 Jan 2018 11:18:11 GMT"},
        {"Server", "Apache/2.4.27 (Unix) OpenSSL/1.0.2l"},
        {"X-Powered-By", "Servlet/3.0 JSP/2.2"},
        {"Connection", "close"},
        {"Transfer-Encoding", "chunked"},
        {"Content-Type", "application/json"}
      ],
      request_url: "https://api-sandbox.globalcollect.com/v1/1226/payments",
      status_code: 400
    }}
  end

  def test_for_refund do
    {:ok, %HTTPoison.Response{
      body:
        ~s/"{\n   errorId : b6ba00d2-8f11-4822-8f32-c6d0a4d8793b,\n   errors : [ {\n      code : 300450,\n      message : ORDER WITHOUT REFUNDABLE PAYMENTS,\n      httpStatusCode : 400\n   } ]\n}"/,
      headers: [
        {"Date", "Wed, 24 Jan 2018 05:33:56 GMT"},
        {"Server", "Apache/2.4.27 (Unix) OpenSSL/1.0.2l"},
        {"X-Powered-By", "Servlet/3.0 JSP/2.2"},
        {"Connection", "close"},
        {"Transfer-Encoding", "chunked"},
        {"Content-Type", "application/json"}
      ],
      request_url:
        "https://api-sandbox.globalcollect.com/v1/1226/payments/000000122600000000870000100001/refund",
      status_code: 400
    }}
  end

  def test_for_capture_with_valid_paymentid do
    {:ok, %HTTPoison.Response{
      body:
        ~s/"{\n   payment : {\n      id : 000000122600000000650000100001,\n      paymentOutput : {\n         amountOfMoney : {\n            amount : 50,\n            currencyCode : USD\n         },\n         references : {\n            paymentReference : 0\n         },\n         paymentMethod : card,\n         cardPaymentMethodSpecificOutput : {\n            paymentProductId : 1,\n            authorisationCode : OK1131,\n            fraudResults : {\n               fraudServiceResult : no-advice,\n               avsResult : 0,\n               cvvResult : 0\n            },\n            card : {\n               cardNumber : ************7977,\n               expiryDate : 1218\n            }\n         }\n      },\n      status : CAPTURE_REQUESTED,\n      statusOutput : {\n         isCancellable : true,\n         statusCategory : PENDING_CONNECT_OR_3RD_PARTY,\n         statusCode : 800,\n         statusCodeChangeDateTime : 20180123140826,\n         isAuthorized : true,\n         isRefundable : false\n      }\n   }\n}"/,
      headers: [
        {"Date", "Tue, 23 Jan 2018 13:08:26 GMT"},
        {"Server", "Apache/2.4.27 (Unix) OpenSSL/1.0.2l"},
        {"X-Powered-By", "Servlet/3.0 JSP/2.2"},
        {"Transfer-Encoding", "chunked"},
        {"Content-Type", "application/json"}
      ],
      request_url:
        "https://api-sandbox.globalcollect.com/v1/1226/payments/000000122600000000650000100001/approve",
      status_code: 200
    }}
  end

  def test_for_capture_with_invalid_paymentid do
    {:ok, %HTTPoison.Response{
      body:
        ~s/"{\n   errorId : ccb99804-0240-45b6-bb28-52aaae59d71b,\n   errors : [ {\n      code : 1002,\n      id : UNKNOWN_PAYMENT_ID,\n      category : CONNECT_PLATFORM_ERROR,\n      propertyName : paymentId,\n      message : UNKNOWN_PAYMENT_ID,\n      httpStatusCode : 404\n   } ]\n}"/,
      headers: [
        {"Date", "Tue, 23 Jan 2018 12:25:59 GMT"},
        {"Server", "Apache/2.4.27 (Unix) OpenSSL/1.0.2l"},
        {"X-Powered-By", "Servlet/3.0 JSP/2.2"},
        {"Transfer-Encoding", "chunked"},
        {"Content-Type", "application/json"}
      ],
      request_url: "https://api-sandbox.globalcollect.com/v1/1226/payments/30/approve",
      status_code: 404
    }}
  end

  def test_for_void_with_valid_card do
    {:ok, %HTTPoison.Response{
      body:
        ~s/"{\n   payment : {\n      id : 000000122600000000870000100001,\n      paymentOutput : {\n         amountOfMoney : {\n            amount : 50,\n            currencyCode : USD\n         },\n         references : {\n            paymentReference : 0\n         },\n         paymentMethod : card,\n         cardPaymentMethodSpecificOutput : {\n            paymentProductId : 1,\n            authorisationCode : OK1131,\n            fraudResults : {\n               fraudServiceResult : no-advice,\n               avsResult : 0,\n               cvvResult : 0\n            },\n            card : {\n               cardNumber : ************7977,\n               expiryDate : 1218\n            }\n         }\n      },\n      status : CANCELLED,\n      statusOutput : {\n         isCancellable : false,\n         statusCategory : UNSUCCESSFUL,\n         statusCode : 99999,\n         statusCodeChangeDateTime : 20180124064204,\n         isAuthorized : false,\n         isRefundable : false\n      }\n   }\n}"/,
      headers: [
        {"Date", "Wed, 24 Jan 2018 05:42:04 GMT"},
        {"Server", "Apache/2.4.27 (Unix) OpenSSL/1.0.2l"},
        {"X-Powered-By", "Servlet/3.0 JSP/2.2"},
        {"Transfer-Encoding", "chunked"},
        {"Content-Type", "application/json"}
      ],
      request_url:
        "https://api-sandbox.globalcollect.com/v1/1226/payments/000000122600000000870000100001/cancel",
      status_code: 200
    }}
  end

  def test_for_network_failure do
    {:error, %HTTPoison.Error{id: nil, reason: :nxdomain}}
  end
end
