defmodule Gringotts.Gateways.PinpayTest do
  # The file contains mocked tests for Pinpay
  
  # We recommend using [mock][1] for this, you can place the mock responses from
  # the Gateway in `test/mocks/pin_pay_mock.exs` file, which has also been
  # generated for you.
  #
  # [1]: https://github.com/jjh42/mock
  
  # Load the mock response file before running the tests.
  Code.require_file "../mocks/pin_pay_mock.exs", __DIR__
  
  use ExUnit.Case, async: false
  alias Gringotts.Gateways.Pinpay
  import Mock

  # Group the test cases by public api
  describe "purchase" do
  end

  describe "authorize" do
  end

  describe "capture" do 
  end

  describe "void" do
  end

  describe "refund" do
  end
end
