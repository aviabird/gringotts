defmodule Gringotts.Integration.Gateways.MercadopagoTest do
  # Integration tests for the Mercadopago 

  use ExUnit.Case, async: false
  alias Gringotts.Gateways.Mercadopago

  @moduletag :integration

  setup_all do
    Application.put_env(
      :gringotts,
      Gringotts.Gateways.Mercadopago,
      public_key: "your_secret_public_key",
      access_token: "your_secret_access_token"
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
