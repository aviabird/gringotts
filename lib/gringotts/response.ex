defmodule Gringotts.Response do
  @moduledoc ~S"""
  Module which defines the struct for response struct.

  Response struct is a standard response from public API to the application.

  TODO: Add the response struct detail about the attributes in the struct

    It mostly has such as:-
      * `success`: boolean indicating the status of the transaction
      * `authorization`: token which is used to issue requests without the card info
      * `code`: status code for the response
      * `reason`: reason for the error if it happens
      * `avs_result`: TODO: add this
      * `cvc_result`: result for cvc verification 
      * `raw`: TODO: add this
  """
  
  defstruct [:success, :authorization, :code, :reason, :avs_result, :cvc_result, :raw]

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
