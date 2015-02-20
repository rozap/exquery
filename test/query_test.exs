defmodule QueryTest do
  use ExUnit.Case
  alias Exquery.Query, as: Q
  import ExqueryTest.Helpers

  setup_all do
    tree = "no_js_css"
    |> fixture
    |> Exquery.tree

    simple = "simple"
    |> fixture
    |> Exquery.tree


    {:ok, %{tree: tree, simple: simple}}
  end

  test "can find one element by attrs", %{tree: tree} do
    assert Q.one(tree, {:any, :any, [{"id", "siteNotice"}]}) == {
      {:tag, "div", [{"id", "siteNotice"}]}, 
      [{:comment, " CentralNotice ", []}]
    }

    assert Q.one(tree, {:any, :any, [{"class", "noprint"}]}) == {
      {:tag, "div", [{"class", "noprint"}, {"id", "mw-page-base"}]}, []
    }

    assert Q.one(tree, {:any, :any, [{"id", "siteNotice", "class", "foobar"}]}) == nil
  end

  test "can find all elements by attrs", %{simple: simple} do
    [one, two, three] = Q.all(simple, {:any, :any, [{"class", "noprint"}]})


    assert one == {{:tag, "div", [{"class", "noprint"}, {"id", "mw-page-base"}]}, []}
    assert two == {{:tag, "div", [{"class", "noprint"}, {"id", "mw-head-base"}]}, []}

    {three, _} = three
    assert three == {:tag, "ul", [{"class", "noprint"}, {"id", "footer-icons"}]}
  end

  test "can find the first element by tag", %{tree: tree} do
    h1 = Q.one(tree, {:tag, "h1", []})
    assert {{:tag, "h1", [
      {"lang", "en"}, 
      {"class", "firstHeading"}, 
      {"id", "firstHeading"}]},
      
      [{:text, "Elixir (programming language)", []}]
    } == h1
  end

  test "can find the first element by tag", %{tree: tree} do
    h1 = Q.one(tree, {:tag, "h1", []})
    assert {{:tag, "h1", [
      {"lang", "en"}, 
      {"class", "firstHeading"}, 
      {"id", "firstHeading"}]},
      
      [{:text, "Elixir (programming language)", []}]
    } == h1
  end


  test "can find element by tag and attrs", %{tree: tree} do
    div = Q.one(tree, {:tag, "div", [{"style", "clear:both"}]})
    assert div == {{:tag, "div", [{"style", "clear:both"}]}, []}
  end





end
