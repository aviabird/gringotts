 defmodule Gringotts.Gateways.TrexleMock do

    def test_for_purchase_with_valid_card do
      %HTTPoison.Response{
        body: "{\"response\":{\"token\":\"charge_3e89c6f073606ac1efe62e76e22dd7885441dc72\",\"success\":true,\"captured\":false}}",
        headers: [
          {"Date", "Fri, 22 Dec 2017 11:57:28 GMT"},
          {"Content-Type", "application/json; charset=UTF-8"},
          {"ETag", "W/\"5a9f44c457a4fdd0478c82ec1af64816\""},
          {"Cache-Control", "max-age=0, private, must-revalidate"},
          {"X-Request-Id", "9b2a1d30-9bca-48f2-862e-4090766689cb"},
          {"X-Runtime", "0.777520"}, 
          {"Content-Length", "104"},
          {"X-Powered-By", "PleskLin"}
        ],
      request_url: "https://core.trexle.com/api/v1//charges", status_code: 201}
    end

    def test_for_purchase_with_invalid_card do    
      %HTTPoison.Response{
        body: "{\"error\":\"Payment failed\",\"detail\":\"Your card's expiration year is invalid.\"}",
        headers: [
          {"Date", "Fri, 22 Dec 2017 13:20:50 GMT"},
          {"Content-Type", "application/json; charset=UTF-8"},
          {"Cache-Control", "no-cache"},
          {"X-Request-Id", "eb8100a1-8ffa-47da-9623-8d3b2af51b84"},
          {"X-Runtime", "0.445244"}, 
          {"Content-Length", "77"},
          {"X-Powered-By", "PleskLin"}, 
          {"Connection", "close"}
        ],
      request_url: "https://core.trexle.com/api/v1//charges", status_code: 400}    
    end

    def test_for_purchase_with_invalid_amount do
      %HTTPoison.Response{
        body: "{\"error\":\"Payment failed\",\"detail\":\"Amount must be at least 50 cents\"}",
        headers: [
          {"Date", "Sat, 23 Dec 2017 18:16:33 GMT"},
          {"Content-Type", "application/json; charset=UTF-8"},
          {"Cache-Control", "no-cache"},
          {"X-Request-Id", "4ce2eea4-3ea9-4345-ac85-9bc45f22f5ac"},
          {"X-Runtime", "0.476058"}, 
          {"Content-Length", "70"},
          {"X-Powered-By", "PleskLin"}, 
          {"Connection", "close"}
        ],
      request_url: "https://core.trexle.com/api/v1//charges", status_code: 400} 
    end

    def test_for_authorize_with_valid_card do 
      %HTTPoison.Response{
        body: "{\"response\":{\"token\":\"charge_8ab2b21a2f02495f5c36b34d129c8a0e836add32\",\"success\":true,\"captured\":false}}",
        headers: [
          {"Date", "Sat, 23 Dec 2017 18:33:31 GMT"},
          {"Content-Type", "application/json; charset=UTF-8"},
          {"ETag", "W/\"ec4f2df0607614f67286ac46eb994150\""},
          {"Cache-Control", "max-age=0, private, must-revalidate"},
          {"X-Request-Id", "51d28d13-81e5-41fd-b711-1b6531fdd3dd"},
          {"X-Runtime", "0.738395"}, 
          {"Content-Length", "104"},
          {"X-Powered-By", "PleskLin"}
        ],
      request_url: "https://core.trexle.com/api/v1//charges", status_code: 201}
    end

    def test_for_authorize_with_invalid_card do
      %HTTPoison.Response{
        body: "{\"error\":\"Payment failed\",\"detail\":\"Your card's expiration year is invalid.\"}",
        headers: [
          {"Date", "Sat, 23 Dec 2017 18:25:40 GMT"},
          {"Content-Type", "application/json; charset=UTF-8"},
          {"Cache-Control", "no-cache"},
          {"X-Request-Id", "239e7054-9500-4a87-bf3b-09456d550b6d"},
          {"X-Runtime", "0.466670"}, 
          {"Content-Length", "77"},
          {"X-Powered-By", "PleskLin"}, 
          {"Connection", "close"}
        ],
      request_url: "https://core.trexle.com/api/v1//charges", status_code: 400} 
    end

    def test_for_authorize_with_invalid_amount do
      %HTTPoison.Response{
      body: "{\"error\":\"Payment failed\",\"detail\":\"Amount must be at least 50 cents\"}",
      headers: [
        {"Date", "Sat, 23 Dec 2017 18:40:10 GMT"},
        {"Content-Type", "application/json; charset=UTF-8"},
        {"Cache-Control", "no-cache"},
        {"X-Request-Id", "d58db806-8016-4a0e-8519-403a969fa1a7"},
        {"X-Runtime", "0.494636"}, 
        {"Content-Length", "70"},
        {"X-Powered-By", "PleskLin"}, 
        {"Connection", "close"}
      ],
      request_url: "https://core.trexle.com/api/v1//charges", status_code: 400} 
    end

    def test_for_authorize_with_missing_ip_address do
      %{"error" => "something went wrong, please try again later"}
    end

    def test_for_refund_with_valid_token do 
      %HTTPoison.Response{
        body: "{\"response\":{\"token\":\"refund_a86a757cc6bdabab50d6ebbfcdcd4db4e04198dd\",\"success\":true,\"amount\":50,\"charge\":\"charge_cb17a0c34e870a479dfa13bd873e7ce7e090ec9b\",\"status_message\":\"Transaction approved\"}}",
        headers: [
          {"Date", "Sat, 23 Dec 2017 18:55:41 GMT"},
          {"Content-Type", "application/json; charset=UTF-8"},
          {"ETag", "W/\"7410ae0b45094aadada390f5c947a58a\""},
          {"Cache-Control", "max-age=0, private, must-revalidate"},
          {"X-Request-Id", "b1c94703-7fb4-48f2-b1b4-32e3b6a87e57"},
          {"X-Runtime", "1.097186"}, 
          {"Content-Length", "198"},
          {"X-Powered-By", "PleskLin"}
        ],
        request_url: "https://core.trexle.com/api/v1//charges/charge_cb17a0c34e870a479dfa13bd873e7ce7e090ec9b/refunds",
      status_code: 201}
    end

    def test_for_refund_with_invalid_token do
      %HTTPoison.Response{
        body: "{\"error\":\"Refund failed\",\"detail\":\"invalid token\"}",
        headers: [
          {"Date", "Sat, 23 Dec 2017 18:53:09 GMT"},
          {"Content-Type", "application/json; charset=UTF-8"},
          {"Cache-Control", "no-cache"},
          {"X-Request-Id", "276fd8f5-dc21-40be-8add-fa76aabbfc5b"},
          {"X-Runtime", "0.009374"}, 
          {"Content-Length", "50"},
          {"X-Powered-By", "PleskLin"}, 
          {"Connection", "close"}
        ],
        request_url: "https://core.trexle.com/api/v1//charges/34/refunds",
      status_code: 400}
    end

    def test_for_capture_with_valid_chargetoken do 
      %HTTPoison.Response{
        body: "{\"response\":{\"token\":\"charge_cb17a0c34e870a479dfa13bd873e7ce7e090ec9b\",\"success\":true,\"captured\":true,\"amount\":50,\"status_message\":\"Transaction approved\"}}",
        headers: [
          {"Date", "Sat, 23 Dec 2017 18:49:50 GMT"},
          {"Content-Type", "application/json; charset=UTF-8"},
          {"ETag", "W/\"26f05a32c0d0a27b180bbe777488fd5f\""},
          {"Cache-Control", "max-age=0, private, must-revalidate"},
          {"X-Request-Id", "97ca2db6-fd4f-4a5b-ae45-01fae9c13668"},
          {"X-Runtime", "1.092051"}, 
          {"Content-Length", "155"},
          {"X-Powered-By", "PleskLin"}
        ],
        request_url: "https://core.trexle.com/api/v1//charges/charge_cb17a0c34e870a479dfa13bd873e7ce7e090ec9b/capture",
      status_code: 200}
    end

    def test_for_capture_with_invalid_chargetoken do 
      %HTTPoison.Response{
        body: "{\"error\":\"Capture failed\",\"detail\":\"invalid token\"}",
        headers: [
          {"Date", "Sat, 23 Dec 2017 18:47:18 GMT"},
          {"Content-Type", "application/json; charset=UTF-8"},
          {"Cache-Control", "no-cache"},
          {"X-Request-Id", "b46ecb8d-7df8-4c5f-b87f-c53fae364e79"},
          {"X-Runtime", "0.010255"}, 
          {"Content-Length", "51"},
          {"X-Powered-By", "PleskLin"}, 
          {"Connection", "close"}
        ],
        request_url: "https://core.trexle.com/api/v1//charges/30/capture",
      status_code: 400}
    end

    def test_for_store_with_valid_card do
      %HTTPoison.Response{
        body: "{\"response\":{\"token\":\"token_94e333959850270460e89a86bad2246613528cbb\",\"card\":{\"token\":\"token_2a1ba29522e4a377fafa62e8e204f76ad8ba8f1e\",\"scheme\":\"master\",\"display_number\":\"XXXX-XXXX-XXXX-8210\",\"expiry_year\":2018,\"expiry_month\":1,\"cvc\":123,\"name\":\"John Doe\",\"address_line1\":\"456 My Street\",\"address_line2\":null,\"address_city\":\"Ottawa\",\"address_state\":\"ON\",\"address_postcode\":\"K1C2N6\",\"address_country\":\"CA\",\"primary\":true}}}",
        headers: [
          {"Date", "Sat, 23 Dec 2017 19:32:58 GMT"},
          {"Content-Type", "application/json; charset=UTF-8"},
          {"ETag", "W/\"c4089eabe907fc2327dd565503242b58\""},
          {"Cache-Control", "max-age=0, private, must-revalidate"},
          {"X-Request-Id", "1a334b22-8e01-4e1b-8b58-90dfd0b7c12f"},
          {"X-Runtime", "0.122441"}, 
          {"Content-Length", "422"},
          {"X-Powered-By", "PleskLin"}
        ],
      request_url: "https://core.trexle.com/api/v1//customers", status_code: 201} 
    end

end