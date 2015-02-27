defmodule FixtureTest do
  use ExUnit.Case
  alias Exquery, as: E
  import ExqueryTest.Helpers


  #Just test the first and last because i'm lazy
  test "no js or css" do
    tokens = "no_js_css"
    |> fixture
    |> E.tokenize

    first = tokens |> Enum.take(5)
    last  = tokens |> Enum.reverse |> Enum.take(5) |> Enum.reverse

    assert first == [
      {:open_tag, "body", [{"class", "mediawiki ltr sitedir-ltr ns-0 ns-subject page-Elixir_programming_language skin-vector action-view"}]},
      {:open_tag, "div", [{"class", "noprint"}, {"id", "mw-page-base"}]},
      {:close_tag, "div", []},
      {:open_tag, "div", [{"class", "noprint"}, {"id", "mw-head-base"}]},
      {:close_tag, "div", []}
    ]

    assert last == [
      {:close_tag, "ul", []}, 
      {:open_tag, "div", [{"style", "clear:both"}]},
      {:close_tag, "div", []}, 
      {:close_tag, "div", []}, 
      {:close_tag, "body", []}
    ]
    
  end


  test "with js" do
    tokens = "with_js"
    |> fixture
    |> E.tokenize


    assert Enum.find(tokens, fn {kind, _, _} ->
      kind == :js
    end) == {:js,
      "\nfunction byId(id) {\n  return document.getElementById(id);\n}\n\nfunction vote(node) {\n  var v = node.id.split(/_/);   // {'up', '123'}\n  var item = v[1];\n\n  // hide arrows\n  byId('up_'   + item).style.visibility = 'hidden';\n  byId('down_' + item).style.visibility = 'hidden';\n\n  // ping server\n  var ping = new Image();\n  ping.src = node.href;\n\n  return false; // cancel browser nav\n} ",
    []}

    final = List.last(tokens)
    assert final == {:close_tag, "html", []}

  end


  @tag timeout: 500
  test "can tokenize in a reasonable amount of time" do
    tree = "large"
    |> fixture
    |> E.tokenize
  end

  @tag timeout: 1000
  test "can treeify in a reasonable amount of time" do
    tree = "large"
    |> fixture
    |> E.tree
  end


  test "capital tags" do
    tree = "capitals"
    |> fixture
    |> E.tree
    |> Exquery.Query.all({:any, "p", []})
    
    assert tree == [
      {{:tag, "p",
         [{"style", "TEXT-ALIGN: left; MARGIN: 0pt; LINE-HEIGHT: 1.25"}, {"id", "PARA42"}]},
          [{{:tag, "font",
           [{"style",
             "FONT-SIZE: 10pt; FONT-FAMILY: Times New Roman, Times, serif"}]},
          [{:text, "WTN Services LLC (California)", []}]}]},
      {{:tag, "p",
        [{"style", "TEXT-ALIGN: left; MARGIN: 0pt; LINE-HEIGHT: 1.25"},{"id", "PARA43"}]},
       [{{:tag, "font",
          [{"style",
            "FONT-SIZE: 10pt; FONT-FAMILY: Times New Roman, Times, serif"}]},
         [{:text, "WTN Marketing Agent LLC (Delaware)", []}]}]},
      {{:tag, "p",
        [{"style", "TEXT-ALIGN: left; MARGIN: 0pt; LINE-HEIGHT: 1.25"},
         {"id", "PARA44"}]},
       [{{:tag, "font",
          [{"style",
            "FONT-SIZE: 10pt; FONT-FAMILY: Times New Roman, Times, serif"}]},
         [{:text, "Colonial Gifts Ltd. (UK)", []}]}]}]

  end


  test "optional closing tags" do
    tree = "no_closing"
    |> fixture
    |> E.tree
    
    assert tree == [
      {{:tag, "tr", []}, 
        [{:text, "a", []}]}, 
      {{:tag, "tr", []}, 
        [{:text, "b", []}]},
      {{:tag, "p", [{"style", "page-break-before:always"}]}, []},
      {:tag, "hr", [{"class", "lol"}]}, 
      {{:tag, "tr", []}, 
        [{:text, "c", []}]},
      {{:tag, "tr", []}, 
        [{:text, "d", []}]}
    ]



  end

end
