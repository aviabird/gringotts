defmodule Kuber.Hex.Gateways.Paymill do
  use Kuber.Hex.Gateways.Base

  @supported_countries ~w(AD AT BE BG CH CY CZ DE DK EE ES FI FO FR GB
                          GI GR HR HU IE IL IM IS IT LI LT LU LV MC MT
                          NL NO PL PT RO SE SI SK TR VA)

  @supported_cartypes [:visa, :master, :american_express, :diners_club, :discover, :union_pay, :jcb]

  @home_page "https://paymill.com"
  @money_format :cents
  @default_currency "EUR"
  @live_url "https://api.paymill.com/v2/"

  def authorize(amount, card, options) do

  end

  defp commit(method, action, parameters) do

  end

end
