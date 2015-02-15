defmodule FixtureTest do
  use ExUnit.Case
  alias Exquery, as: E
  
  defp fixture(name) do
    {:ok, c} = File.cwd
    path = "#{c}/test/fixtures/#{name}.html"
    File.read!(path)
  end

  test "no js or css" do
    r = "no_js_css"
    |> fixture
    |> E.tokenize
    |> Enum.each(fn i -> IO.inspect i end)
    # IO.puts r
  end


end
