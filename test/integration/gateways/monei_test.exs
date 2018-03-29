defmodule Gringotts.Integration.Gateways.MoneiTest do
  use ExUnit.Case, async: true

  alias Gringotts.{
    CreditCard
  }

  alias Gringotts.Gateways.Monei, as: Gateway

  @moduletag :integration

  @amount Money.new(42, :EUR)
  @sub_amount Money.new(21, :EUR)

  @card %CreditCard{
    first_name: "Harry",
    last_name: "Potter",
    number: "4200000000000000",
    year: 2099,
    month: 12,
    verification_code: "123",
    brand: "VISA"
  }

  @customer %{
    givenName: "Harry",
    surname: "Potter",
    merchantCustomerId: "the_boy_who_lived",
    sex: "M",
    birthDate: "1980-07-31",
    mobile: "+15252525252",
    email: "masterofdeath@ministryofmagic.gov",
    ip: "127.0.0.1",
    status: "NEW"
  }
  @merchant %{
    name: "Ollivanders",
    city: "South Side",
    street: "Diagon Alley",
    state: "London",
    country: "GB",
    submerchantId: "Makers of Fine Wands since 382 B.C."
  }
  @billing %{
    street1: "301, Gryffindor",
    street2: "Hogwarts School of Witchcraft and Wizardry, Hogwarts Castle",
    city: "Highlands",
    state: "Scotland",
    country: "GB"
  }
  @shipping Map.merge(
              %{method: "SAME_DAY_SERVICE", comment: "For our valued customer, Mr. Potter"},
              @billing
            )

  @extra_opts [
    customer: @customer,
    merchant: @merchant,
    billing: @billing,
    shipping: @shipping,
    shipping_customer: @customer,
    category: "EC",
    custom: %{voldemort: "he who must not be named"}
  ]

  @auth %{
    userId: "8a8294186003c900016010a285582e0a",
    password: "hMkqf2qbWf",
    entityId: "8a82941760036820016010a28a8337f6"
  }

  setup_all do
    Application.put_env(
      :gringotts,
      Gringotts.Gateways.Monei,
      adapter: Gringotts.Gateways.Monei,
      userId: @auth[:userId],
      password: @auth[:password],
      entityId: @auth[:entityId]
    )
  end

  setup do
    randoms = [
      invoice_id: Base.encode16(:crypto.hash(:md5, :crypto.strong_rand_bytes(32))),
      transaction_id: Base.encode16(:crypto.hash(:md5, :crypto.strong_rand_bytes(32)))
    ]

    {:ok, opts: [config: @auth] ++ randoms ++ @extra_opts}
  end

  test "[authorize] without tokenisation", %{opts: opts} do
    with {:ok, auth_result} <- Gateway.authorize(@amount, @card, opts),
         {:ok, _capture_result} <- Gateway.capture(auth_result.id, @amount, opts) do
      "yay!"
    else
      {:error, _err} ->
        flunk()
    end
  end

  test "[authorize -> capture] with tokenisation", %{opts: opts} do
    with {:ok, auth_result} <- Gateway.authorize(@amount, @card, opts ++ [register: true]),
         {:ok, _registration_token} <- Map.fetch(auth_result, :token),
         {:ok, _capture_result} <- Gateway.capture(auth_result.id, @amount, opts) do
      "yay!"
    else
      {:error, _err} ->
        flunk()
    end
  end

  test "[authorize -> void]", %{opts: opts} do
    with {:ok, auth_result} <- Gateway.authorize(@amount, @card, opts),
         {:ok, _void_result} <- Gateway.void(auth_result.id, opts) do
      "yay!"
    else
      {:error, _err} ->
        flunk()
    end
  end

  test "[purchase/capture -> void]", %{opts: opts} do
    with {:ok, purchase_result} <- Gateway.purchase(@amount, @card, opts),
         {:ok, _void_result} <- Gateway.void(purchase_result.id, opts) do
      "yay!"
    else
      {:error, _err} ->
        flunk()
    end
  end

  test "[purchase/capture -> refund] (partial)", %{opts: opts} do
    with {:ok, purchase_result} <- Gateway.purchase(@amount, @card, opts),
         {:ok, _refund_result} <- Gateway.refund(@sub_amount, purchase_result.id, opts) do
      "yay!"
    else
      {:error, _err} ->
        flunk()
    end
  end

  test "[store]", %{opts: opts} do
    assert {:ok, _store_result} = Gateway.store(@card, opts)
  end

  @tag :skip
  test "[store -> unstore]", %{opts: opts} do
    with {:ok, store_result} <- Gateway.store(@card, opts),
         {:ok, _unstore_result} <- Gateway.unstore(store_result.id, opts) do
      "yay!"
    else
      {:error, _err} ->
        flunk()
    end
  end

  test "[purchase]", %{opts: opts} do
    assert {:ok, _response} = Gateway.purchase(@amount, @card, opts)
  end

  test "Environment setup" do
    config = Application.get_env(:gringotts, Gringotts.Gateways.Monei)
    assert config[:adapter] == Gringotts.Gateways.Monei
  end
end
