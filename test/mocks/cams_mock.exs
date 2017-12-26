defmodule Gringotts.Gateways.CamsMock do
	def successful_purchase do
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
	
	def with_invalid_currency do
    {:ok,
    %HTTPoison.Response{body: "response=3&responsetext=The cc payment type [Visa] and/or currency [INR] is not accepted REFID:3503238709&authcode=&transactionid=&avsresponse=&cvvresponse=&orderid=&type=auth&response_code=300",
    headers: [{"Date", "Tue, 26 Dec 2017 10:37:42 GMT"}, {"Server", "Apache"},
    {"Content-Length", "193"}, {"Content-Type", "text/html; charset=UTF-8"}],
    request_url: "https://secure.centralams.com/gw/api/transact.php",
    status_code: 200}}   
  end
  
  def successful_capture do
		{:ok,
    %HTTPoison.Response{body: "response=1&responsetext=SUCCESS&authcode=123456&transactionid=3921111362&avsresponse=&cvvresponse=&orderid=&type=capture&response_code=100",
    headers: [{"Date", "Tue, 26 Dec 2017 12:16:55 GMT"}, {"Server", "Apache"},
    {"Content-Length", "138"}, {"Content-Type", "text/html; charset=UTF-8"}],
    request_url: "https://secure.centralams.com/gw/api/transact.php",
    status_code: 200}}     
  end
  def successful_authorize do
    {:ok,
    %HTTPoison.Response{body: "response=1&responsetext=SUCCESS&authcode=123456&transactionid=3921111362&avsresponse=N&cvvresponse=N&orderid=&type=auth&response_code=100",
    headers: [{"Date", "Tue, 26 Dec 2017 12:16:11 GMT"}, {"Server", "Apache"},
    {"Content-Length", "137"}, {"Content-Type", "text/html; charset=UTF-8"}],
    request_url: "https://secure.centralams.com/gw/api/transact.php",
    status_code: 200}}
  end
  def invalid_transaction_id do
    {:ok,
    %HTTPoison.Response{body: "response=3&responsetext=Transaction not found REFID:3503243979&authcode=&transactionid=3921118690&avsresponse=&cvvresponse=&orderid=&type=capture&response_code=300",
    headers: [{"Date", "Tue, 26 Dec 2017 12:39:05 GMT"}, {"Server", "Apache"},
    {"Content-Length", "163"}, {"Content-Type", "text/html; charset=UTF-8"}],
    request_url: "https://secure.centralams.com/gw/api/transact.php",
    status_code: 200}}   
  end 
  def more_than_authorization_amount do  
    {:ok,
    %HTTPoison.Response{body: "response=3&responsetext=The specified amount of 1001 exceeds the authorization amount of 1000.00 REFID:3503244462&authcode=&transactionid=3921127126&avsresponse=&cvvresponse=&orderid=&type=capture&response_code=300",
    headers: [{"Date", "Tue, 26 Dec 2017 13:00:55 GMT"}, {"Server", "Apache"},
    {"Content-Length", "214"}, {"Content-Type", "text/html; charset=UTF-8"}],
    request_url: "https://secure.centralams.com/gw/api/transact.php",
    status_code: 200}}
  end
  def successful_refund do
    {:ok,
    %HTTPoison.Response{body: "response=1&responsetext=SUCCESS&authcode=&transactionid=3921158933&avsresponse=&cvvresponse=&orderid=&type=refund&response_code=100",
    headers: [{"Date", "Tue, 26 Dec 2017 14:00:08 GMT"}, {"Server", "Apache"},
    {"Content-Length", "131"}, {"Content-Type", "text/html; charset=UTF-8"}],
    request_url: "https://secure.centralams.com/gw/api/transact.php",
    status_code: 200}}
  end

  def more_than_purchase_amount do
    {:ok,
    %HTTPoison.Response{body: "response=3&responsetext=Refund amount may not exceed the transaction balance REFID:3503249728&authcode=&transactionid=&avsresponse=&cvvresponse=&orderid=&type=refund&response_code=300",
    headers: [{"Date", "Tue, 26 Dec 2017 14:05:31 GMT"}, {"Server", "Apache"},
    {"Content-Length", "183"}, {"Content-Type", "text/html; charset=UTF-8"}],
    request_url: "https://secure.centralams.com/gw/api/transact.php",
    status_code: 200}}   
  end 
  def successful_void do
    {:ok,
    %HTTPoison.Response{body: "response=1&responsetext=Transaction Void Successful&authcode=123456&transactionid=3921178863&avsresponse=&cvvresponse=&orderid=&type=void&response_code=100",
    headers: [{"Date", "Tue, 26 Dec 2017 14:26:05 GMT"}, {"Server", "Apache"},
    {"Content-Length", "155"}, {"Content-Type", "text/html; charset=UTF-8"}],
    request_url: "https://secure.centralams.com/gw/api/transact.php",
    status_code: 200}} 
  end
 
end




