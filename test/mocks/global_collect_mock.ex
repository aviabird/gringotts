defmodule Gringotts.Gateways.GlobalCollectMock do
  @moduledoc false

  def test_for_purchase_with_valid_card do
    {:ok,
     %HTTPoison.Response{
       body:
         ~s/{"creationOutput":{"additionalReference":"00000012260000000074","externalReference":
       "000000122600000000740000100001"},"payment":{"id":"000000122600000000740000100001",
       "paymentOutput":{"amountOfMoney":{"amount":500,"currencyCode":"USD"},"references":
       {"paymentReference":"0"},"paymentMethod":"card","cardPaymentMethodSpecificOutput":
       {"paymentProductId":1,"authorisationCode":"OK1131","fraudResults":{"fraudServiceResult":
       "no-advice","avsResult":"0","cvvResult":"0"},"card":{"cardNumber":"************7977",
       "expiryDate":"1218"}}},"status":"PENDING_APPROVAL","statusOutput":{"isCancellable":true,
       "statusCategory":"PENDING_MERCHANT","statusCode":600,"statusCodeChangeDateTime":
       "20180118135349","isAuthorized":true,"isRefundable":false}}}/,
       headers: [
         {"Date", "Thu, 18 Jan 2018 12:53:49 GMT"},
         {"Server", "Apache/2.4.27 (Unix) OpenSSL/1.0.2l"},
         {"Location",
          "https://api-sandbox.globalcollect.com:443/v1/1226/payments/000000122600000000740000100001"},
         {"X-Powered-By", "Servlet/3.0 JSP/2.2"},
         {"Transfer-Encoding", "chunked"},
         {"Content-Type", "application/json"}
       ],
       request_url: "https://api-sandbox.globalcollect.com/v1/1226/payments",
       status_code: 201
     }}
  end

  def test_for_purchase_with_invalid_card do
    {:ok,
     %HTTPoison.Response{
       body:
         ~s/{"errorId" : "363899bd-acfb-4452-bbb0-741c0df6b4b8","errors" : [ {"code" : "21000120",
         "requestId" : "980825","propertyName" : "cardPaymentMethodSpecificInput.card.expiryDate",
         "message" : "cardPaymentMethodSpecificInput.card.expiryDate (1210) IS IN THE PAST OR NOT IN CORRECT MMYY FORMAT",
         "httpStatusCode" : 400} ],"paymentResult" : {"creationOutput" : { " additionalReference" : "00000012260000000075",
         "externalReference" : "000000122600000000750000100001"},"payment" : {"id" : "000000122600000000750000100001",
         "paymentOutput" : {"amountOfMoney" : {"amount" : 500,"currencyCode" : "USD"},"references" : {"paymentReference" : "0"},
         "paymentMethod" : "card","cardPaymentMethodSpecificOutput" : {"paymentProductId" : 1}},
         "status" : "REJECTED","statusOutput" : {"errors" : [ {"code" : "21000120",
         "requestId" : "546247","propertyName" : "cardPaymentMethodSpecificInput.card.expiryDate",
         "message" : "cardPaymentMethodSpecificInput.card.expiryDate (1210) IS IN THE PAST OR NOT IN CORRECT MMYY FORMAT",
         "httpStatusCode" : 400} ],"isCancellable" : false,"statusCategory" : "UNSUCCESSFUL","statusCode" : 100,
         "statusCodeChangeDateTime" : "20180118135651","isAuthorized" : false,"isRefundable" : false}}}}/,
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
    {:ok,
     %HTTPoison.Response{
       body:
         ~s/{ "errorId" : "8c34dc0b-776c-44e3-8cd4-b36222960153","errors" : [ {"code" : "1099","id" :
       "INVALID_VALUE","category" : "CONNECT_PLATFORM_ERROR","message" :
       "INVALID_VALUE: '50.3' is not a valid value for field 'amount'",
       "httpStatusCode" : 400 } ]}/,
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
    {:ok,
     %HTTPoison.Response{
       body:
         ~s/{"creationOutput" : {"additionalReference" : "00000012260000000065","externalReference" :
        "000000122600000000650000100001"},"payment" : {"id" : "000000122600000000650000100001",
        "paymentOutput" :{"amountOfMoney" : {"amount" : 500,"currencyCode" : "USD"},"references" :
        {"paymentReference" : "0" },"paymentMethod" : "card","cardPaymentMethodSpecificOutput" :
        {"paymentProductId" : 1,"authorisationCode" : "OK1131","fraudResults" :
        {"fraudServiceResult" : "no-advice","avsResult" : "0","cvvResult" : "0"},"card" :
        {"cardNumber" : "************7977","expiryDate" : "1218"}}},"status" : "PENDING_APPROVAL",
        "statusOutput" : {"isCancellable" : true,"statusCategory" : "PENDING_MERCHANT","statusCode"
        : 600,"statusCodeChangeDateTime" : "20180118110419","isAuthorized" : true,
        "isRefundable" : false}}}/,
       headers: [
         {"Date", "Thu, 18 Jan 2018 10:04:19 GMT"},
         {"Server", "Apache/2.4.27 (Unix) OpenSSL/1.0.2l"},
         {"Location",
          "https://api-sandbox.globalcollect.com:443/v1/1226/payments/000000122600000000650000100001"},
         {"X-Powered-By", "Servlet/3.0 JSP/2.2"},
         {"Transfer-Encoding", "chunked"},
         {"Content-Type", "application/json"}
       ],
       request_url: "https://api-sandbox.globalcollect.com/v1/1226/payments",
       status_code: 201
     }}
  end

  def test_for_authorize_with_invalid_card do
    {:ok,
     %HTTPoison.Response{
       body:
         ~s/{"errorId" : "dcdf5c8d-e475-4fbc-ac57-76123c1640a2","errors" : [ {"code" : "21000120",
        "requestId" : "978754","propertyName" : "cardPaymentMethodSpecificInput.card.expiryDate","message":
        "cardPaymentMethodSpecificInput.card.expiryDate (1210) IS IN THE PAST OR NOT IN CORRECT MMYY FORMAT",
        "httpStatusCode" : 400} ],"paymentResult" : {"creationOutput" :
        {"additionalReference" :"00000012260000000066","externalReference" :
        "000000122600000000660000100001"},"payment" :{"id" : "000000122600000000660000100001",
        "paymentOutput" : {"amountOfMoney" : {"amount" : 500,"currencyCode" : "USD"},
        "references" : {"paymentReference" : "0"},"paymentMethod" : "card",
        "cardPaymentMethodSpecificOutput" : {"paymentProductId" : 1}},"status" : "REJECTED",
        "statusOutput":{"errors" : [ {"code" : "21000120","requestId" : "978755","propertyName" :
        "cardPaymentMethodSpecificInput.card.expiryDate","message" :
        "cardPaymentMethodSpecificInput.card.expiryDate (1210) IS IN THE PAST OR NOT IN CORRECT MMYY FORMAT",
        "httpStatusCode" : 400} ],"isCancellable" : false,"statusCategory" :
        "UNSUCCESSFUL","statusCode" : 100,"statusCodeChangeDateTime" : "20180118111508",
        "isAuthorized" : false,"isRefundable" : false}}}}/,
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
    {:ok,
     %HTTPoison.Response{
       body:
         ~s/{"errorId" : "1dbef568-ed86-4c8d-a3c3-74ced258d5a2","errors" : [ {"code" : "1099","id" :
       "INVALID_VALUE", "category" : "CONNECT_PLATFORM_ERROR","message" :
       "INVALID_VALUE: '50.3' is not a valid value for field 'amount'","httpStatusCode" : 400} ]}/,
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
    {:ok,
     %HTTPoison.Response{
       body:
         ~s/{  "errorId" : "b6ba00d2-8f11-4822-8f32-c6d0a4d8793b",  "errors" : [ {"code" : "300450",
       "message" : "ORDER WITHOUT REFUNDABLE PAYMENTS", "httpStatusCode" : 400  } ]}/,
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
    {:ok,
     %HTTPoison.Response{
       body: ~s/{   "payment" : {"id" : "000000122600000000650000100001", "paymentOutput" : {
         "amountOfMoney" :{"amount" : 50,"currencyCode" : "USD"},"references" : {"paymentReference"
        : "0"},"paymentMethod" : "card","cardPaymentMethodSpecificOutput" : {"paymentProductId" :
        1,"authorisationCode" : "OK1131","fraudResults" : {"fraudServiceResult" : "no-advice",
        "avsResult" : "0","cvvResult" : "0"},"card" :{"cardNumber" : "************7977",
        "expiryDate" : "1218"}}},"status" : "CAPTURE_REQUESTED","statusOutput" :
        {"isCancellable" : true,"statusCategory" : "PENDING_CONNECT_OR_3RD_PARTY",
        "statusCode" : 800,"statusCodeChangeDateTime" : "20180123140826","isAuthorized" : true,
        "isRefundable" : false} }}/,
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
    {:ok,
     %HTTPoison.Response{
       body: ~s/{   "errorId" : "ccb99804-0240-45b6-bb28-52aaae59d71b",   "errors" : [
         {"code" : "1002","id" :"UNKNOWN_PAYMENT_ID","category" : "CONNECT_PLATFORM_ERROR",
         "propertyName" : "paymentId","message": "UNKNOWN_PAYMENT_ID","httpStatusCode" :404}]}/,
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
    {:ok,
     %HTTPoison.Response{
       body:
         ~s/{ "payment" : {"id" : "000000122600000000870000100001","paymentOutput" : {"amountOfMoney"
        :{"amount" : 50,"currencyCode" : "USD"},"references" : {"paymentReference" : "0"},
        "paymentMethod" : "card","cardPaymentMethodSpecificOutput" : {"paymentProductId" : 1,
        "authorisationCode" : "OK1131","fraudResults" : {"fraudServiceResult" : "no-advice",
        "avsResult" : "0","cvvResult" : "0"},"card" :{"cardNumber" : "************7977",
        "expiryDate" : "1218"}}},"status" : "CANCELLED","statusOutput":{"isCancellable" :
        false,"statusCategory" : "UNSUCCESSFUL","statusCode" : 99999,
        "statusCodeChangeDateTime" : "20180124064204","isAuthorized" : false,"isRefundable" :
         false}}}/,
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
