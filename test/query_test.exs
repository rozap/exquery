defmodule QueryTest do
  use ExUnit.Case
  alias Exquery.Query, as: Q
  import ExqueryTest.Helpers
  doctest Exquery.Query

  @fragment """
    <div class="foo">
      <div class="bar">
        <div class="baz">
          <span>hi</span>
        </div>
      </div>
    </div>
  """

  @double_fragment """
    <div class="foo">
      <div class="bar">
        <div class="baz">
          <span>hi</span>
          <div class="foo">
            <div class="bar">
              <div class="baz">
                <span>hi</span>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  """

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

  test "finds one element when there is one using all/2" do
    assert length(@fragment
    |> Exquery.tree
    |> Q.all({:tag, "span", []})) == 1

    assert length(@fragment
    |> Exquery.tree
    |> Q.all({:tag, "div", []})) == 3

    assert length(@fragment
    |> Exquery.tree
    |> Q.all({:tag, "nothing", []})) == 0
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

  test "flat css tag to spec", _ do
    assert Q.css_to_spec("foo") == {:tag, "foo", []}
    assert Q.css_to_spec("foo.bar") == {:tag, "foo", [{"class", "bar"}]}
    assert Q.css_to_spec("foo.bar#baz") == {:tag, "foo", [{"class", "bar"}, {"id", "baz"}]}
    assert Q.css_to_spec("foo.bar#baz.buzz") == {:tag, "foo", [{"class", "bar"}, {"id", "baz"}, {"class", "buzz"}]}
  end

  test "flat css class to spec", _ do
    assert Q.css_to_spec(".foo") == {:tag, :any, [{"class", "foo"}]}
    assert Q.css_to_spec(".foo.bar.baz") == {:tag, :any, [{"class", "foo"}, {"class", "bar"}, {"class", "baz"}]}
  end

  test "flat css id to spec", _ do
    assert Q.css_to_spec("#foo") == {:tag, :any, [{"id", "foo"}]}
    assert Q.css_to_spec("#foo#bar#baz") == {:tag, :any, [{"id", "foo"}, {"id", "bar"}, {"id", "baz"}]}
  end

  # test "flat css attr to spec", _ do
  #   assert Q.css_to_spec("span[title=\"foo\"]") == {:tag, "span", [{"title", "foo"}]}
  # end

  test "css with direct descendents", _ do
    assert Q.css_to_spec("#foo>#bar")   == {:direct, {{:tag, :any, [{"id", "foo"}]}, {:tag, :any, [{"id", "bar"}]}}}
    assert Q.css_to_spec("#foo > #bar") == {:direct, {{:tag, :any, [{"id", "foo"}]}, {:tag, :any, [{"id", "bar"}]}}}
    assert Q.css_to_spec(">#foo>") == {:tag, :any, [{"id", "foo"}]}
  end

  test "css with indirect descendents", _ do
    assert Q.css_to_spec("#foo #bar") == {:indirect, {{:tag, :any, [{"id", "foo"}]}, {:tag, :any, [{"id", "bar"}]}}}
    assert Q.css_to_spec("#foo #bar #baz") == {
      :indirect, {
        {
          :tag, :any, [{"id", "foo"}]}, {
            :indirect, {
              {
                :tag, :any, [{"id", "bar"}]}, {
                  :tag, :any, [{"id", "baz"}]
              }
            }
          }
        }
      }
  end

  test "mixed bag of css", _ do
    assert Q.css_to_spec("div#foo span#bar>a.baz") == {
      :indirect, {{
        :tag, "div", [{"id", "foo"}]}, {
          :direct, {{
            :tag, "span", [{"id", "bar"}]}, {
              :tag, "a", [{"class", "baz"}]}}}}}


    assert Q.css_to_spec("div#foo span#bar>a.baz  > a.cool#link div.wow") == {
      :indirect, {{
        :tag, "div", [{"id", "foo"}]
        }, {
          :direct, {{
            :tag, "span", [{"id", "bar"}]}, {
              :direct, {{
                :tag, "a", [{"class", "baz"}]}, {
                  :indirect, {{
                    :tag, "a", [{"class", "cool"}, {"id", "link"}]}, {
                      :tag, "div", [{"class", "wow"}]}}}}}}}}}
  end

  test "normalize css" do
    assert Q.normalize_css(".foo   > .bar") == ".foo>.bar"
    assert Q.normalize_css(".foo    .bar") == ".foo .bar"
    assert Q.normalize_css("     .foo    .bar") == ".foo .bar"
  end

  test "can css select for simple flat spec", %{tree: tree} do
    assert Q.all(tree, {:any, :any, [{"id", "top"}]}) == Q.css(tree, "a#top")
    assert Q.all(tree, {:tag, "h2", [{"id", "toctitle"}]}) == Q.css(tree, "h2#toctitle")
  end

  test "can css select for indirect spec", %{tree: tree} do
    assert Q.css(tree, "div#mw-hidden-catlinks a") 
    |> Enum.map(fn {{:tag, "a", _}, [{:text, txt, _}]} -> txt end) == [
      "All stub articles", "WikiProject Computer science stubs"
    ]

    assert Q.css(tree, "div div#does-not-exist a") == []
  end

  test "can css select for direct spec", %{tree: tree} do
    assert Q.css(tree, "div#content>a#top") == [{{:tag, "a", [{"id", "top"}]}, []}]
    assert Q.css(tree, "div>a#top") == [{{:tag, "a", [{"id", "top"}]}, []}]
    assert Q.css(tree, "div>#toctitle") == [{{
      :tag, "div", [{"id", "toctitle"}]}, [{{:tag, "h2", []}, [{:text, "Contents", []}]}]}]
    assert Q.css(tree, "div>div>#toctitle") == [{{
      :tag, "div", [{"id", "toctitle"}]}, [{{:tag, "h2", []}, [{:text, "Contents", []}]}]}]
  end

  test "can css for indirect spec" do

    span = [{{:tag, "span", []}, [{:text, "hi", []}]}]

    assert (@fragment
    |> Exquery.tree
    |> Q.css("div.foo span") == span)

    assert (@fragment
    |> Exquery.tree
    |> Q.css("div.baz span") == span)

    assert (@fragment
    |> Exquery.tree
    |> Q.css("div div span") == span)

    assert (@fragment
    |> Exquery.tree
    |> Q.css("div div div span") == span)

    assert (@fragment
    |> Exquery.tree
    |> Q.css("div span") == span)


    assert (@double_fragment
    |> Exquery.tree
    |> Q.css("div span") == List.flatten([span, span]))

    assert (@fragment
    |> Exquery.tree
    |> Q.css("div div div div div span") == [])


  end


  test "can apply elementids to elements", %{tree: tree} do
    assert (@fragment
    |> Exquery.tree
    |> Q.apply_ids) == [{4,
      {{:tag, "div", [{"class", "foo"}]},
       [{3,
         {{:tag, "div", [{"class", "bar"}]},
          [{2,
            {{:tag, "div", [{"class", "baz"}]},
             [{1, {{:tag, "span", []}, [{0, {:text, "hi", []}}]}}]}}]}}]}}]
  end

  test "can unapply elementids to elements", %{tree: tree} do
    assert (@fragment
    |> Exquery.tree
    |> Q.apply_ids
    |> Q.unapply_ids) == Exquery.tree(@fragment)
  end


  test "can css for direct spec" do

    span = [{{:tag, "span", []}, [{:text, "hi", []}]}]

    assert (@fragment
    |> Exquery.tree
    |> Q.css("div.baz>span") == span)

    assert (@fragment
    |> Exquery.tree
    |> Q.css("div>div>div>span") == span)

    assert (@fragment
    |> Exquery.tree
    |> Q.css("div>div>span") == span)

    assert (@fragment
    |> Exquery.tree
    |> Q.css("div>span") == span)

    assert (@double_fragment
    |> Exquery.tree
    |> Q.css("div>div>span") == List.flatten([span, span]))

    assert (@double_fragment
    |> Exquery.tree
    |> Q.css("div.foo>span") == [])


    assert (@fragment
    |> Exquery.tree
    |> Q.css("div>div>div>div>span") == [])

  end


end
