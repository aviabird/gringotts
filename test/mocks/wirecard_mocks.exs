defmodule Gringotts.Gateways.WireCardMock do
  # Authorization success
  def successful_authorization_response do
    {:ok, %{"WIRECARD_BXML" => %{"W_RESPONSE" => %{"W_JOB" => %{"FNC_CC_PREAUTHORIZATION" => %{"CC_TRANSACTION" => %{"PROCESSING_STATUS" => %{"AVS" => %{"AuthorizationEntity" => "5",
                 "AuthorizationEntityMessage" => "Response provided by issuer processor.",
                 "Message" => "AVS Unavailable.", "ProviderResultCode" => "I",
                 "ProviderResultMessage" => "Address information is unavailable, or the Issuer does not support AVS. Acquirer has representment rights.",
                 "ResultCode" => "U"}, "AuthorizationCode" => "914683",
               "CVCResponseCode" => "P", "FunctionResult" => "ACK",
               "GuWID" => "C621878151436146500573",
               "Info" => "THIS IS A DEMO TRANSACTION USING CREDIT CARD NUMBER 420000****0000. NO REAL MONEY WILL BE TRANSFERED.",
               "StatusType" => "INFO", "TimeStamp" => "2017-12-27 08:57:45"},
             "TransactionID" => "1"}, "FunctionID" => "dummy_description"},
         "JobID" => %{}}},
     "{http://www.w3.org/1999/XMLSchema-instance}noNamespaceSchemaLocation" => "wirecard.xsd"}}}
  end

  def wrong_creditcard_authorization_response do
    {:ok, %{"WIRECARD_BXML" => %{"W_RESPONSE" => %{"W_JOB" => %{"FNC_CC_PREAUTHORIZATION" => %{"CC_TRANSACTION" => %{"PROCESSING_STATUS" => %{"AuthorizationCode" => %{},
               "ERROR" => %{"Advice" => "Only demo card number is allowed for VISA in demo mode.",
                 "Message" => "Credit card number not allowed in demo mode.",
                 "Number" => "24997", "Type" => "DATA_ERROR"},
               "FunctionResult" => "NOK", "GuWID" => "C828112151436189571040",
               "StatusType" => "INFO", "TimeStamp" => "2017-12-27 09:04:55"},
             "TransactionID" => "1"}, "FunctionID" => "dummy_description"},
         "JobID" => %{}}},
     "{http://www.w3.org/1999/XMLSchema-instance}noNamespaceSchemaLocation" => "wirecard.xsd"}}}
  end

  # Capture success
  def successful_capture_response do
    {:ok, %{"WIRECARD_BXML" => %{"W_RESPONSE" => %{"W_JOB" => %{"FNC_CC_CAPTURE" => %{"CC_TRANSACTION" => %{"PROCESSING_STATUS" => %{"AuthorizationCode" => "600306",
               "CVCResponseCode" => "P", "FunctionResult" => "PENDING",
               "GuWID" => "C801119151436209066299",
               "Info" => "THIS IS A DEMO TRANSACTION USING CREDIT CARD NUMBER 420000****0000. NO REAL MONEY WILL BE TRANSFERED.",
               "StatusType" => "INFO", "TimeStamp" => "2017-12-27 09:08:10"},
             "TransactionID" => "1"}, "FunctionID" => "dummy_description"},
         "JobID" => %{}}},
     "{http://www.w3.org/1999/XMLSchema-instance}noNamespaceSchemaLocation" => "wirecard.xsd"}}}
  end

  # Capture failure
  def unauthorized_capture_response do
    {:ok, %{"WIRECARD_BXML" => %{"W_RESPONSE" => %{"W_JOB" => %{"FNC_CC_CAPTURE" => %{"CC_TRANSACTION" => %{"PROCESSING_STATUS" => %{"AuthorizationCode" => %{},
               "ERROR" => %{"Message" => "Could not find referenced transaction for GuWID 1234567890123456789012.",
                 "Number" => "20080", "Type" => "DATA_ERROR"},
               "FunctionResult" => "NOK", "GuWID" => "C837754151436226322557",
               "StatusType" => "INFO", "TimeStamp" => "2017-12-27 09:11:03"},
             "TransactionID" => "1"}, "FunctionID" => "dummy_description"}, 
         "JobID" => %{}}},
     "{http://www.w3.org/1999/XMLSchema-instance}noNamespaceSchemaLocation" => "wirecard.xsd"}}}
  end

  # Purchase success
  def successful_purchase_response do
    {:ok, %{"WIRECARD_BXML" => %{"W_RESPONSE" => %{"W_JOB" => %{"FNC_CC_PURCHASE" => %{"CC_TRANSACTION" => %{"PROCESSING_STATUS" => %{"AuthorizationCode" => "531750",
               "FunctionResult" => "ACK", "GuWID" => "C865402121385575982910",
               "Info" => "THIS IS A DEMO TRANSACTION USING CREDIT CARD NUMBER 420000****0000. NO REAL MONEY WILL BE TRANSFERED.",
               "StatusType" => "INFO", "TimeStamp" => "2008-06-19 08:09:19"},
             "TransactionID" => "1"},
           "FunctionID" => "Wirecard remote test purchase"},
         "JobID" => "test dummy data"}},
     "{http://www.w3.org/1999/XMLSchema-instance}noNamespaceSchemaLocation" => "wirecard.xsd"}}}
  end

  # Refund success
  def successful_refund_response do
    {:ok, %{"WIRECARD_BXML" => %{"W_RESPONSE" => %{"W_JOB" => %{"FNC_CC_BOOKBACK" => %{"CC_TRANSACTION" => %{"PROCESSING_STATUS" => %{"AuthorizationCode" => "424492",
               "FunctionResult" => "ACK", "GuWID" => "C898842138247065382261",
               "Info" => "All good!", "StatusType" => "INFO",
               "TimeStamp" => "2013-10-22 21:37:33"},
             "TransactionID" => "2a486b3ab747df694d5460c3cb444591"},
           "FunctionID" => %{}}, "JobID" => %{}}},
     "{http://www.w3.org/1999/XMLSchema-instance}noNamespaceSchemaLocation" => "wirecard.xsd"}}}
  end

  # Refund Failed
  def failed_refund_response do
    {:ok, %{"WIRECARD_BXML" => %{"W_RESPONSE" => %{"W_JOB" => %{"FNC_CC_BOOKBACK" => %{"CC_TRANSACTION" => %{"PROCESSING_STATUS" => %{"AuthorizationCode" => %{},
               "ERROR" => %{"Message" => "Not prudent", "Number" => "20080",
                 "Type" => "DATA_ERROR"}, "FunctionResult" => "NOK",
               "GuWID" => "C999187138247102291030", "StatusType" => "INFO",
               "TimeStamp" => "2013-10-22 21:43:42"},
             "TransactionID" => "98680cbeee81d32e94a2b71397ffdf88"},
           "FunctionID" => %{}}, "JobID" => %{}}},
     "{http://www.w3.org/1999/XMLSchema-instance}noNamespaceSchemaLocation" => "wirecard.xsd"}}}
  end

  # Void Success
  def successful_void_response do
    {:ok, %{"WIRECARD_BXML" => %{"W_RESPONSE" => %{"W_JOB" => %{"FNC_CC_REVERSAL" => %{"CC_TRANSACTION" => %{"PROCESSING_STATUS" => %{"AuthorizationCode" => "802187",
               "FunctionResult" => "ACK", "GuWID" => "C907807138247383379288",
               "Info" => "Nice one!", "StatusType" => "INFO",
               "TimeStamp" => "2013-10-22 22:30:33"},
             "TransactionID" => "5f1a2ab3fb2ed7a6aaa0eea74dc109e2"},
           "FunctionID" => %{}}, "JobID" => %{}}},
     "{http://www.w3.org/1999/XMLSchema-instance}noNamespaceSchemaLocation" => "wirecard.xsd"}}}
  end
  
  # Void Failed  
  def failed_void_response do
    {:ok, %{"WIRECARD_BXML" => %{"W_RESPONSE" => %{"W_JOB" => %{"FNC_CC_REVERSAL" => %{"CC_TRANSACTION" => %{"PROCESSING_STATUS" => %{"AuthorizationCode" => %{},
               "ERROR" => %{"Message" => "Not gonna do it", "Number" => "20080", 
                 "Type" => "DATA_ERROR"}, "FunctionResult" => "NOK",
               "GuWID" => "C941776138247400010330", "StatusType" => "INFO",
               "TimeStamp" => "2013-10-22 22:33:20"},
             "TransactionID" => "c11154e9395cf03c49bd68ec5c7087cc"},
           "FunctionID" => %{}}, "JobID" => %{}}},
     "{http://www.w3.org/1999/XMLSchema-instance}noNamespaceSchemaLocation" => "wirecard.xsd"}}}
  end

  # Purchase failure
  def wrong_creditcard_purchase_response do
    {:ok, %{"WIRECARD_BXML" => %{"W_RESPONSE" => %{"W_JOB" => %{"FNC_CC_PURCHASE" => %{"CC_TRANSACTION" => %{"PROCESSING_STATUS" => %{"AuthorizationCode" => %{},
               "ERROR" => %{"Advice" => "Only demo card number '4200000000000000' is allowed for VISA in demo mode.",
                 "Message" => "Credit card number not allowed in demo mode.",
                 "Number" => "24997", "Type" => "DATA_ERROR"},
               "FunctionResult" => "NOK", "GuWID" => "C824697121385153203112",
               "StatusType" => "INFO", "TimeStamp" => "2008-06-19 06:58:51"},
             "TransactionID" => "1"},
           "FunctionID" => "Wirecard remote test purchase"},
         "JobID" => "test dummy data"}},
     "{http://www.w3.org/1999/XMLSchema-instance}noNamespaceSchemaLocation" => "wirecard.xsd"}}}
  end

  # AVS failure
  def failed_avs_response do
    {:ok, %{"WIRECARD_BXML" => %{"W_RESPONSE" => %{"W_JOB" => %{"FNC_CC_PURCHASE" => %{"CC_TRANSACTION" => %{"PROCESSING_STATUS" => %{"AVS" => %{"AuthorizationEntity" => "5",
                 "AuthorizationEntityMessage" => "Response provided by issuer processor.",
                 "Message" => "AVS Unavailable.", "ProviderResultCode" => "A",
                 "ProviderResultMessage" => "Address information is unavailable, or the Issuer does not support AVS. Acquirer has representment rights.",
                 "ResultCode" => "U"}, "AuthorizationCode" => "732129",
               "FunctionResult" => "PENDING",
               "GuWID" => "C997753139988691610455",
               "Info" => "THIS IS A DEMO TRANSACTION USING CREDIT CARD NUMBER 420000****0000. NO REAL MONEY WILL BE TRANSFERED.",
               "StatusType" => "INFO", "TimeStamp" => "2014-05-12 11:28:36"},
             "TransactionID" => "E0BCBF30B82D0131000000000000E4CF"},
           "FunctionID" => %{}}, "JobID" => %{}}},
     "{http://www.w3.org/1999/XMLSchema-instance}noNamespaceSchemaLocation" => "wirecard.xsd"}}}
  end

  def system_error_response do
    {:ok, %{"WIRECARD_BXML" => %{"W_RESPONSE" => %{"W_JOB" => %{"FNC_CC_PURCHASE" => %{"CC_TRANSACTION" => %{"PROCESSING_STATUS" => %{"AuthorizationCode" => %{},
               "ERROR" => %{"Message" => %{}, "Number" => "20205", 
                 "Type" => "SYSTEM_ERROR"}, "FunctionResult" => "NOK",
               "GuWID" => "C967464140265180577024",
               "Info" => "THIS IS A DEMO TRANSACTION USING CREDIT CARD NUMBER 420000****0000. NO REAL MONEY WILL BE TRANSFERED.",
               "StatusType" => "INFO", "TimeStamp" => "2014-06-13 11:30:05"},
             "TransactionID" => "3A368E50D50B01310000000000009153"},
           "FunctionID" => %{}}, "JobID" => %{}}},
     "{http://www.w3.org/1999/XMLSchema-instance}noNamespaceSchemaLocation" => "wirecard.xsd"}}}
  end

  def system_error_response_without_job do
    {:ok, %{"WIRECARD_BXML" => %{"W_RESPONSE" => %{"ERROR" => %{"Message" => "Job Refused",
         "Number" => "10003", "Type" => "SYSTEM_ERROR"}},
     "{http://www.w3.org/1999/XMLSchema-instance}noNamespaceSchemaLocation" => "wirecard.xsd"}}}
  end

  def transcript do
    {:ok, %{"WIRECARD_BXML" => %{"W_REQUEST" => %{"W_JOB" => %{"BusinessCaseSignature" => "00000031629CAFD5",
         "FNC_CC_PURCHASE" => %{"CC_TRANSACTION" => %{"Amount" => "100",
             "CORPTRUSTCENTER_DATA" => %{"ADDRESS" => %{"Address1" => "456 My Street",
                 "Address2" => "Apt 1", "City" => "Ottawa", "Country" => "CA", 
                 "Email" => "soleone@example.com", "State" => "ON",
                 "ZipCode" => "K1C2N6"}},
             "CREDIT_CARD_DATA" => %{"CVC2" => "123",
               "CardHolderName" => "Longbob Longsen",
               "CreditCardNumber" => "4200000000000000",
               "ExpirationMonth" => "09", "ExpirationYear" => "2016"},
             "CountryCode" => "CA", "Currency" => "EUR",
             "RECURRING_TRANSACTION" => %{"Type" => "Single"},
             "TransactionID" => "1"},
           "FunctionID" => "Wirecard remote test purchase"}, "JobID" => %{}}}}}}
  end

  def scrubbed_transcript do
    {:ok, %{"WIRECARD_BXML" => %{"W_REQUEST" => %{"W_JOB" => %{"BusinessCaseSignature" => "00000031629CAFD5",
         "FNC_CC_PURCHASE" => %{"CC_TRANSACTION" => %{"Amount" => "100",
             "CORPTRUSTCENTER_DATA" => %{"ADDRESS" => %{"Address1" => "456 My Street",
                 "Address2" => "Apt 1", "City" => "Ottawa", "Country" => "CA", 
                 "Email" => "soleone@example.com", "State" => "ON",
                 "ZipCode" => "K1C2N6"}},
             "CREDIT_CARD_DATA" => %{"CVC2" => "[FILTERED]",
               "CardHolderName" => "Longbob Longsen",
               "CreditCardNumber" => "[FILTERED]", "ExpirationMonth" => "09",
               "ExpirationYear" => "2016"}, "CountryCode" => "CA",
             "Currency" => "EUR",
             "RECURRING_TRANSACTION" => %{"Type" => "Single"},
             "TransactionID" => "1"},
           "FunctionID" => "Wirecard remote test purchase"}, "JobID" => %{}}}}}}
  end
end
