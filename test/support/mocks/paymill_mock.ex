defmodule Gringotts.Gateways.PaymillMock do
  @moduledoc false

  def auth_success do
    ~s/{ "data":{ "id":"preauth_7f0a5b2787d0acb96db5", "amount":"4200",
    "currency":"EUR", "description":"description example", "status":"closed",
    "livemode":false, "created_at":1523890381, "updated_at":1523890383,
    "app_id":null, "payment":{ "id":"pay_abdd833557398641e9dfcc47",
    "type":"creditcard", "client":"client_d8b9c9a37b0ecb1bbd83",
    "card_type":"mastercard", "country":"DE", "expire_month":"12",
    "expire_year":"2018", "card_holder":"Harry Potter", "last4":"0004",
    "updated_at":1522922164, "created_at":1522922164, "app_id":null,
    "is_recurring":true, "is_usable_for_preauthorization":true }, "client":{
    "id":"client_d8b9c9a37b0ecb1bbd83", "email":null, "description":null,
    "app_id":null, "updated_at":1522922164, "created_at":1522922164, "payment":[
    "pay_abdd833557398641e9dfcc47" ], "subscription":null }, "transaction":{
    "id":"tran_7341c475993e3ddbbff801c47597", "amount":4200,
    "origin_amount":4200, "status":"preauth", "description":"description example",
    "livemode":false, "refunds":null,
    "client":"client_d8b9c9a37b0ecb1bbd83", "currency":"EUR",
    "created_at":1523890381, "updated_at":1523890383, "response_code":20000,
    "short_id":null, "is_fraud":false, "invoices":[ ], "app_id":null,
    "preauthorization":"preauth_7f0a5b2787d0acb96db5", "fees":[ ],
    "payment":"pay_abdd833557398641e9dfcc47", "mandate_reference":null,
    "is_refundable":false, "is_markable_as_fraud":true } }, "mode":"test" }/
  end

  def auth_purchase_invalid_token do
    ~s/{ "error":{ "messages":{
      "regexNotMatch":"'tok_d26e611c47d64693a281e841193' does not match against pattern '\/^[a-zA-Z0-9_]{32}$\/'"
    }, "field":"token" } }/
  end

  def purchase_valid_token do
    ~s/{ "data":{ "id":"tran_de77d38b85d6eee2984accc8b2cc", "amount":4200,
    "origin_amount":4200, "status":"closed", "description":"", "livemode":false,
    "refunds":null, "client":{ "id":"client_d8b9c9a37b0ecb1bbd83", "email":null,
    "description":null, "app_id":null, "updated_at":1522922164,
    "created_at":1522922164, "payment":[ "pay_abdd833557398641e9dfcc47" ],
    "subscription":null }, "currency":"EUR", "created_at":1524135111,
    "updated_at":1524135111, "response_code":20000, "short_id":"0000.9999.0000",
    "is_fraud":false, "invoices":[ ], "app_id":null, "preauthorization":null,
    "fees":[ ], "payment":{ "id":"pay_abdd833557398641e9dfcc47",
    "type":"creditcard", "client":"client_d8b9c9a37b0ecb1bbd83",
    "card_type":"mastercard", "country":"DE", "expire_month":"12",
    "expire_year":"2018", "card_holder":"Sagar Karwande", "last4":"0004",
    "updated_at":1522922164, "created_at":1522922164, "app_id":null,
    "is_recurring":true, "is_usable_for_preauthorization":true },
    "mandate_reference":null, "is_refundable":true, "is_markable_as_fraud":true
    }, "mode":"test" }/
  end

  def refund_success do
    ~s/{ "data":{ "id":"refund_96a0c66456a55ba3e746", "amount":4200,
    "status":"refunded", "description":null, "livemode":false,
    "created_at":1524138133, "updated_at":1524138133,
    "short_id":"0000.9999.0000", "response_code":20000, "reason":null,
    "app_id":null, "transaction":{ "id":"tran_de77d38b85d6eee2984accc8b2cc",
    "amount":0, "origin_amount":4200, "status":"refunded", "description":"",
    "livemode":false, "refunds":[ "refund_96a0c66456a55ba3e746" ],
    "client":"client_d8b9c9a37b0ecb1bbd83", "currency":"EUR",
    "created_at":1524135111, "updated_at":1524138134, "response_code":20000,
    "short_id":"0000.9999.0000", "is_fraud":false, "invoices":[ ],
    "app_id":null, "preauthorization":null, "fees":[ ],
    "payment":"pay_abdd833557398641e9dfcc47", "mandate_reference":null,
    "is_refundable":false, "is_markable_as_fraud":true } }, "mode":"test" }/
  end

  def refund_again do
    ~s/{ "exception":"refund_amount_to_high", "error":"Amount to high" }/
  end

  def refund_bad_transaction do
    ~s/{ "exception":"transaction_not_found", "error":"Transaction not found" }/
  end

  def capture_success do
    ~s/{ "data":{ "id":"tran_2f46c44c4d5219e4ef4b7c6292ba", "amount":4200,
    "origin_amount":4200, "status":"closed", "description":"", "livemode":false,
    "refunds":null, "client":{ "id":"client_d8b9c9a37b0ecb1bbd83", "email":null,
    "description":null, "app_id":null, "updated_at":1522922164,
    "created_at":1522922164, "payment":[ "pay_abdd833557398641e9dfcc47" ],
    "subscription":null }, "currency":"EUR", "created_at":1524138666,
    "updated_at":1524138699, "response_code":20000, "short_id":"0000.9999.0000",
    "is_fraud":false, "invoices":[ ], "app_id":null, "preauthorization":{
    "id":"preauth_d654694c8116109af903", "amount":"4200", "currency":"EUR",
    "description":"description example", "status":"closed", "livemode":false,
    "created_at":1524138666, "updated_at":1524138669, "app_id":null,
    "payment":"pay_abdd833557398641e9dfcc47",
    "client":"client_d8b9c9a37b0ecb1bbd83",
    "transaction":"tran_2f46c44c4d5219e4ef4b7c6292ba" }, "fees":[ ], "payment":{
    "id":"pay_abdd833557398641e9dfcc47", "type":"creditcard",
    "client":"client_d8b9c9a37b0ecb1bbd83", "card_type":"mastercard",
    "country":"DE", "expire_month":"12", "expire_year":"2018",
    "card_holder":"Sagar Karwande", "last4":"0004", "updated_at":1522922164,
    "created_at":1522922164, "app_id":null, "is_recurring":true,
    "is_usable_for_preauthorization":true }, "mandate_reference":null,
    "is_refundable":true, "is_markable_as_fraud":true }, "mode":"test" }/
  end

  def bad_preauth do
    ~s/{ "exception":"not_found_transaction_preauthorize", "error":"Preauthorize not found" }/
  end

  def capture_preauth_done_before do
    ~s/{ "exception":"preauthorization_already_used", "error":"Preauthorization has already been used" }/
  end

  def void_success do
    ~s/{ "data":{ "id":"preauth_0bfc975c2858980a6023",
  "amount":"4200", "currency":"EUR", "description":"description example",
  "status":"deleted", "livemode":false, "created_at":1524140381,
  "updated_at":1524140479, "app_id":null, "payment":{
  "id":"pay_abdd833557398641e9dfcc47", "type":"creditcard",
  "client":"client_d8b9c9a37b0ecb1bbd83", "card_type":"mastercard",
  "country":"DE", "expire_month":"12", "expire_year":"2018",
  "card_holder":"Sagar Karwande", "last4":"0004", "updated_at":1522922164,
  "created_at":1522922164, "app_id":null, "is_recurring":true,
  "is_usable_for_preauthorization":true }, "client":{
  "id":"client_d8b9c9a37b0ecb1bbd83", "email":null, "description":null,
  "app_id":null, "updated_at":1522922164, "created_at":1522922164, "payment":[
  "pay_abdd833557398641e9dfcc47" ], "subscription":null }, "transaction":{
  "id":"tran_f360d805dce7f84baf07077a7f96", "amount":4200, "origin_amount":4200,
  "status":"failed", "description":"description example", "livemode":false,
  "refunds":null, "client":"client_d8b9c9a37b0ecb1bbd83", "currency":"EUR",
  "created_at":1524140381, "updated_at":1524140479, "response_code":50810,
  "short_id":null, "is_fraud":false, "invoices":[ ], "app_id":null,
  "preauthorization":"preauth_0bfc975c2858980a6023", "fees":[ ],
  "payment":"pay_abdd833557398641e9dfcc47", "mandate_reference":null,
  "is_refundable":false, "is_markable_as_fraud":true } }, "mode":"test" }/
  end

  def void_done_before do
    ~s/{ "exception":"preauthorization_not_found", "error":"Preauthorization was not found" }/
  end
end
