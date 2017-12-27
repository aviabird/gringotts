defmodule Gringotts.Gateways.WireCardMock do
  # Authorization success
  def successful_authorization_response do
    {:ok,
    %HTTPoison.Response{body: ~s{
        <?xml version="1.0" encoding="UTF-8"?>
        <WIRECARD_BXML xmlns:xsi="http://www.w3.org/1999/XMLSchema-instance" xsi:noNamespaceSchemaLocation="wirecard.xsd">
        <W_RESPONSE>
          <W_JOB>
            <JobID>test dummy data</JobID>
            <FNC_CC_PREAUTHORIZATION>
              <FunctionID>Wirecard remote test purchase</FunctionID>
              <CC_TRANSACTION>
                <TransactionID>1</TransactionID>
                <PROCESSING_STATUS>
                  <GuWID>C822580121385121429927</GuWID>
                  <AuthorizationCode>709678</AuthorizationCode>
                  <Info>THIS IS A DEMO TRANSACTION USING CREDIT CARD NUMBER 420000****0000. NO REAL MONEY WILL BE TRANSFERED.</Info>
                  <StatusType>INFO</StatusType>
                  <FunctionResult>ACK</FunctionResult>
                  <TimeStamp>2008-06-19 06:53:33</TimeStamp>
                </PROCESSING_STATUS>
              </CC_TRANSACTION>
            </FNC_CC_PREAUTHORIZATION>
          </W_JOB>
      </W_RESPONSE>
    </WIRECARD_BXML>},
     request_url: "https://c3-test.wirecard.com/secure/ssl-gateway",
     status_code: 200}}  
  end

  def wrong_creditcard_authorization_response do
    {:ok,
    %HTTPoison.Response{body: "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<WIRECARD_BXML xmlns:xsi=\"http://www.w3.org/1999/XMLSchema-instance\" xsi:noNamespaceSchemaLocation=\"wirecard.xsd\">\n\t<W_RESPONSE>\n\t\t<W_JOB>\n\t\t\t<JobID></JobID>\n\t\t\t<FNC_CC_PREAUTHORIZATION>\n\t\t\t\t<FunctionID>dummy_description</FunctionID>\n\t\t\t\t<CC_TRANSACTION>\n\t\t\t\t\t<TransactionID>1</TransactionID>\n\t\t\t\t\t<PROCESSING_STATUS>\n\t\t\t\t\t\t<GuWID>C784893151437179785993</GuWID>\n\t\t\t\t\t\t<AuthorizationCode></AuthorizationCode>\n\t\t\t\t\t\t<StatusType>INFO</StatusType>\n\t\t\t\t\t\t<FunctionResult>NOK</FunctionResult>\n\t\t\t\t\t\t<ERROR>\n\t\t\t\t\t\t\t<Type>DATA_ERROR</Type>\n\t\t\t\t\t\t\t<Number>24997</Number>\n\t\t\t\t\t\t\t<Message>Credit card number not allowed in demo mode.</Message>\n\t\t\t\t\t\t\t<Advice>Only demo card number is allowed for VISA in demo mode.</Advice>\n\t\t\t\t\t\t</ERROR>\n\t\t\t\t\t\t<TimeStamp>2017-12-27 11:49:57</TimeStamp>\n\t\t\t\t\t</PROCESSING_STATUS>\n\t\t\t\t</CC_TRANSACTION>\n\t\t\t</FNC_CC_PREAUTHORIZATION>\n\t\t</W_JOB>\n\t</W_RESPONSE>\n</WIRECARD_BXML>\n",
     request_url: "https://c3-test.wirecard.com/secure/ssl-gateway",
     status_code: 200}}   
  end

  # Capture success
  def successful_capture_response do
    {:ok,
    %HTTPoison.Response{body: ~s{
      <?xml version="1.0" encoding="UTF-8"?>
      <WIRECARD_BXML xmlns:xsi="http://www.w3.org/1999/XMLSchema-instance" xsi:noNamespaceSchemaLocation="wirecard.xsd">
        <W_RESPONSE>
          <W_JOB>
            <JobID>test dummy data</JobID>
            <FNC_CC_CAPTURE>
              <FunctionID>Wirecard remote test purchase</FunctionID>
              <CC_TRANSACTION>
                <TransactionID>1</TransactionID>
                <PROCESSING_STATUS>
                  <GuWID>C833707121385268439116</GuWID>
                  <AuthorizationCode>915025</AuthorizationCode>
                  <Info>THIS IS A DEMO TRANSACTION USING CREDIT CARD NUMBER 420000****0000. NO REAL MONEY WILL BE TRANSFERED.</Info>
                  <StatusType>INFO</StatusType>
                  <FunctionResult>ACK</FunctionResult>
                  <TimeStamp>2008-06-19 07:18:04</TimeStamp>
                </PROCESSING_STATUS>
              </CC_TRANSACTION>
            </FNC_CC_CAPTURE>
          </W_JOB>
        </W_RESPONSE>
      </WIRECARD_BXML>},
     request_url: "https://c3-test.wirecard.com/secure/ssl-gateway",
     status_code: 200}}
  end

  # Capture failure
  def unauthorized_capture_response do
    {:ok, %HTTPoison.Response{body: ~s{
      <?xml version="1.0" encoding="UTF-8"?>
      <WIRECARD_BXML xmlns:xsi="http://www.w3.org/1999/XMLSchema-instance" xsi:noNamespaceSchemaLocation="wirecard.xsd">
        <W_RESPONSE>
          <W_JOB>
            <JobID>test dummy data</JobID>
            <FNC_CC_CAPTURE>
              <FunctionID>Test dummy FunctionID</FunctionID>
              <CC_TRANSACTION>
                <TransactionID>a2783d471ccc98825b8c498f1a62ce8f</TransactionID>
                <PROCESSING_STATUS>
                  <GuWID>C833707121385268439116</GuWID>
                  <AuthorizationCode></AuthorizationCode>
                  <StatusType>INFO</StatusType>
                  <FunctionResult>NOK</FunctionResult>
                  <ERROR>
                    <Type>DATA_ERROR</Type>
                    <Number>20080</Number>
                    <Message>Could not find referenced transaction for GuWID 1234567890123456789012.</Message>
                  </ERROR>
                  <TimeStamp>2008-06-19 08:09:20</TimeStamp>
                </PROCESSING_STATUS>
              </CC_TRANSACTION>
            </FNC_CC_CAPTURE>
          </W_JOB>
        </W_RESPONSE>
      </WIRECARD_BXML>},
     request_url: "https://c3-test.wirecard.com/secure/ssl-gateway",
     status_code: 200}}
  end

  # Purchase success
  def successful_purchase_response do
    {:ok, %HTTPoison.Response{body: ~s{
      <?xml version="1.0" encoding="UTF-8"?>
      <WIRECARD_BXML xmlns:xsi="http://www.w3.org/1999/XMLSchema-instance" xsi:noNamespaceSchemaLocation="wirecard.xsd">
        <W_RESPONSE>
          <W_JOB>
            <JobID>test dummy data</JobID>
            <FNC_CC_PURCHASE>
              <FunctionID>Wirecard remote test purchase</FunctionID>
              <CC_TRANSACTION>
                <TransactionID>1</TransactionID>
                <PROCESSING_STATUS>
                  <GuWID>C865402121385575982910</GuWID>
                  <AuthorizationCode>531750</AuthorizationCode>
                  <Info>THIS IS A DEMO TRANSACTION USING CREDIT CARD NUMBER 420000****0000. NO REAL MONEY WILL BE TRANSFERED.</Info>
                  <StatusType>INFO</StatusType>
                  <FunctionResult>ACK</FunctionResult>
                  <TimeStamp>2008-06-19 08:09:19</TimeStamp>
                </PROCESSING_STATUS>
              </CC_TRANSACTION>
            </FNC_CC_PURCHASE>
          </W_JOB>
        </W_RESPONSE>
      </WIRECARD_BXML>},
      request_url: "https://c3-test.wirecard.com/secure/ssl-gateway",
      status_code: 200}}
  end

  # Refund success
  def successful_refund_response do
    {:ok, %HTTPoison.Response{body: ~s{
      <?xml version="1.0" encoding="UTF-8"?>
      <WIRECARD_BXML xmlns:xsi="http://www.w3.org/1999/XMLSchema-instance" xsi:noNamespaceSchemaLocation="wirecard.xsd">
          <W_RESPONSE>
              <W_JOB>
                <JobID></JobID>
                <FNC_CC_BOOKBACK>
                  <FunctionID></FunctionID>
                  <CC_TRANSACTION>
                    <TransactionID>2a486b3ab747df694d5460c3cb444591</TransactionID>
                    <PROCESSING_STATUS>
                      <GuWID>C898842138247065382261</GuWID>
                      <AuthorizationCode>424492</AuthorizationCode>
                      <Info>All good!</Info>
                      <StatusType>INFO</StatusType>
                      <FunctionResult>ACK</FunctionResult>
                      <TimeStamp>2013-10-22 21:37:33</TimeStamp>
                    </PROCESSING_STATUS>
                  </CC_TRANSACTION>
                </FNC_CC_BOOKBACK>
              </W_JOB>
          </W_RESPONSE>
      </WIRECARD_BXML>},
      request_url: "https://c3-test.wirecard.com/secure/ssl-gateway",
      status_code: 200}}
  end

  # Refund Failed
  def failed_refund_response do
    {:ok, %HTTPoison.Response{body: ~s{
      <?xml version="1.0" encoding="UTF-8"?>
      <WIRECARD_BXML xmlns:xsi="http://www.w3.org/1999/XMLSchema-instance" xsi:noNamespaceSchemaLocation="wirecard.xsd">
        <W_RESPONSE>
          <W_JOB>
            <JobID></JobID>
            <FNC_CC_BOOKBACK>
              <FunctionID></FunctionID>
              <CC_TRANSACTION>
                  <TransactionID>98680cbeee81d32e94a2b71397ffdf88</TransactionID>
                  <PROCESSING_STATUS>
                    <GuWID>C999187138247102291030</GuWID>
                    <AuthorizationCode></AuthorizationCode>
                    <StatusType>INFO</StatusType>
                    <FunctionResult>NOK</FunctionResult>
                    <ERROR>
                        <Type>DATA_ERROR</Type>
                        <Number>20080</Number>
                        <Message>Not prudent</Message>
                    </ERROR>
                    <TimeStamp>2013-10-22 21:43:42</TimeStamp>
                  </PROCESSING_STATUS>
              </CC_TRANSACTION>
            </FNC_CC_BOOKBACK>
          </W_JOB>
        </W_RESPONSE>
      </WIRECARD_BXML>},
      request_url: "https://c3-test.wirecard.com/secure/ssl-gateway",
      status_code: 200}}

  end

  # Void Success
  def successful_void_response do
    {:ok, %HTTPoison.Response{body: ~s{
      <?xml version="1.0" encoding="UTF-8"?>
      <WIRECARD_BXML xmlns:xsi="http://www.w3.org/1999/XMLSchema-instance" xsi:noNamespaceSchemaLocation="wirecard.xsd">
       <W_RESPONSE>
         <W_JOB>
           <JobID></JobID>
           <FNC_CC_REVERSAL>
             <FunctionID></FunctionID>
             <CC_TRANSACTION>
               <TransactionID>5f1a2ab3fb2ed7a6aaa0eea74dc109e2</TransactionID>
               <PROCESSING_STATUS>
                 <GuWID>C907807138247383379288</GuWID>
                 <AuthorizationCode>802187</AuthorizationCode>
                 <Info>Nice one!</Info>
                 <StatusType>INFO</StatusType>
                 <FunctionResult>ACK</FunctionResult>
                 <TimeStamp>2013-10-22 22:30:33</TimeStamp>
               </PROCESSING_STATUS>
             </CC_TRANSACTION>
           </FNC_CC_REVERSAL>
         </W_JOB>
       </W_RESPONSE>
     </WIRECARD_BXML>},
      request_url: "https://c3-test.wirecard.com/secure/ssl-gateway",
      status_code: 200}}
  end
  
  # Void Failed  
  def failed_void_response do
    {:ok, %HTTPoison.Response{body: ~s{
      <?xml version="1.0" encoding="UTF-8"?>
      <WIRECARD_BXML xmlns:xsi="http://www.w3.org/1999/XMLSchema-instance" xsi:noNamespaceSchemaLocation="wirecard.xsd">
          <W_RESPONSE>
              <W_JOB>
                <JobID></JobID>
                <FNC_CC_REVERSAL>
                  <FunctionID></FunctionID>
                  <CC_TRANSACTION>
                    <TransactionID>c11154e9395cf03c49bd68ec5c7087cc</TransactionID>
                    <PROCESSING_STATUS>
                      <GuWID>C941776138247400010330</GuWID>
                      <AuthorizationCode></AuthorizationCode>
                      <StatusType>INFO</StatusType>
                      <FunctionResult>NOK</FunctionResult>
                      <ERROR>
                          <Type>DATA_ERROR</Type>
                          <Number>20080</Number>
                          <Message>Not gonna do it</Message>
                      </ERROR>
                      <TimeStamp>2013-10-22 22:33:20</TimeStamp>
                    </PROCESSING_STATUS>
                  </CC_TRANSACTION>
                </FNC_CC_REVERSAL>
              </W_JOB>
          </W_RESPONSE>
      </WIRECARD_BXML>},
      request_url: "https://c3-test.wirecard.com/secure/ssl-gateway",
      status_code: 200}}
  end

  # Purchase failure
  def wrong_creditcard_purchase_response do
    {:ok, %HTTPoison.Response{body: ~s{
      <?xml version="1.0" encoding="UTF-8"?>
      <WIRECARD_BXML xmlns:xsi="http://www.w3.org/1999/XMLSchema-instance" xsi:noNamespaceSchemaLocation="wirecard.xsd">
        <W_RESPONSE>
          <W_JOB>
            <JobID>test dummy data</JobID>
            <FNC_CC_PURCHASE>
              <FunctionID>Wirecard remote test purchase</FunctionID>
              <CC_TRANSACTION>
                <TransactionID>1</TransactionID>
                <PROCESSING_STATUS>
                  <GuWID>C824697121385153203112</GuWID>
                  <AuthorizationCode></AuthorizationCode>
                  <StatusType>INFO</StatusType>
                  <FunctionResult>NOK</FunctionResult>
                  <ERROR>
                    <Type>DATA_ERROR</Type>                                                    <Number>24997</Number>
                    <Message>Credit card number not allowed in demo mode.</Message>
                    <Advice>Only demo card number '4200000000000000' is allowed for VISA in demo mode.</Advice>
                  </ERROR>
                  <TimeStamp>2008-06-19 06:58:51</TimeStamp>
                </PROCESSING_STATUS>
              </CC_TRANSACTION>
            </FNC_CC_PURCHASE>
          </W_JOB>
        </W_RESPONSE>
      </WIRECARD_BXML>},
      request_url: "https://c3-test.wirecard.com/secure/ssl-gateway",
      status_code: 200}}
  end

  # AVS failure
  def failed_avs_response do
    {:ok, %HTTPoison.Response{body: ~s{
      <?xml version="1.0" encoding="UTF-8"?>
      <WIRECARD_BXML xmlns:xsi="http://www.w3.org/1999/XMLSchema-instance" xsi:noNamespaceSchemaLocation="wirecard.xsd">
        <W_RESPONSE>
          <W_JOB>
            <JobID></JobID>
            <FNC_CC_PURCHASE>
              <FunctionID></FunctionID>
              <CC_TRANSACTION>
                <TransactionID>E0BCBF30B82D0131000000000000E4CF</TransactionID>
                <PROCESSING_STATUS>
                  <GuWID>C997753139988691610455</GuWID>
                  <AuthorizationCode>732129</AuthorizationCode>
                  <Info>THIS IS A DEMO TRANSACTION USING CREDIT CARD NUMBER 420000****0000. NO REAL MONEY WILL BE TRANSFERED.</Info>
                  <StatusType>INFO</StatusType>
                  <FunctionResult>PENDING</FunctionResult>
                  <AVS>
                    <ResultCode>U</ResultCode>
                    <Message>AVS Unavailable.</Message>
                    <AuthorizationEntity>5</AuthorizationEntity>
                    <AuthorizationEntityMessage>Response provided by issuer processor.</AuthorizationEntityMessage>
                    <ProviderResultCode>A</ProviderResultCode>
                    <ProviderResultMessage>Address information is unavailable, or the Issuer does not support AVS. Acquirer has representment rights.</ProviderResultMessage>
                  </AVS>
                  <TimeStamp>2014-05-12 11:28:36</TimeStamp>
                </PROCESSING_STATUS>
              </CC_TRANSACTION>
            </FNC_CC_PURCHASE>
          </W_JOB>
        </W_RESPONSE>
      </WIRECARD_BXML>},
      request_url: "https://c3-test.wirecard.com/secure/ssl-gateway",
      status_code: 200}}
  end

  def system_error_response do
    {:ok, %HTTPoison.Response{body: ~s{
      <?xml version="1.0" encoding="UTF-8"?>
      <WIRECARD_BXML xmlns:xsi="http://www.w3.org/1999/XMLSchema-instance" xsi:noNamespaceSchemaLocation="wirecard.xsd">
        <W_RESPONSE>
          <W_JOB>
            <JobID></JobID>
            <FNC_CC_PURCHASE>
              <FunctionID></FunctionID>
              <CC_TRANSACTION>
                <TransactionID>3A368E50D50B01310000000000009153</TransactionID>
                <PROCESSING_STATUS>
                  <GuWID>C967464140265180577024</GuWID>
                  <AuthorizationCode></AuthorizationCode>
                  <Info>THIS IS A DEMO TRANSACTION USING CREDIT CARD NUMBER 420000****0000. NO REAL MONEY WILL BE TRANSFERED.</Info>
                  <StatusType>INFO</StatusType>
                  <FunctionResult>NOK</FunctionResult>
                  <ERROR>
                    <Type>SYSTEM_ERROR</Type>
                    <Number>20205</Number>
                    <Message></Message>
                  </ERROR>
                  <TimeStamp>2014-06-13 11:30:05</TimeStamp>
                </PROCESSING_STATUS>
              </CC_TRANSACTION>
            </FNC_CC_PURCHASE>
          </W_JOB>
        </W_RESPONSE>
      </WIRECARD_BXML>},
      request_url: "https://c3-test.wirecard.com/secure/ssl-gateway",
      status_code: 200}}

  end

  def system_error_response_without_job do
    {:ok, %HTTPoison.Response{body: ~s{
      <?xml version="1.0" encoding="UTF-8"?>
      <WIRECARD_BXML xmlns:xsi="http://www.w3.org/1999/XMLSchema-instance" xsi:noNamespaceSchemaLocation="wirecard.xsd">
        <W_RESPONSE>
          <ERROR>
            <Type>SYSTEM_ERROR</Type>
            <Number>10003</Number>
            <Message>Job Refused</Message>
          </ERROR>
        </W_RESPONSE>
      </WIRECARD_BXML>},
      request_url: "https://c3-test.wirecard.com/secure/ssl-gateway",
      status_code: 200}}
  end
end
