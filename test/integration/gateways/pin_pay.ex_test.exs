defmodule Gringotts.Integration.Gateways.PinpayTest do
  # Integration tests for the Pinpay 

  use ExUnit.Case, async: false
  alias Gringotts.Gateways.Pinpay

  @moduletag :integration

  setup_all do
    Application.put_env(:gringotts, Gringotts.Gateways.Pinpay,
      [ # some_key: "some_secret_key"
      ]
    )
  end
  
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

  describe "environment setup" do
  end
end
