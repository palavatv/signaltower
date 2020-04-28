ExUnit.start()

defmodule TestHelper do
  use ExUnit.Case

  def wait_for_breaks(n) when n > 0 do
    1..n |> Enum.each(fn _ -> assert_receive :break, 10_000 end)
  end
end
