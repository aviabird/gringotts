  defmodule Gringotts.Gateways.AuthorizeNetMock do

    # purchase mock response
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

    # authorize mock response
    def successful_authorize_response do
      {:ok,
      %HTTPoison.Response{body: "﻿<?xml version=\"1.0\" encoding=\"utf-8\"?><createTransactionResponse xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\" xmlns:xsd=\"http://www.w3.org/2001/XMLSchema\" xmlns=\"AnetApi/xml/v1/schema/AnetApiSchema.xsd\"><refId>123456</refId><messages><resultCode>Ok</resultCode><message><code>I00001</code><text>Successful.</text></message></messages><transactionResponse><responseCode>1</responseCode><authCode>K6Z0AB</authCode><avsResultCode>Y</avsResultCode><cvvResultCode>P</cvvResultCode><cavvResultCode>2</cavvResultCode><transId>60036854582</transId><refTransID /><transHash>A4AD079E22A271D92662CF093CED7A5D</transHash><testRequest>0</testRequest><accountNumber>XXXX0015</accountNumber><accountType>MasterCard</accountType><messages><message><code>1</code><description>This transaction has been approved.</description></message></messages><transHashSha2 /></transactionResponse></createTransactionResponse>",
       headers: [{"Cache-Control", "private"},
        {"Content-Type", "application/xml; charset=utf-8"},
        {"X-OPNET-Transaction-Trace",
         "a2_b6b84b43-d399-4dde-bc12-fb1f8ccf4b27-51156-15778237"},
        {"Access-Control-Allow-Origin", "*"},
        {"Access-Control-Allow-Methods", "PUT,OPTIONS,POST,GET"},
        {"Access-Control-Allow-Headers",
         "x-requested-with,cache-control,content-type,origin,method,SOAPAction"},
        {"Access-Control-Allow-Credentials", "true"}, {"X-Cnection", "close"},
        {"Content-Length", "908"}, {"Date", "Mon, 25 Dec 2017 14:17:56 GMT"},
        {"Connection", "keep-alive"}],
       request_url: "https://apitest.authorize.net/xml/v1/request.api",
       status_code: 200}}
    end

    def bad_card_authorize_response do
      {:ok,
      %HTTPoison.Response{body: "﻿<?xml version=\"1.0\" encoding=\"utf-8\"?><ErrorResponse xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\" xmlns:xsd=\"http://www.w3.org/2001/XMLSchema\" xmlns=\"AnetApi/xml/v1/schema/AnetApiSchema.xsd\"><messages><resultCode>Error</resultCode><message><code>E00003</code><text>The 'AnetApi/xml/v1/schema/AnetApiSchema.xsd:cardNumber' element is invalid - The value XXXXX is invalid according to its datatype 'String' - The actual length is less than the MinLength value.</text></message></messages></ErrorResponse>",
       headers: [{"Cache-Control", "private"},
        {"Content-Type", "application/xml; charset=utf-8"},
        {"X-OPNET-Transaction-Trace",
         "a2_f2f80544-1a98-4ad7-989b-8d267ebf5043-56152-12660528"},
        {"Access-Control-Allow-Origin", "*"},
        {"Access-Control-Allow-Methods", "PUT,OPTIONS,POST,GET"},
        {"Access-Control-Allow-Headers",
         "x-requested-with,cache-control,content-type,origin,method,SOAPAction"},
        {"Access-Control-Allow-Credentials", "true"}, {"X-Cnection", "close"},
        {"Content-Length", "514"}, {"Date", "Mon, 25 Dec 2017 14:19:29 GMT"},
        {"Connection", "keep-alive"}],
       request_url: "https://apitest.authorize.net/xml/v1/request.api",
       status_code: 200}}     
    end

    def bad_amount_authorize_response do
      {:ok,
      %HTTPoison.Response{body: "﻿<?xml version=\"1.0\" encoding=\"utf-8\"?><createTransactionResponse xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\" xmlns:xsd=\"http://www.w3.org/2001/XMLSchema\" xmlns=\"AnetApi/xml/v1/schema/AnetApiSchema.xsd\"><refId>123456</refId><messages><resultCode>Error</resultCode><message><code>E00027</code><text>The transaction was unsuccessful.</text></message></messages><transactionResponse><responseCode>3</responseCode><authCode /><avsResultCode>P</avsResultCode><cvvResultCode /><cavvResultCode /><transId>0</transId><refTransID /><transHash>C7C56F020A2AE2660A87637CD00B4D5C</transHash><testRequest>0</testRequest><accountNumber>XXXX0015</accountNumber><accountType>MasterCard</accountType><errors><error><errorCode>290</errorCode><errorText>There is one or more missing or invalid required fields.</errorText></error></errors><transHashSha2 /></transactionResponse></createTransactionResponse>",
       headers: [{"Cache-Control", "private"},
        {"Content-Type", "application/xml; charset=utf-8"},
        {"X-OPNET-Transaction-Trace",
         "a2_b6b84b43-d399-4dde-bc12-fb1f8ccf4b27-51156-15779095"},
        {"Access-Control-Allow-Origin", "*"},
        {"Access-Control-Allow-Methods", "PUT,OPTIONS,POST,GET"},
        {"Access-Control-Allow-Headers",
         "x-requested-with,cache-control,content-type,origin,method,SOAPAction"},
        {"Access-Control-Allow-Credentials", "true"}, {"X-Cnection", "close"},
        {"Content-Length", "898"}, {"Date", "Mon, 25 Dec 2017 14:22:02 GMT"},
        {"Connection", "keep-alive"}],
       request_url: "https://apitest.authorize.net/xml/v1/request.api",
       status_code: 200}}
    end

    # capture mock response

    def successful_capture_response do
      {:ok,
      %HTTPoison.Response{body: "﻿<?xml version=\"1.0\" encoding=\"utf-8\"?><createTransactionResponse xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\" xmlns:xsd=\"http://www.w3.org/2001/XMLSchema\" xmlns=\"AnetApi/xml/v1/schema/AnetApiSchema.xsd\"><refId>123456</refId><messages><resultCode>Ok</resultCode><message><code>I00001</code><text>Successful.</text></message></messages><transactionResponse><responseCode>1</responseCode><authCode>4OKD6Y</authCode><avsResultCode>P</avsResultCode><cvvResultCode /><cavvResultCode /><transId>60036854931</transId><refTransID>60036854931</refTransID><transHash>348C4ECD0F764736B012C4655BFA68EF</transHash><testRequest>0</testRequest><accountNumber>XXXX0015</accountNumber><accountType>MasterCard</accountType><messages><message><code>1</code><description>This transaction has been approved.</description></message></messages><transHashSha2 /></transactionResponse></createTransactionResponse>",
       headers: [{"Cache-Control", "private"},
        {"Content-Type", "application/xml; charset=utf-8"},
        {"X-OPNET-Transaction-Trace",
         "a2_b6b84b43-d399-4dde-bc12-fb1f8ccf4b27-51156-15783402"},
        {"Access-Control-Allow-Origin", "*"},
        {"Access-Control-Allow-Methods", "PUT,OPTIONS,POST,GET"},
        {"Access-Control-Allow-Headers",
         "x-requested-with,cache-control,content-type,origin,method,SOAPAction"},
        {"Access-Control-Allow-Credentials", "true"}, {"X-Cnection", "close"},
        {"Content-Length", "899"}, {"Date", "Mon, 25 Dec 2017 14:39:28 GMT"},
        {"Connection", "keep-alive"}],
       request_url: "https://apitest.authorize.net/xml/v1/request.api",
       status_code: 200}}
    end

    def bad_id_capture do
      {:ok,
      %HTTPoison.Response{body: "﻿<?xml version=\"1.0\" encoding=\"utf-8\"?><createTransactionResponse xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\" xmlns:xsd=\"http://www.w3.org/2001/XMLSchema\" xmlns=\"AnetApi/xml/v1/schema/AnetApiSchema.xsd\"><refId>123456</refId><messages><resultCode>Error</resultCode><message><code>E00027</code><text>The transaction was unsuccessful.</text></message></messages><transactionResponse><responseCode>3</responseCode><authCode /><avsResultCode>P</avsResultCode><cvvResultCode /><cavvResultCode /><transId>0</transId><refTransID /><transHash>A5280E2A6AA1290D451A24286692D1B0</transHash><testRequest>0</testRequest><accountNumber /><accountType /><errors><error><errorCode>33</errorCode><errorText>A valid referenced transaction ID is required.</errorText></error></errors><transHashSha2 /></transactionResponse></createTransactionResponse>",
       headers: [{"Cache-Control", "private"},
        {"Content-Type", "application/xml; charset=utf-8"},
        {"X-OPNET-Transaction-Trace",
         "a2_b6b84b43-d399-4dde-bc12-fb1f8ccf4b27-51156-15784805"},
        {"Access-Control-Allow-Origin", "*"},
        {"Access-Control-Allow-Methods", "PUT,OPTIONS,POST,GET"},
        {"Access-Control-Allow-Headers",
         "x-requested-with,cache-control,content-type,origin,method,SOAPAction"},
        {"Access-Control-Allow-Credentials", "true"}, {"X-Cnection", "close"},
        {"Content-Length", "843"}, {"Date", "Mon, 25 Dec 2017 14:45:32 GMT"},
        {"Connection", "keep-alive"}],
       request_url: "https://apitest.authorize.net/xml/v1/request.api",
       status_code: 200}}
    end

    # refund mock response
    def successful_refund_response do
      {:ok,
      %HTTPoison.Response{body: "﻿<?xml version=\"1.0\" encoding=\"utf-8\"?><createTransactionResponse xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\" xmlns:xsd=\"http://www.w3.org/2001/XMLSchema\" xmlns=\"AnetApi/xml/v1/schema/AnetApiSchema.xsd\"><refId>123456</refId><messages><resultCode>Ok</resultCode><message><code>I00001</code><text>Successful.</text></message></messages><transactionResponse><responseCode>1</responseCode><authCode /><avsResultCode>P</avsResultCode><cvvResultCode /><cavvResultCode /><transId>60036855661</transId><refTransID>60036752756</refTransID><transHash>169F2381B172A5AA247A01757A3E520A</transHash><testRequest>0</testRequest><accountNumber>XXXX0015</accountNumber><accountType>MasterCard</accountType><messages><message><code>1</code><description>This transaction has been approved.</description></message></messages><transHashSha2 /></transactionResponse></createTransactionResponse>",
       headers: [{"Cache-Control", "private"},
        {"Content-Type", "application/xml; charset=utf-8"},
        {"X-OPNET-Transaction-Trace",
         "a2_f2f80544-1a98-4ad7-989b-8d267ebf5043-56152-12678232"},
        {"Access-Control-Allow-Origin", "*"},
        {"Access-Control-Allow-Methods", "PUT,OPTIONS,POST,GET"},
        {"Access-Control-Allow-Headers",
         "x-requested-with,cache-control,content-type,origin,method,SOAPAction"},
        {"Access-Control-Allow-Credentials", "true"}, {"X-Cnection", "close"},
        {"Content-Length", "884"}, {"Date", "Mon, 25 Dec 2017 15:22:19 GMT"},
        {"Connection", "keep-alive"}],
       request_url: "https://apitest.authorize.net/xml/v1/request.api",
       status_code: 200}}   
    end

    def bad_card_refund do
      {:ok,
      %HTTPoison.Response{body: "﻿<?xml version=\"1.0\" encoding=\"utf-8\"?><ErrorResponse xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\" xmlns:xsd=\"http://www.w3.org/2001/XMLSchema\" xmlns=\"AnetApi/xml/v1/schema/AnetApiSchema.xsd\"><messages><resultCode>Error</resultCode><message><code>E00003</code><text>The 'AnetApi/xml/v1/schema/AnetApiSchema.xsd:cardNumber' element is invalid - The value XX is invalid according to its datatype 'String' - The actual length is less than the MinLength value.</text></message></messages></ErrorResponse>",
       headers: [{"Cache-Control", "private"},
        {"Content-Type", "application/xml; charset=utf-8"},
        {"X-OPNET-Transaction-Trace",
         "a2_b6b84b43-d399-4dde-bc12-fb1f8ccf4b27-51156-15795999"},
        {"Access-Control-Allow-Origin", "*"},
        {"Access-Control-Allow-Methods", "PUT,OPTIONS,POST,GET"},
        {"Access-Control-Allow-Headers",
         "x-requested-with,cache-control,content-type,origin,method,SOAPAction"},
        {"Access-Control-Allow-Credentials", "true"}, {"X-Cnection", "close"},
        {"Content-Length", "511"}, {"Date", "Mon, 25 Dec 2017 15:21:20 GMT"},
        {"Connection", "keep-alive"}],
       request_url: "https://apitest.authorize.net/xml/v1/request.api",
       status_code: 200}}
    end

    def debit_less_than_refund do
      {:ok,
      %HTTPoison.Response{body: "﻿<?xml version=\"1.0\" encoding=\"utf-8\"?><createTransactionResponse xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\" xmlns:xsd=\"http://www.w3.org/2001/XMLSchema\" xmlns=\"AnetApi/xml/v1/schema/AnetApiSchema.xsd\"><refId>123456</refId><messages><resultCode>Error</resultCode><message><code>E00027</code><text>The transaction was unsuccessful.</text></message></messages><transactionResponse><responseCode>3</responseCode><authCode /><avsResultCode>P</avsResultCode><cvvResultCode /><cavvResultCode /><transId>0</transId><refTransID>60036752756</refTransID><transHash>A5280E2A6AA1290D451A24286692D1B0</transHash><testRequest>0</testRequest><accountNumber>XXXX0015</accountNumber><accountType>MasterCard</accountType><errors><error><errorCode>55</errorCode><errorText>The sum of credits against the referenced transaction would exceed original debit amount.</errorText></error></errors><transHashSha2 /></transactionResponse></createTransactionResponse>",
       headers: [{"Cache-Control", "private"},
        {"Content-Type", "application/xml; charset=utf-8"},
        {"X-OPNET-Transaction-Trace",
         "a2_f2f80544-1a98-4ad7-989b-8d267ebf5043-56152-12681460"},
        {"Access-Control-Allow-Origin", "*"},
        {"Access-Control-Allow-Methods", "PUT,OPTIONS,POST,GET"},
        {"Access-Control-Allow-Headers",
         "x-requested-with,cache-control,content-type,origin,method,SOAPAction"},
        {"Access-Control-Allow-Credentials", "true"}, {"X-Cnection", "close"},
        {"Content-Length", "952"}, {"Date", "Mon, 25 Dec 2017 15:39:25 GMT"},
        {"Connection", "keep-alive"}],
       request_url: "https://apitest.authorize.net/xml/v1/request.api",
       status_code: 200}}
    end

    # void mock response
    def successful_void do
      {:ok,
      %HTTPoison.Response{body: "﻿<?xml version=\"1.0\" encoding=\"utf-8\"?><createTransactionResponse xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\" xmlns:xsd=\"http://www.w3.org/2001/XMLSchema\" xmlns=\"AnetApi/xml/v1/schema/AnetApiSchema.xsd\"><refId>123456</refId><messages><resultCode>Ok</resultCode><message><code>I00001</code><text>Successful.</text></message></messages><transactionResponse><responseCode>1</responseCode><authCode>ZJPVRX</authCode><avsResultCode>P</avsResultCode><cvvResultCode /><cavvResultCode /><transId>60036855217</transId><refTransID>60036855217</refTransID><transHash>F09A215511891DCEA91B6CC52B9F4E87</transHash><testRequest>0</testRequest><accountNumber>XXXX0015</accountNumber><accountType>MasterCard</accountType><messages><message><code>1</code><description>This transaction has been approved.</description></message></messages><transHashSha2 /></transactionResponse></createTransactionResponse>",
       headers: [{"Cache-Control", "private"},
        {"Content-Type", "application/xml; charset=utf-8"},
        {"X-OPNET-Transaction-Trace",
         "a2_f2f80544-1a98-4ad7-989b-8d267ebf5043-56152-12682366"},
        {"Access-Control-Allow-Origin", "*"},
        {"Access-Control-Allow-Methods", "PUT,OPTIONS,POST,GET"},
        {"Access-Control-Allow-Headers",
         "x-requested-with,cache-control,content-type,origin,method,SOAPAction"},
        {"Access-Control-Allow-Credentials", "true"}, {"X-Cnection", "close"},
        {"Content-Length", "899"}, {"Date", "Mon, 25 Dec 2017 15:43:56 GMT"},
        {"Connection", "keep-alive"}],
       request_url: "https://apitest.authorize.net/xml/v1/request.api",
       status_code: 200}}     
    end

    def void_non_existent_id do
      {:ok,
      %HTTPoison.Response{body: "﻿<?xml version=\"1.0\" encoding=\"utf-8\"?><createTransactionResponse xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\" xmlns:xsd=\"http://www.w3.org/2001/XMLSchema\" xmlns=\"AnetApi/xml/v1/schema/AnetApiSchema.xsd\"><refId>123456</refId><messages><resultCode>Error</resultCode><message><code>E00027</code><text>The transaction was unsuccessful.</text></message></messages><transactionResponse><responseCode>3</responseCode><authCode /><avsResultCode>P</avsResultCode><cvvResultCode /><cavvResultCode /><transId>0</transId><refTransID>60036855219</refTransID><transHash>C7C56F020A2AE2660A87637CD00B4D5C</transHash><testRequest>0</testRequest><accountNumber /><accountType /><errors><error><errorCode>16</errorCode><errorText>The transaction cannot be found.</errorText></error></errors><shipTo /><transHashSha2 /></transactionResponse></createTransactionResponse>",
       headers: [{"Cache-Control", "private"},
        {"Content-Type", "application/xml; charset=utf-8"},
        {"X-OPNET-Transaction-Trace",
         "a2_b6b84b43-d399-4dde-bc12-fb1f8ccf4b27-51156-15801470"},
        {"Access-Control-Allow-Origin", "*"},
        {"Access-Control-Allow-Methods", "PUT,OPTIONS,POST,GET"},
        {"Access-Control-Allow-Headers",
         "x-requested-with,cache-control,content-type,origin,method,SOAPAction"},
        {"Access-Control-Allow-Credentials", "true"}, {"X-Cnection", "close"},
        {"Content-Length", "861"}, {"Date", "Mon, 25 Dec 2017 15:49:38 GMT"},
        {"Connection", "keep-alive"}],
       request_url: "https://apitest.authorize.net/xml/v1/request.api",
       status_code: 200}}     
    end

    # store mock response

    def successful_store_response do
      {:ok,
      %HTTPoison.Response{body: "﻿<?xml version=\"1.0\" encoding=\"utf-8\"?><createCustomerProfileResponse xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\" xmlns:xsd=\"http://www.w3.org/2001/XMLSchema\" xmlns=\"AnetApi/xml/v1/schema/AnetApiSchema.xsd\"><messages><resultCode>Ok</resultCode><message><code>I00001</code><text>Successful.</text></message></messages><customerProfileId>1813991490</customerProfileId><customerPaymentProfileIdList><numericString>1808649724</numericString></customerPaymentProfileIdList><customerShippingAddressIdList /><validationDirectResponseList /></createCustomerProfileResponse>",
       headers: [{"Cache-Control", "private"},
        {"Content-Type", "application/xml; charset=utf-8"},
        {"X-OPNET-Transaction-Trace",
         "a2_b6b84b43-d399-4dde-bc12-fb1f8ccf4b27-51156-15829721"},
        {"Access-Control-Allow-Origin", "*"},
        {"Access-Control-Allow-Methods", "PUT,OPTIONS,POST,GET"},
        {"Access-Control-Allow-Headers",
         "x-requested-with,cache-control,content-type,origin,method,SOAPAction"},
        {"Access-Control-Allow-Credentials", "true"}, {"X-Cnection", "close"},
        {"Content-Length", "577"}, {"Date", "Mon, 25 Dec 2017 17:08:12 GMT"},
        {"Connection", "keep-alive"}],
       request_url: "https://apitest.authorize.net/xml/v1/request.api",
       status_code: 200}}
    end
    
    def store_without_profile_fields do
      {:ok,
      %HTTPoison.Response{body: "﻿<?xml version=\"1.0\" encoding=\"utf-8\"?><createCustomerProfileResponse xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\" xmlns:xsd=\"http://www.w3.org/2001/XMLSchema\" xmlns=\"AnetApi/xml/v1/schema/AnetApiSchema.xsd\"><messages><resultCode>Error</resultCode><message><code>E00041</code><text>One or more fields in the profile must contain a value.</text></message></messages></createCustomerProfileResponse>",
       headers: [{"Cache-Control", "private"},
        {"Content-Type", "application/xml; charset=utf-8"},
        {"X-OPNET-Transaction-Trace",
         "a2_b6b84b43-d399-4dde-bc12-fb1f8ccf4b27-51156-15831457"},
        {"Access-Control-Allow-Origin", "*"},
        {"Access-Control-Allow-Methods", "PUT,OPTIONS,POST,GET"},
        {"Access-Control-Allow-Headers",
         "x-requested-with,cache-control,content-type,origin,method,SOAPAction"},
        {"Access-Control-Allow-Credentials", "true"}, {"X-Cnection", "close"},
        {"Content-Length", "408"}, {"Date", "Mon, 25 Dec 2017 17:12:30 GMT"},
        {"Connection", "keep-alive"}],
       request_url: "https://apitest.authorize.net/xml/v1/request.api",
       status_code: 200}} 
    end

    #unstore mock response
    def successful_unstore_response do
      {:ok,
      %HTTPoison.Response{body: "﻿<?xml version=\"1.0\" encoding=\"utf-8\"?><deleteCustomerProfileResponse xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\" xmlns:xsd=\"http://www.w3.org/2001/XMLSchema\" xmlns=\"AnetApi/xml/v1/schema/AnetApiSchema.xsd\"><messages><resultCode>Ok</resultCode><message><code>I00001</code><text>Successful.</text></message></messages></deleteCustomerProfileResponse>",
       headers: [{"Cache-Control", "private"},
        {"Content-Type", "application/xml; charset=utf-8"},
        {"X-OPNET-Transaction-Trace",
         "a2_b6b84b43-d399-4dde-bc12-fb1f8ccf4b27-51156-15833786"},
        {"Access-Control-Allow-Origin", "*"},
        {"Access-Control-Allow-Methods", "PUT,OPTIONS,POST,GET"},
        {"Access-Control-Allow-Headers",
         "x-requested-with,cache-control,content-type,origin,method,SOAPAction"},
        {"Access-Control-Allow-Credentials", "true"}, {"X-Cnection", "close"},
        {"Content-Length", "361"}, {"Date", "Mon, 25 Dec 2017 17:21:20 GMT"},
        {"Connection", "keep-alive"}],
       request_url: "https://apitest.authorize.net/xml/v1/request.api",
       status_code: 200}}     
    end

    def network_error_response do
      body = "no response error"
      {:error, %{body: body, status_code: 500}}
    end
  end
