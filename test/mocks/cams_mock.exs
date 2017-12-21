defmodule Gringotts.Gateways.CamsMock do
	def successful_purchase_response do
		{:ok,
		%HTTPoison.Response{body: "response=1&responsetext=SUCCESS&authcode=123456&transactionid=3916017714&avsresponse=N&cvvresponse=N&orderid=&type=sale&response_code=100",
		 headers: [{"Date", "Thu, 21 Dec 2017 12:45:16 GMT"}, {"Server", "Apache"},
			{"Content-Length", "137"}, {"Content-Type", "text/html; charset=UTF-8"}],
		 request_url: "https://secure.centralams.com/gw/api/transact.php",
		 status_code: 200}}		 
	end
	def failed_purchase_with_bad_credit_card do
		{:ok,
		%HTTPoison.Response{body: "response=3&responsetext=Invalid Credit Card Number REFID:3502947912&authcode=&transactionid=&avsresponse=&cvvresponse=&orderid=&type=sale&response_code=300",
		 headers: [{"Date", "Thu, 21 Dec 2017 13:20:08 GMT"}, {"Server", "Apache"},
			{"Content-Length", "155"}, {"Content-Type", "text/html; charset=UTF-8"}],
		 request_url: "https://secure.centralams.com/gw/api/transact.php",
		 status_code: 200}}			 
	end
	def failed_purchase_with_bad_money do
		{:ok,
		%HTTPoison.Response{body: "response=3&responsetext=Invalid amount REFID:3502949755&authcode=&transactionid=&avsresponse=&cvvresponse=&orderid=&type=sale&response_code=300",
		 headers: [{"Date", "Thu, 21 Dec 2017 13:50:20 GMT"}, {"Server", "Apache"},
		  {"Content-Length", "143"}, {"Content-Type", "text/html; charset=UTF-8"}],
		 request_url: "https://secure.centralams.com/gw/api/transact.php",
		 status_code: 200}}
	end
 
end
    