ExUnit.start()

defmodule TestHelper do
  use ExUnit.Case

  def wait_for_breaks(n) when n > 0 do
    1..n |> Enum.each(fn _ -> assert_receive :break, 10_000 end)
  end

  def receive_and_check_turn_credentials(expiry_before) do
    assert_receive(
      {:to_user,
       %{
         event: "joined_room",
         own_id: own_id,
         turn_user: user,
         turn_password: pw
       }},
      1000
    )

    [expiry_str, id] = String.split(user, ":")
    expiry = String.to_integer(expiry_str)
    assert own_id == id
    assert System.os_time(:second) < expiry
    assert expiry < System.os_time(:second) + 3 * 60 * 60 + 10
    assert expiry_before <= expiry

    assert pw ==
             :crypto.mac(
               :hmac,
               :sha,
               to_charlist("verysecretpassphrase1234"),
               to_charlist(user)
             )
             |> Base.encode64()
  end
end
