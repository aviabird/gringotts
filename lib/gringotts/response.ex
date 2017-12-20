defmodule Gringotts.Response do
  @moduledoc ~S"""
  Module which defines the struct for response struct.

  Response struct is a standard response from public API to the application.

    It mostly has such as:-
      * `success`: boolean indicating the status of the transaction
      * `authorization`: token which is used to issue requests without the card info
      * `status_code`: response code
      * `error_code`: error code if there is error else nil
      * `message`: message related to the status of the response
      * `avs_result`: result for address verfication
      * `cvc_result`: result for cvc verification 
      * `params`: original raw response from the gateway
      * `fraud_review`: information related to fraudulent transactions
  """
  
  defstruct [
    :success, :authorization, :status_code, :error_code, :message, 
    :avs_result, :cvc_result, :params, :fraud_review
  ]

  def success(opts \\ []) do
    new(true, opts)
  end

  def error(opts \\ []) do
    new(false, opts)
  end

  defp new(success, opts) do
    Map.merge(%__MODULE__{success: success}, Enum.into(opts, %{}))
  end
end
