defmodule Gringotts.Gateways.PaymillMock do
  @moduledoc false

  def successful_authorize() do
    {:ok,
      %HTTPoison.Response{body: "{\"mode\":\"test\",\"data\":{\"updated_at\":1514371900,\"transaction\":{\"updated_at\":1514371900,\"status\":\"preauth\",\"short_id\":null,\"response_code\":20000,\"refunds\":null,\"preauthorization\":\"preauth_7e160b01c8a570d513e8\",\"payment\":\"pay_a2934f6a2a5f65f6dfa337d3\",\"origin_amount\":100,\"mandate_reference\":null,\"livemode\":false,\"is_refundable\":false,\"is_markable_as_fraud\":true,\"is_frau d\":false,\"invoices\":[],\"id\":\"tran_1352d28a96c3a31b2a145748786f\",\"fees\":[],\"description\":null,\"currency\":\"EUR\",\"created_at\":1514371897,\"client\":\"client_c38ce0f295edc5773027\",\"app_id\":null,\"amount\":100},\"status\":\"closed\",\"payment\":{\"updated_at\":1514371897,\"type\":\"creditcard\",\"last4\":\"1111\",\"is_usable_for_preauthorization\":true,\"is_recurring\":true,\"id\":\"pay_a2934f6a2a5f65f6dfa337d3\",\"expire_year\":\"2018\",\"e xpire_month\":\"12\",\"created_at\":1514371897,\"country\":\"DE\",\"client\":\"client_c38ce0f295edc5773027\",\"card_type\":\"visa\",\"card_holder\":\"Sagar   Karwande\",\"app_id\":null},\"livemode\":false,\"id\":\"preauth_7e160b01c8a570d513e8\",\"description\":null,\"currency\":\"EUR\",\"created_at\":1514371898,\"client\":{\"updated_at\":1514371897,\"subscription\":null,\"payment\":[\"pay_a2934f6a2a5f65f6dfa337d3\"],\"id\":\"client_c38ce0f295edc5773027\",\"email\":null,\"description\":null,\"created_at\":1514371897,\"app_id\":null},\"app_id\":null,\"amount\":\"100\"}}",
      request_url: "https://api.paymill.com/v2.1/preauthorizations",
      status_code: 200}}
  end

  def authorize_invalid_cvv() do
    {:ok,
      %HTTPoison.Response{body: "{\"mode\":\"test\",\"data\":{\"updated_at\":1514373790,\"transaction\":{\"updated_at\":1514373790,\"status\":\"failed\",\"short_id\":null,\"response_code\":50800,\"refunds\":null,\"preauthorization\":\"preauth_8e2cc0cb547097246cfd\",\"payment\":\"pay_ff6f4eafa56f68e1aa894a94\",\"origin_amount\":100,\"mandate_reference\":null,\"livemode\":false,\"is_refundable\":false,\"is_markable_as_fraud\":true,\"is_fraud\":false,\"invoices\":[],\"id\":\"tran_5a0398849b093a193c9a065a40b2\",\"fees\":[],\"description\":null,\"currency\":\"EUR\",\"created_at\":1514373675,\"client\":\"client_08c47a5372b1d96db907\",\"app_id\":null,\"amount\":100},\"status\":\"failed\",\"payment\":{\"updated_at\":1514373675,\"type\":\"creditcard\",\"last4\":\"5100\",\"is_usable_for_preauthorization\":true,\"is_recurring\":true,\"id\":\"pay_ff6f4eafa56f68e1aa894a94\",\"expire_year\":\"2020\",\"expire_month\":\"8\",\"created_at\":1514373675,\"country\":\"DE\",\"client\":\"client_08c47a5372b1d96db907\",\"card_type\":\"mastercard\",\"card_holder\":\"Sagar Karwande\",\"app_id\":null},\"livemode\":false,\"id\":\"preauth_8e2cc0cb547097246cfd\",\"description\":null,\"currency\":\"EUR\",\"created_at\":1514373788,\"client\":{\"updated_at\":1514373675,\"subscription\":null,\"payment\":[\"pay_ff6f4eafa56f68e1aa894a94\"],\"id\":\"client_08c47a5372b1d96db907\",\"email\":null,\"description\":null,\"created_at\":1514373675,\"app_id\":null},\"app_id\":null,\"amount\":\"100\"}}",
      request_url: "https://api.paymill.com/v2.1/preauthorizations",
      status_code: 200}}
  end

  def authorize_invalid_card_token() do
    {:ok, %HTTPoison.Response{body: "{\n\t\"error\":{\n\t\t\"messages\":{\n\t\t\t\"regexNotMatch\":\"'tok_123' does not match against pattern '\\/^[a-zA-Z0-9_]{32}$\\/'\"\n\t\t},\n\t\t\"field\":\"token\"\n\t}\n}",
      request_url: "https://api.paymill.com/v2.1/preauthorizations",
      status_code: 400}}
  end

  def authorize_invalid_currency() do
    {:ok, %HTTPoison.Response{body: "{\n\t\"error\":{\n\t\t\"messages\":{\n\t\t\t\"notInArray\":\"'ABC' was not found in the haystack\"\n\t\t},\n\t\t\"field\":\"currency\"\n\t}\n}",
      request_url: "https://api.paymill.com/v2.1/preauthorizations",
      status_code: 400}}
  end
end
