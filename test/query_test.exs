defmodule QueryTest do
  use ExUnit.Case
  alias Exquery.Query, as: Q
  import ExqueryTest.Helpers
  doctest Exquery.Query

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


  test "can find element by tag and attrs", %{tree: tree} do
    div = Q.one(tree, {:tag, "div", [{"style", "clear:both"}]})
    assert div == {{:tag, "div", [{"style", "clear:both"}]}, []}
  end

  test "can get the before element", %{tree: tree} do
    a = Q.before(tree, {:tag, "div", [{"id", "siteNotice"}]})
    assert a == {{:tag, "a", [{"id", "top"}]}, []}
  end

  test "can get the before element n element", %{tree: tree} do
    a = Q.before(tree, {:tag, "div", [{"id", "bodyContent"}]}, 4)
    assert a == {{:tag, "a", [{"id", "top"}]}, []}
  end

  test "gives nil when before doesn't exist", %{tree: tree} do
    assert Q.before(tree, {:tag, "a", [{"id", "top"}]}) == nil
  end


  test "can get the element after", %{tree: tree} do
    a = Q.next(tree, {:tag, "div", [{"id", "siteNotice"}]})
    assert a == {{:tag, "div", [{"class", "mw-indicators"}]}, []}
  end

  test "can get the element n after element", %{tree: tree} do
    {el, _kids} = Q.next(tree, {:tag, "a", [{"id", "top"}]}, 4)
    assert el == {:tag, "div", [{"class", "mw-body-content"}, {"id", "bodyContent"}]}
  end

  test "gives nil when next doesn't exist", %{tree: tree} do
    assert Q.next(tree, {:tag, "body", []}) == nil
  end



  test "flat css class to spec", _ do
    assert Q.css_to_spec(".foo") == {:and, [{:class, "foo"}]}
    assert Q.css_to_spec(".foo.bar") == {:and, [{:class, "foo"}, {:class, "bar"}]}
    assert Q.css_to_spec(".foo.bar.baz") == {:and, [{:class, "foo"}, {:class, "bar"}, {:class, "baz"}]}
  end

  test "flat css id to spec", _ do
    assert Q.css_to_spec("#foo") == {:and, [{:id, "foo"}]}
    assert Q.css_to_spec("#foo#bar") == {:and, [{:id, "foo"}, {:id, "bar"}]}
    assert Q.css_to_spec("#foo#bar#baz") == {:and, [{:id, "foo"}, {:id, "bar"}, {:id, "baz"}]}
  end

  test "css with direct descendents", _ do
    assert Q.css_to_spec("#foo>#bar") == {:direct, {:id, "foo"}, {:and, [{:id, "bar"}]}}
    assert Q.css_to_spec("#foo>#bar>#baz") == {
      :direct, {:id, "foo"}, 
      {
        :direct, {:id, "bar"}, 
        {
          :and, [{:id, "baz"}]
        }
      }
    }

  end



end
