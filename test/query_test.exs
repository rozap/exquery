defmodule QueryTest do
  use ExUnit.Case
  alias Exquery.Tree, as: Tree
  alias Exquery.Query, as: Q
  import ExqueryTest.Helpers
  import ExUnit.CaptureIO


  test "can query by class" do
    tree = "no_js_css"
    |> fixture
    |> Exquery.tree


    |> Tree.print

  end


end
