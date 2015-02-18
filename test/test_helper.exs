ExUnit.start()

defmodule ExqueryTest.Helpers do
  
  def fixture(name) do
    {:ok, c} = File.cwd
    path = "#{c}/test/fixtures/#{name}.html"
    File.read!(path)
  end
end
