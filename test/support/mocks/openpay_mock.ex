defmodule Gringotts.Gateways.OpenpayMock do
  @base_url "https://api.mercadopago.com"

  @moduledoc false
  # purchase mock response
  def successful_purchase_response do
    {:ok,
     %HTTPoison.Response{
       #       body: {"id": 20359978, "date_created": "2019-07-10T10:47:58.000-04:00", "date_approved": "2019-07-10T10:47:58.000-04:00", "date_last_updated": "2019-07-10T10:47:58.000-04:00", "date_of_expiration": null, "money_release_date": "2019-07-24T10:47:58.000-04:00", "operation_type": "regular_payment", "issuer_id": "25", "payment_method_id": "visa", "payment_type_id": "credit_card", "status": "approved"},
       body:
         "{\"id\":24687003,\"date_created\":\"2019-07-10T03:23:38.000-04:00\",\"date_approved\":\"2019-07-10T03:23:38.000-04:00\",\"date_last_updated\":\"2019-07-10T03:23:38.000-04:00\",\"date_of_expiration\":null,\"money_release_date\":\"2020-04-14T03:23:38.000-04:00\",\"operation_type\":\"regular_payment\",\"issuer_id\":\"25\",\"payment_method_id\":\"visa\",\"payment_type_id\":\"credit_card\",\"status\":\"approved\",\"status_detail\":\"accredited\",\"currency_id\":\"BRL\",\"description\":null,\"live_mode\":false,\"sponsor_id\":null,\"authorization_code\":null,\"money_release_schema\":null,\"taxes_amount\":0,\"counter_currency\":null,\"shipping_amount\":0,\"pos_id\":null,\"store_id\":null,\"integrator_id\":null,\"platform_id\":null,\"corporation_id\":null,\"collector_id\":543713181,\"payer\":{\"first_name\":\"Test\",\"last_name\":\"Test\",\"email\":\"test_user_80507629@testuser.com\",\"identification\":{\"number\":\"32659430\",\"type\":\"DNI\"},\"phone\":{\"area_code\":\"01\",\"number\":\"1111-1111\",\"extension\":\"\"},\"type\":\"registered\",\"entity_type\":null,\"id\":\"546439110\"},\"marketplace_owner\":null,\"metadata\":{},\"additional_info\":{\"available_balance\":null,\"nsu_processadora\":null},\"order\":{},\"external_reference\":null,\"transaction_amount\":4500,\"transaction_amount_refunded\":0,\"coupon_amount\":0,\"differential_pricing_id\":null,\"deduction_schema\":null,\"installments\":1,\"transaction_details\":{\"payment_method_reference_id\":null,\"net_received_amount\":4275.45,\"total_paid_amount\":4500,\"overpaid_amount\":0,\"external_resource_url\":null,\"installment_amount\":4500,\"financial_institution\":null,\"payable_deferral_period\":null,\"acquirer_reference\":null},\"fee_details\":[{\"type\":\"mercadopago_fee\",\"amount\":224.55,\"fee_payer\":\"collector\"}],\"captured\":true,\"binary_mode\":false,\"call_for_authorize_id\":null,\"statement_descriptor\":\"ASHISHSINGH\",\"card\":{\"id\":null,\"first_six_digits\":\"450995\",\"last_four_digits\":\"3704\",\"expiration_month\":7,\"expiration_year\":2030,\"date_created\":\"2020-04-14T03:23:38.000-04:00\",\"date_last_updated\":\"2020-04-14T03:23:38.000-04:00\",\"cardholder\":{\"name\":\"Hermoine Grangerr\",\"identification\":{\"number\":null,\"type\":null}}},\"notification_url\":null,\"refunds\":[],\"processing_mode\":\"aggregator\",\"merchant_account_id\":null,\"acquirer\":null,\"merchant_number\":null,\"acquirer_reconciliation\":[]}",
       headers: [
         {"Content-Type", "application/json;charset=UTF-8"},
         {"Transfer-Encoding", "chunked"},
         {"Connection", "keep-alive"},
         {"Cache-Control", "max-age=0"},
         {"ETag", "6d6d1b4a79c868769305de14687c4d6d"},
         {"Vary", "Accept,Accept-Encoding,Accept-Encoding"},
         {"X-Caller-Id", "543713181"},
         {"X-Response-Status", "approved/accredited"},
         {"X-Site-Id", "MLB"},
         {"X-Content-Type-Options", "nosniff"},
         {"X-Request-Id", "59257cf5-6cc6-4afc-b310-e36e412ad4fc"},
         {"X-XSS-Protection", "1; mode=block"},
         {"Strict-Transport-Security", "max-age=16070400; includeSubDomains; preload"},
         {"Access-Control-Allow-Origin", "*"},
         {"Access-Control-Allow-Headers", "Content-Type"},
         {"Access-Control-Allow-Methods", "PUT, GET, POST, DELETE, OPTIONS"},
         {"Access-Control-Max-Age", "86400"},
         {"Timing-Allow-Origin", "*"},
         {"Date", "Mon, 25 Dec 2017 14:17:56 GMT"}
       ],
       request_url: "#{@base_url}/v1/payments",
       status_code: 200
     }}
  end

  def bad_card_purchase_response do
    {:error,
     %HTTPoison.Error{
       reason: "Bad Card for Purchase",
       id: 1_234_567
     }}
  end

  def bad_amount_purchase_response do
    {:error,
     %HTTPoison.Response{
       body:
         "{\"id\": 20359978, \"date_created\": \"2019-07-10T10:47:58.000-04:00\", \"date_approved\": \"2019-07-10T10:47:58.000-04:00\", \"date_last_updated\": \"2019-07-10T10:47:58.000-04:00\", \"date_of_expiration\": null, \"money_release_date\": \"2019-07-24T10:47:58.000-04:00\", \"operation_type\": \"regular_payment\", \"issuer_id\": \"25\", \"payment_method_id\": \"visa\", \"payment_type_id\": \"credit_card\", \"status\": \"approved\"}",
       headers: [
         {"Content-Type", "application/json"},
         {"Access-Control-Allow-Origin", "*"},
         {"Access-Control-Allow-Methods", "PUT,OPTIONS,POST,GET"},
         {"Date", "Mon, 25 Dec 2017 14:17:56 GMT"}
       ],
       request_url: "#{@base_url}/v1/payments",
       status_code: 200
     }}
  end

  # authorize mock response
  def successful_authorize_response do
    {:ok,
     %HTTPoison.Response{
       body:
         "{\"id\": 20359978, \"date_created\": \"2019-07-10T10:47:58.000-04:00\", \"date_approved\": \"2019-07-10T10:47:58.000-04:00\", \"date_last_updated\": \"2019-07-10T10:47:58.000-04:00\", \"date_of_expiration\": null, \"money_release_date\": \"2019-07-24T10:47:58.000-04:00\", \"operation_type\": \"regular_payment\", \"issuer_id\": \"25\", \"payment_method_id\": \"visa\", \"payment_type_id\": \"credit_card\", \"status\": \"approved\"}",
       headers: [
         {"Content-Type", "application/json"},
         {"Access-Control-Allow-Origin", "*"},
         {"Access-Control-Allow-Methods", "PUT,OPTIONS,POST,GET"},
         {"Date", "Mon, 25 Dec 2017 14:17:56 GMT"}
       ],
       request_url: "#{@base_url}/v1/payments",
       status_code: 200
     }}
  end

  def bad_card_authorize_response do
    {:ok,
     %HTTPoison.Response{
       body:
         "{\"id\": 20359978, \"date_created\": \"2019-07-10T10:47:58.000-04:00\", \"date_approved\": \"2019-07-10T10:47:58.000-04:00\", \"date_last_updated\": \"2019-07-10T10:47:58.000-04:00\", \"date_of_expiration\": null, \"money_release_date\": \"2019-07-24T10:47:58.000-04:00\", \"operation_type\": \"regular_payment\", \"issuer_id\": \"25\", \"payment_method_id\": \"visa\", \"payment_type_id\": \"credit_card\", \"status\": \"approved\"}",
       headers: [
         {"Content-Type", "application/json"},
         {"Access-Control-Allow-Origin", "*"},
         {"Access-Control-Allow-Methods", "PUT,OPTIONS,POST,GET"},
         {"Date", "Mon, 25 Dec 2017 14:17:56 GMT"}
       ],
       request_url: "#{@base_url}/v1/payments",
       status_code: 200
     }}
  end

  def bad_amount_authorize_response do
    {:ok,
     %HTTPoison.Response{
       body:
         "{\"id\": 20359978, \"date_created\": \"2019-07-10T10:47:58.000-04:00\", \"date_approved\": \"2019-07-10T10:47:58.000-04:00\", \"date_last_updated\": \"2019-07-10T10:47:58.000-04:00\", \"date_of_expiration\": null, \"money_release_date\": \"2019-07-24T10:47:58.000-04:00\", \"operation_type\": \"regular_payment\", \"issuer_id\": \"25\", \"payment_method_id\": \"visa\", \"payment_type_id\": \"credit_card\", \"status\": \"approved\"}",
       headers: [
         {"Content-Type", "application/json"},
         {"Access-Control-Allow-Origin", "*"},
         {"Access-Control-Allow-Methods", "PUT,OPTIONS,POST,GET"},
         {"Date", "Mon, 25 Dec 2017 14:17:56 GMT"}
       ],
       request_url: "#{@base_url}/v1/payments",
       status_code: 200
     }}
  end

  # capture mock response

  def successful_capture_response do
    {:ok,
     %HTTPoison.Response{
       body:
         "{\"id\": 20359978, \"date_created\": \"2019-07-10T10:47:58.000-04:00\", \"date_approved\": \"2019-07-10T10:47:58.000-04:00\", \"date_last_updated\": \"2019-07-10T10:47:58.000-04:00\", \"date_of_expiration\": null, \"money_release_date\": \"2019-07-24T10:47:58.000-04:00\", \"operation_type\": \"regular_payment\", \"issuer_id\": \"25\", \"payment_method_id\": \"visa\", \"payment_type_id\": \"credit_card\", \"status\": \"approved\"}",
       headers: [
         {"Content-Type", "application/json"},
         {"Access-Control-Allow-Origin", "*"},
         {"Access-Control-Allow-Methods", "PUT,OPTIONS,POST,GET"},
         {"Date", "Mon, 25 Dec 2017 14:17:56 GMT"}
       ],
       request_url: "#{@base_url}/v1/payments",
       status_code: 200
     }}
  end

  def bad_id_capture do
    {:error,
     %HTTPoison.Error{
       reason: "Bad ID for Capture",
       id: 1_234_567
     }}
  end

  # refund mock response
  def successful_refund_response do
    {:ok,
     %HTTPoison.Response{
       body:
         "{\"id\": 20359978, \"payment_id\":24686811, \"unique_sequence_number\":null,\"refund_mode\":\"standard\",\"status\":\"approved\", \"source\":{\"id\":\"543713181\",\"name\":\"Developer Testing\",\"type\":\"collector\"} }",
       headers: [
         {"Date", "Mon, 25 Dec 2017 14:17:56 GMT"},
         {"Content-Type", "application/json"},
         {"Transfer-Encoding", "chunked"},
         {"Connection", "keep-alive"},
         {"Cache-Control", "max-age=0"},
         {"ETag", "e2894bf98b818a4f49a3bd1065a3d9b8"},
         {"Vary", "Accept,Accept-Encoding,Accept-Encoding"},
         {"X-Content-Type-Options", "nosniff"},
         {"X-Request-Id", "f6d28d4c-ce70-4cf4-ac82-5733f826eef6"},
         {"X-XSS-Protection", "1; mode=block"},
         {"Strict-Transport-Security", "max-age=16070400; includeSubDomains; preload"},
         {"Access-Control-Allow-Origin", "*"},
         {"Access-Control-Allow-Headers", "Content-Type"},
         {"Access-Control-Allow-Methods", "PUT,OPTIONS,POST,GET"},
         {"Access-Control-Max-Age", "86400"},
         {"Timing-Allow-Origin", "*"}
       ],
       request_url: "#{@base_url}/v1/payments",
       status_code: 200
     }}
  end

  def bad_card_refund do
    {:error,
     %HTTPoison.Error{
       reason: "Bad Card for refund",
       id: 1_234_567
     }}
  end

  def debit_less_than_refund do
    {:error,
     %HTTPoison.Error{
       reason: "Debit less than refund",
       id: 1_234_567
     }}
  end

  # void mock response
  def successful_void do
    {:ok,
     %HTTPoison.Response{
       body:
         "{\"id\": 20359978, \"date_created\": \"2019-07-10T10:47:58.000-04:00\", \"date_approved\": \"2019-07-10T10:47:58.000-04:00\", \"date_last_updated\": \"2019-07-10T10:47:58.000-04:00\", \"date_of_expiration\": null, \"money_release_date\": \"2019-07-24T10:47:58.000-04:00\", \"operation_type\": \"regular_payment\", \"issuer_id\": \"25\", \"payment_method_id\": \"visa\", \"payment_type_id\": \"credit_card\", \"status\": \"approved\"}",
       headers: [
         {"Content-Type", "application/json"},
         {"Access-Control-Allow-Origin", "*"},
         {"Access-Control-Allow-Methods", "PUT,OPTIONS,POST,GET"},
         {"Date", "Mon, 25 Dec 2017 14:17:56 GMT"}
       ],
       request_url: "#{@base_url}/v1/payments",
       status_code: 200
     }}
  end

  def void_non_existent_id do
    {:error,
     %HTTPoison.Error{
       reason: "Transaction ID does not exist for Void",
       id: 1_234_567
     }}
  end

  def customer_payment_profile_success_response do
    {:ok,
     %HTTPoison.Response{
       body:
         "{\"id\": 20359978, \"date_created\": \"2019-07-10T10:47:58.000-04:00\", \"date_approved\": \"2019-07-10T10:47:58.000-04:00\", \"date_last_updated\": \"2019-07-10T10:47:58.000-04:00\", \"date_of_expiration\": null, \"money_release_date\": \"2019-07-24T10:47:58.000-04:00\", \"operation_type\": \"regular_payment\", \"issuer_id\": \"25\", \"payment_method_id\": \"visa\", \"payment_type_id\": \"credit_card\", \"status\": \"approved\"}",
       headers: [
         {"Content-Type", "application/json"},
         {"Access-Control-Allow-Origin", "*"},
         {"Access-Control-Allow-Methods", "PUT,OPTIONS,POST,GET"},
         {"Date", "Mon, 25 Dec 2017 14:17:56 GMT"}
       ],
       request_url: "#{@base_url}/v1/payments",
       status_code: 200
     }}
  end

  def netwok_error_non_existent_domain do
    {:error, %HTTPoison.Error{id: nil, reason: :nxdomain}}
  end
end
