defmodule TreeTest do
  use ExUnit.Case
  alias Exquery.Tree, as: Tree
  import ExqueryTest.Helpers
  import ExUnit.CaptureIO


  test "simple tree" do
    r = Tree.to_tree([
      {:open_tag, "div", []},
        {:text, "hello", []},
      {:close_tag, "div", []}
    ])
    assert r == [
      {{:tag, "div", []}, 
        [{:text, "hello", []}]
      }
    ]
  end

  test "can make a tree from some basic html" do
    tokens = [
      {:open_tag, "div", []},
        {:text, "hello", []},
      {:close_tag, "div", []},
      {:text, "a", []},
      {:text, "b", []},
      {:open_tag, "div", []},
        {:text, "end", []},
      {:close_tag, "div", []}
    ]

    tree = Tree.to_tree(tokens)

    assert tree == [
      {
        {:tag, "div", []}, 
          [{:text, "hello", []}]
      },
      {:text, "a", []},
      {:text, "b", []},
      {
        {:tag, "div", []},
          [{:text, "end", []}]
      }
    ]
  end

  test "can make a tree from nested html" do
    tokens = [
      {:open_tag, "div", []},
        {:text, "hello", []},
        {:open_tag, "span", []},
          {:text, "world", []},
        {:close_tag, "span", []},
      {:close_tag, "div", []}
    ]

    t = Tree.to_tree(tokens)

    assert t == [
      {{:tag, "div", []}, [
        {:text, "hello", []},
        {{:tag, "span", []}, [
          {:text, "world", []}
        ]}
      ]}
    ]
  end


  test "can make a tree from more nested html" do
    tokens = [
      {:open_tag, "div", []},
        {:text, "hello", []},
        {:open_tag, "span", []},
          {:text, "world", []},
        {:close_tag, "span", []},
        {:open_tag, "ul", []},
          {:open_tag, "li", []},
            {:text, "a", []},
          {:close_tag, "li", []},
          {:open_tag, "li", []},
            {:text, "b", []},
          {:close_tag, "li", []},
          {:open_tag, "li", []},
            {:text, "c", []},
          {:close_tag, "li", []},
        {:close_tag, "ul", []},
      {:close_tag, "div", []}
    ]

    t = Tree.to_tree(tokens)

    assert t == [
      {{:tag, "div", []}, [
          {:text, "hello", []},
          {{:tag, "span", []}, [
            {:text, "world", []}
          ]},
          {{:tag, "ul", []},
          [{{:tag, "li", []}, [{:text, "a", []}]},
           {{:tag, "li", []}, [{:text, "b", []}]},
           {{:tag, "li", []}, [{:text, "c", []}]}]}]}
    ]
  end


end
