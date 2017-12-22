 defmodule Gringotts.Gateways.TrexleMock do

    def valid_card_purchase_response do
      {:ok,
       %HTTPoison.Response{body: "{\"response\":{\"token\":\"charge_3e89c6f073606ac1efe62e76e22dd7885441dc72\",\"success\":true,\"captured\":false}}",
        headers: [{"Date", "Fri, 22 Dec 2017 11:57:28 GMT"},
         {"Content-Type", "application/json; charset=UTF-8"},
         {"ETag", "W/\"5a9f44c457a4fdd0478c82ec1af64816\""},
         {"Cache-Control", "max-age=0, private, must-revalidate"},
         {"X-Request-Id", "9b2a1d30-9bca-48f2-862e-4090766689cb"},
         {"X-Runtime", "0.777520"}, {"Content-Length", "104"},
         {"X-Powered-By", "PleskLin"}],
        request_url: "https://core.trexle.com/api/v1//charges", status_code: 201}}
    end

    def invalid_card_purchase_response do
      {:ok,
       %HTTPoison.Response{body: "{\"error\":\"Payment failed\",\"detail\":\"Your card's expiration year is invalid.\"}",
        headers: [{"Date", "Fri, 22 Dec 2017 13:20:50 GMT"},
         {"Content-Type", "application/json; charset=UTF-8"},
         {"Cache-Control", "no-cache"},
         {"X-Request-Id", "eb8100a1-8ffa-47da-9623-8d3b2af51b84"},
         {"X-Runtime", "0.445244"}, {"Content-Length", "77"},
         {"X-Powered-By", "PleskLin"}, {"Connection", "close"}],
        request_url: "https://core.trexle.com/api/v1//charges", status_code: 400}
      }
    end

end