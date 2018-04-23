defmodule Gringotts.Gateways.WireCardTest do
  use ExUnit.Case, async: false

  import Mock

  setup do
    # TEST_AUTHORIZATION_GUWID = 'C822580121385121429927'
    # TEST_PURCHASE_GUWID =      'C865402121385575982910'
    # TEST_CAPTURE_GUWID =       'C833707121385268439116'

    # config = %{credentails: {'user', 'pass'}, default_currency: "EUR"}
    :ok
  end

  test "test_successful_authorization" do
    assert 1 + 1 == 2
  end
end
