  defmodule Gringotts.Gateways.AuthorizeNetMock do

    def successful_purchase_response do
      {:ok,
      %HTTPoison.Response{body: "﻿<?xml version=\"1.0\" encoding=\"utf-8\"?><createTransactionResponse xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\" xmlns:xsd=\"http://www.w3.org/2001/XMLSchema\" xmlns=\"AnetApi/xml/v1/schema/AnetApiSchema.xsd\"><refId>123456</refId><messages><resultCode>Ok</resultCode><message><code>I00001</code><text>Successful.</text></message></messages><transactionResponse><responseCode>1</responseCode><authCode>C7HPT1</authCode><avsResultCode>Y</avsResultCode><cvvResultCode>P</cvvResultCode><cavvResultCode>2</cavvResultCode><transId>60036553096</transId><refTransID /><transHash>5D6782A03246EE3BAFABE8006E32DE97</transHash><testRequest>0</testRequest><accountNumber>XXXX0015</accountNumber><accountType>MasterCard</accountType><messages><message><code>1</code><description>This transaction has been approved.</description></message></messages><transHashSha2 /></transactionResponse></createTransactionResponse>",
       headers: [{"Cache-Control", "private"},
        {"Content-Type", "application/xml; charset=utf-8"},
        {"X-OPNET-Transaction-Trace",
         "a2_b6b84b43-d399-4dde-bc12-fb1f8ccf4b27-51156-13182173"},
        {"Access-Control-Allow-Origin", "*"},
        {"Access-Control-Allow-Methods", "PUT,OPTIONS,POST,GET"},
        {"Access-Control-Allow-Headers",
         "x-requested-with,cache-control,content-type,origin,method,SOAPAction"},
        {"Access-Control-Allow-Credentials", "true"}, {"X-Cnection", "close"},
        {"Content-Length", "908"}, {"Date", "Thu, 21 Dec 2017 09:29:12 GMT"},
        {"Connection", "keep-alive"}],
       request_url: "https://apitest.authorize.net/xml/v1/request.api",
       status_code: 200}}
    end

    def bad_card_purchase_response do
      {:ok,
      %HTTPoison.Response{body: "﻿<?xml version=\"1.0\" encoding=\"utf-8\"?><ErrorResponse xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\" xmlns:xsd=\"http://www.w3.org/2001/XMLSchema\" xmlns=\"AnetApi/xml/v1/schema/AnetApiSchema.xsd\"><messages><resultCode>Error</resultCode><message><code>E00003</code><text>The 'AnetApi/xml/v1/schema/AnetApiSchema.xsd:cardNumber' element is invalid - The value XXXXX is invalid according to its datatype 'String' - The actual length is less than the MinLength value.</text></message></messages></ErrorResponse>",
       headers: [{"Cache-Control", "private"},
        {"Content-Type", "application/xml; charset=utf-8"},
        {"X-OPNET-Transaction-Trace",
         "a2_f2f80544-1a98-4ad7-989b-8d267ebf5043-56152-10066531"},
        {"Access-Control-Allow-Origin", "*"},
        {"Access-Control-Allow-Methods", "PUT,OPTIONS,POST,GET"},
        {"Access-Control-Allow-Headers",
         "x-requested-with,cache-control,content-type,origin,method,SOAPAction"},
        {"Access-Control-Allow-Credentials", "true"}, {"X-Cnection", "close"},
        {"Content-Length", "514"}, {"Date", "Thu, 21 Dec 2017 09:35:45 GMT"},
        {"Connection", "keep-alive"}],
       request_url: "https://apitest.authorize.net/xml/v1/request.api",
       status_code: 200}}
    end

    def bad_amount_purchase_response do
      {:ok,
      %HTTPoison.Response{body: "﻿<?xml version=\"1.0\" encoding=\"utf-8\"?><createTransactionResponse xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\" xmlns:xsd=\"http://www.w3.org/2001/XMLSchema\" xmlns=\"AnetApi/xml/v1/schema/AnetApiSchema.xsd\"><refId>123456</refId><messages><resultCode>Error</resultCode><message><code>E00027</code><text>The transaction was unsuccessful.</text></message></messages><transactionResponse><responseCode>3</responseCode><authCode /><avsResultCode>P</avsResultCode><cvvResultCode /><cavvResultCode /><transId>0</transId><refTransID /><transHash>C7C56F020A2AE2660A87637CD00B4D5C</transHash><testRequest>0</testRequest><accountNumber>XXXX0015</accountNumber><accountType>MasterCard</accountType><errors><error><errorCode>5</errorCode><errorText>A valid amount is required.</errorText></error></errors><transHashSha2 /></transactionResponse></createTransactionResponse>",
       headers: [{"Cache-Control", "private"},
        {"Content-Type", "application/xml; charset=utf-8"},
        {"X-OPNET-Transaction-Trace",
         "a2_b6b84b43-d399-4dde-bc12-fb1f8ccf4b27-51156-13187900"},
        {"Access-Control-Allow-Origin", "*"},
        {"Access-Control-Allow-Methods", "PUT,OPTIONS,POST,GET"},
        {"Access-Control-Allow-Headers",
         "x-requested-with,cache-control,content-type,origin,method,SOAPAction"},
        {"Access-Control-Allow-Credentials", "true"}, {"X-Cnection", "close"},
        {"Content-Length", "867"}, {"Date", "Thu, 21 Dec 2017 09:44:33 GMT"},
        {"Connection", "keep-alive"}],
       request_url: "https://apitest.authorize.net/xml/v1/request.api",
       status_code: 200}}
    end

    def network_error_response do
      body = "no response error"
      {:error, %{body: body, status_code: 500}}
    end
  end
