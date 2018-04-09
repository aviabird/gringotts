defmodule Gringotts.Gateways.PaymillMock do
  @moduledoc false

  def successful_authorize() do
    {:ok,
     %HTTPoison.Response{
       body:
         "{\"mode\":\"test\",\"data\":{\"updated_at\":1514371900,\"transaction\":{\"updated_at\":1514371900,\"status\":\"preauth\",\"short_id\":null,\"response_code\":20000,\"refunds\":null,\"preauthorization\":\"preauth_7e160b01c8a570d513e8\",\"payment\":\"pay_a2934f6a2a5f65f6dfa337d3\",\"origin_amount\":100,\"mandate_reference\":null,\"livemode\":false,\"is_refundable\":false,\"is_markable_as_fraud\":true,\"is_frau d\":false,\"invoices\":[],\"id\":\"tran_1352d28a96c3a31b2a145748786f\",\"fees\":[],\"description\":null,\"currency\":\"EUR\",\"created_at\":1514371897,\"client\":\"client_c38ce0f295edc5773027\",\"app_id\":null,\"amount\":100},\"status\":\"closed\",\"payment\":{\"updated_at\":1514371897,\"type\":\"creditcard\",\"last4\":\"1111\",\"is_usable_for_preauthorization\":true,\"is_recurring\":true,\"id\":\"pay_a2934f6a2a5f65f6dfa337d3\",\"expire_year\":\"2018\",\"e xpire_month\":\"12\",\"created_at\":1514371897,\"country\":\"DE\",\"client\":\"client_c38ce0f295edc5773027\",\"card_type\":\"visa\",\"card_holder\":\"Sagar   Karwande\",\"app_id\":null},\"livemode\":false,\"id\":\"preauth_7e160b01c8a570d513e8\",\"description\":null,\"currency\":\"EUR\",\"created_at\":1514371898,\"client\":{\"updated_at\":1514371897,\"subscription\":null,\"payment\":[\"pay_a2934f6a2a5f65f6dfa337d3\"],\"id\":\"client_c38ce0f295edc5773027\",\"email\":null,\"description\":null,\"created_at\":1514371897,\"app_id\":null},\"app_id\":null,\"amount\":\"100\"}}",
       request_url: "https://api.paymill.com/v2.1/preauthorizations",
       status_code: 200
     }}
  end

  def authorize_invalid_cvv() do
    {:ok,
     %HTTPoison.Response{
       body:
         "{\"mode\":\"test\",\"data\":{\"updated_at\":1514373790,\"transaction\":{\"updated_at\":1514373790,\"status\":\"failed\",\"short_id\":null,\"response_code\":50800,\"refunds\":null,\"preauthorization\":\"preauth_8e2cc0cb547097246cfd\",\"payment\":\"pay_ff6f4eafa56f68e1aa894a94\",\"origin_amount\":100,\"mandate_reference\":null,\"livemode\":false,\"is_refundable\":false,\"is_markable_as_fraud\":true,\"is_fraud\":false,\"invoices\":[],\"id\":\"tran_5a0398849b093a193c9a065a40b2\",\"fees\":[],\"description\":null,\"currency\":\"EUR\",\"created_at\":1514373675,\"client\":\"client_08c47a5372b1d96db907\",\"app_id\":null,\"amount\":100},\"status\":\"failed\",\"payment\":{\"updated_at\":1514373675,\"type\":\"creditcard\",\"last4\":\"5100\",\"is_usable_for_preauthorization\":true,\"is_recurring\":true,\"id\":\"pay_ff6f4eafa56f68e1aa894a94\",\"expire_year\":\"2020\",\"expire_month\":\"8\",\"created_at\":1514373675,\"country\":\"DE\",\"client\":\"client_08c47a5372b1d96db907\",\"card_type\":\"mastercard\",\"card_holder\":\"Sagar Karwande\",\"app_id\":null},\"livemode\":false,\"id\":\"preauth_8e2cc0cb547097246cfd\",\"description\":null,\"currency\":\"EUR\",\"created_at\":1514373788,\"client\":{\"updated_at\":1514373675,\"subscription\":null,\"payment\":[\"pay_ff6f4eafa56f68e1aa894a94\"],\"id\":\"client_08c47a5372b1d96db907\",\"email\":null,\"description\":null,\"created_at\":1514373675,\"app_id\":null},\"app_id\":null,\"amount\":\"100\"}}",
       request_url: "https://api.paymill.com/v2.1/preauthorizations",
       status_code: 200
     }}
  end

  def authorize_invalid_card_token() do
    {:ok,
     %HTTPoison.Response{
       body:
         "{\"error\":{\"messages\":{\"regexNotMatch\":\"'tok_123' does not match against pattern '/^[a-zA-Z0-9_]{32}$/'\"},\"field\":\"token\"}}",
       request_url: "https://api.paymill.com/v2.1/preauthorizations",
       status_code: 400
     }}
  end

  def authorize_invalid_currency() do
    {:ok,
     %HTTPoison.Response{
       body:
         "{\"error\":{\"messages\":{\"notInArray\":\"'ABC' was not found in the haystack\"},\"field\":\"currency\"}}",
       request_url: "https://api.paymill.com/v2.1/preauthorizations",
       status_code: 400
     }}
  end

  def successful_capture() do
    {:ok,
     %HTTPoison.Response{
       body:
         "{\"mode\":\"test\",\"data\":{\"updated_at\":1514396484,\"status\":\"closed\",\"short_id\":\"0000.9999.0000\",\"response_code\":20000,\"refunds\":null,\"preauthorization\":{\"updated_at\":1514396459,\"transaction\":\"tran_478351595d1ec1e65d32d97e2696\",\"status\":\"closed\",\"payment\":\"pay_d9eef5928b69760cd60c4784\",\"livemode\":false,\"id\":\"preauth_7dc9457660b33759b70b\",\"description\":null,\"currency\":\"INR\",\"created_at\":1514396457,\"client\":\"client_436f5667c0835f3adf2c\",\"app_id\":null,\"amount\":\"200\"},\"payment\":{\"updated_at\":1514396441,\"type\":\"creditcard\",\"last4\":\"1111\",\"is_usable_for_preauthorization\":true,\"is_recurring\":true,\"id\":\"pay_d9eef5928b69760cd60c4784\",\"expire_year\":\"2020\",\"expire_month\":\"3\",\"created_at\":1514396441,\"country\":\"DE\",\"client\":\"client_436f5667c0835f3adf2c\",\"card_type\":\"visa\",\"card_holder\":\"Sagar Karwande\",\"app_id\":null},\"origin_amount\":2000,\"mandate_reference\":null,\"livemode\":false,\"is_refundable\":true,\"is_markable_as_fraud\":true,\"is_fraud\":false,\"invoices\":[],\"id\":\"tran_478351595d1ec1e65d32d97e2696\",\"fees\":[],\"description\":\"\",\"currency\":\"EUR\",\"created_at\":1514396441,\"client\":{\"updated_at\":1514396441,\"subscription\":null,\"payment\":[\"pay_d9eef5928b69760cd60c4784\"],\"id\":\"client_436f5667c0835f3adf2c\",\"email\":null,\"description\":null,\"created_at\":1514396441,\"app_id\":null},\"app_id\":null,\"amount\":2000}}",
       request_url: "https://api.paymill.com/v2.1/transactions",
       status_code: 200
     }}
  end

  def capture_with_used_auth do
    {:ok,
     %HTTPoison.Response{
       body:
         "{\"exception\":\"preauthorization_already_used\",\"error\":\"Preauthorization has already been used\"}",
       request_url: "https://api.paymill.com/v2.1/transactions",
       status_code: 409
     }}
  end

  def capture_with_invalid_auth_token do
    {:ok,
     %HTTPoison.Response{
       body:
         "{\"exception\":\"not_found_transaction_preauthorize\",\"error\":\"Preauthorize not found\"}",
       request_url: "https://api.paymill.com/v2.1/transactions",
       status_code: 404
     }}
  end

  def successful_purchase() do
    {:ok,
     %HTTPoison.Response{
       body:
         "{\"mode\":\"test\",\"data\":{\"updated_at\":1514400803,\"status\":\"closed\",\"short_id\":\"0000.9999.0000\",\"response_code\":20000,\"refunds\":null,\"preauthorization\":null,\"payment\":{\"updated_at\":1514400802,\"type\":\"creditcard\",\"last4\":\"1111\",\"is_usable_for_preauthorization\":true,\"is_recurring\":true,\"id\":\"pay_9a09b497432463b3a6ee1ad1\",\"expire_year\":\"2018\",\"expire_month\":\"12\",\"created_at\":1514400802,\"country\":\"DE\",\"client\":\"client_75b88daa13b3d547accd\",\"card_type\":\"visa\",\"card_holder\":\"Sagar Karwande\",\"app_id\":null},\"origin_amount\":100,\"mandate_reference\":null,\"livemode\":false,\"is_refundable\":true,\"is_markable_as_fraud\":true,\"is_fraud\":false,\"invoices\":[],\"id\":\"tran_9d4db278fbf8ef2e997ef42c0a55\",\"fees\":[],\"description\":\"\",\"currency\":\"EUR\",\"created_at\":1514400802,\"client\":{\"updated_at\":1514400802,\"subscription\":null,\"payment\":[\"pay_9a09b497432463b3a6ee1ad1\"],\"id\":\"client_75b88daa13b3d547accd\",\"email\":null,\"description\":null,\"created_at\":1514400802,\"app_id\":null},\"app_id\":null,\"amount\":100}}",
       request_url: "https://api.paymill.com/v2.1/transactions",
       status_code: 200
     }}
  end

  def purchase_with_invalid_card_token do
    {:ok,
     %HTTPoison.Response{
       body:
         "{\"mode\":\"test\",\"data\":{\"updated_at\":1514401924,\"status\":\"failed\",\"short_id\":null,\"response_code\":40102,\"refunds\":null,\"preauthorization\":null,\"payment\":{\"updated_at\":1514401923,\"type\":\"creditcard\",\"last4\":\"\",\"is_usable_for_preauthorization\":true,\"is_recurring\":true,\"id\":\"pay_0e39722b8afa3be3beeaa372\",\"expire_year\":\"\",\"expire_month\":\"\",\"created_at\":1514401923,\"country\":null,\"client\":\"client_51998977a73051f2b0da\",\"card_type\":null,\"card_holder\":\"\",\"app_id\":null},\"origin_amount\":100,\"mandate_reference\":null,\"livemode\":false,\"is_refundable\":false,\"is_markable_as_fraud\":true,\"is_fraud\":false,\"invoices\":[],\"id\":\"tran_3a6cc404cdb1c26065977d988ecd\",\"fees\":[],\"description\":\"\",\"currency\":\"EUR\",\"created_at\":1514401924,\"client\":{\"updated_at\":1514401923,\"subscription\":null,\"payment\":[\"pay_0e39722b8afa3be3beeaa372\"],\"id\":\"client_51998977a73051f2b0da\",\"email\":null,\"description\":null,\"created_at\":1514401923,\"app_id\":null},\"app_id\":null,\"amount\":100}}",
       request_url: "https://api.paymill.com/v2.1/transactions",
       status_code: 403
     }}
  end

  def successful_void do
    {:ok,
     %HTTPoison.Response{
       body:
         "{\"mode\":\"test\",\"data\":{\"updated_at\":1514405187,\"transaction\":{\"updated_at\":1514405187,\"status\":\"failed\",\"short_id\":null,\"response_code\":50810,\"refunds\":null,\"preauthorization\":\"preauth_028b0d40a6465099a774\",\"payment\":\"pay_d9eef5928b69760cd60c4784\",\"origin_amount\":200,\"mandate_reference\":null,\"livemode\":false,\"is_refundable\":false,\"is_markable_as_fraud\":true,\"is_fraud\":false,\"invoices\":[],\"id\":\"tran_2b8f2196ba52cc9c7e56d86d5bd4\",\"fees\":[],\"description\":null,\"currency\":\"INR\",\"created_at\":1514405146,\"client\":\"client_436f5667c0835f3adf2c\",\"app_id\":null,\"amount\":200},\"status\":\"deleted\",\"payment\":{\"updated_at\":1514396441,\"type\":\"creditcard\",\"last4\":\"1111\",\"is_usable_for_preauthorization\":true,\"is_recurring\":true,\"id\":\"pay_d9eef5928b69760cd60c4784\",\"expire_year\":\"2020\",\"expire_month\":\"3\",\"created_at\":1514396441,\"country\":\"DE\",\"client\":\"client_436f5667c0835f3adf2c\",\"card_type\":\"visa\",\"card_holder\":\"Sagar Karwande\",\"app_id\":null},\"livemode\":false,\"id\":\"preauth_028b0d40a6465099a774\",\"description\":null,\"currency\":\"INR\",\"created_at\":1514405146,\"client\":{\"updated_at\":1514396441,\"subscription\":null,\"payment\":[\"pay_d9eef5928b69760cd60c4784\"],\"id\":\"client_436f5667c0835f3adf2c\",\"email\":null,\"description\":null,\"created_at\":1514396441,\"app_id\":null},\"app_id\":null,\"amount\":\"200\"}}",
       request_url: "https://api.paymill.com/v2.1/preauthorizations/preauth_028b0d40a6465099a774",
       status_code: 200
     }}
  end

  def void_with_invalid_auth_token do
    {:ok,
     %HTTPoison.Response{
       body:
         "{\"exception\":\"preauthorization_not_found\",\"error\":\"Preauthorization was not found\"}",
       request_url: "https://api.paymill.com/v2.1/preauthorizations/preauth_028b0d40a6465099a123",
       status_code: 404
     }}
  end

  def successful_refund() do
    {:ok,
     %HTTPoison.Response{
       body:
         "{\"mode\":\"test\",\"data\":{\"updated_at\":1514408064,\"transaction\":{\"updated_at\":1514408064,\"status\":\"refunded\",\"short_id\":\"0000.9999.0000\",\"response_code\":20000,\"refunds\":[\"refund_1840867e0632e776d307\"],\"preauthorization\":null,\"payment\":\"pay_0a22787c797a150f40ad32fc\",\"origin_amount\":100,\"mandate_reference\":null,\"livemode\":false,\"is_refundable\":false,\"is_markable_as_fraud\":true,\"is_fraud\":false,\"invoices\":[],\"id\":\"tran_8e3c8746b274c89930cd2a38ed43\",\"fees\":[],\"description\":\"\",\"currency\":\"EUR\",\"created_at\":1514408006,\"client\":\"client_d9a15a3bc9edd53b7d3b\",\"app_id\":null,\"amount\":0},\"status\":\"refunded\",\"short_id\":\"0000.9999.0000\",\"response_code\":20000,\"reason\":null,\"livemode\":false,\"id\":\"refund_1840867e0632e776d307\",\"description\":null,\"created_at\":1514408064,\"app_id\":null,\"amount\":100}}",
       request_url: "https://api.paymill.com/v2.1/refunds/tran_8e3c8746b274c89930cd2a38ed43",
       status_code: 200
     }}
  end

  def refund_with_invalid_trans_token() do
    {:ok,
     %HTTPoison.Response{
       body: "{\"exception\":\"transaction_not_found\",\"error\":\"Transaction not found\"}",
       request_url: "https://api.paymill.com/v2.1/refunds/tran_8e3c8746b274c89930cd2a38e123",
       status_code: 404
     }}
  end

  def refund_with_high_amount() do
    {:ok,
     %HTTPoison.Response{
       body: "{\"exception\":\"refund_amount_to_high\",\"error\":\"Amount to high\"}",
       request_url: "https://api.paymill.com/v2.1/refunds/tran_d9df8ae460354befe6aee6916fbf",
       status_code: 400
     }}
  end
end
