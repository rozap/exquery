defmodule QueryTest do
  use ExUnit.Case
  alias Exquery.Tree, as: Tree
  alias Exquery.Query, as: Q
  import ExqueryTest.Helpers
  import ExUnit.CaptureIO

  setup_all do
    tree = "no_js_css"
    |> fixture
    |> Exquery.tree

    {:ok, %{tree: tree}}
  end

  test "can find one element by attrs", %{tree: tree} do
    assert Q.one(tree, {:any, :any, [{"id", "siteNotice"}]}) == {
      {:tag, "div", [{"id", "siteNotice"}]}, 
      [{:comment, " CentralNotice ", []}]
    }

    Q.one(tree, {:any, :any, [{"class", "noprint"}]}) == {
      {:tag, "div", [{"id", "mw-page-base"}, {"class", "noprint"}]}
    }

    assert Q.one(tree, {:any, :any, [{"id", "siteNotice", "class", "foobar"}]}) == nil
  end







end
