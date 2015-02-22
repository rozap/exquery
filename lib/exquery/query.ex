defmodule Exquery.Query do
  import Exquery.Helpers

  defp matches?({_, _, attrs}, {:any, :any, kvs}) do
    Enum.all?(kvs, fn kv -> Enum.member?(attrs, kv) end)
  end  
  defp matches?({tag, _, attrs} = el, {tag, contents, kvs}) when tag != :any do
    matches?(el, {:any, contents, kvs})
  end
  defp matches?({_, contents, attrs} = el, {tag, contents, kvs}) when contents != :any do
    matches?(el, {tag, :any, kvs})
  end

  defp matches?({_, _, _}, {_, _, _}), do: false

  defp matches?({el, children}, kv), do: matches?(el, kv)


  defp children_of({_, _, _}), do: []
  defp children_of({el, children}), do: children 



  defp find_all([], _, acc), do: Enum.reverse(acc)
  defp find_all(tree, {kind, contents, kv} = spec, acc) do
    new_acc = Enum.reduce(tree, acc, fn(el, a) ->
      if matches?(el, spec) do
        [el | a]
      else
        a
      end
    end)

    tree
    |> Enum.map(&(children_of &1))
    |> List.flatten
    |> find_all(spec, new_acc)
  end


  @doc ~S"""
    Find the all elements in the tree that matche the spec.
    

    A tree is an HTML tree given from `Exquery.tree/1`
    A spec is an HTML elemement, which a three element tuple
    of the element type, contents, and attributes. 
    `<div id="foo"></div>` would look like `{:tag, "div", [{"id", "foo"}]}`

    You may pass `:any` in for the element type and element contents to select 
    any element. 

    Examples: 
      iex> "<div id=\"foo\"><div id=\"bar\">hi</div></div>" |> Exquery.tree |> Exquery.Query.all({:tag, "div", []})
      [
        {{:tag, "div", [{"id", "foo"}]}, [
          {{:tag, "div", [{"id", "bar"}]}, [
            {:text, "hi", []}
          ]}
        ]},
        {{:tag, "div", [{"id", "bar"}]}, [
          {:text, "hi", []}
        ]}
      ]

      iex> "<div id=\"foo\"><div id=\"bar\">hi</div></div>" |> Exquery.tree |> Exquery.Query.all({:tag, "div", [{"id", "bar"}]})
      [{{:tag, "div", [{"id", "bar"}]}, [{:text, "hi", []}]}]

      iex> "<div id=\"foo\"><div id=\"bar\">hi</div></div>" |> Exquery.tree |> Exquery.Query.all({:tag, "div", [{"id", "nope"}]})
      []

  """
  def all(tree, spec), do: find_all(tree, spec, [])

  @doc ~S"""
    Find the first element in the tree that matches the spec.
    

    A tree is an HTML tree given from `Exquery.tree/1`
    A spec is an HTML elemement, which a three element tuple
    of the element type, contents, and attributes. 
    `<div id="foo"></div>` would look like `{:tag, "div", [{"id", "foo"}]}`

    You may pass `:any` in for the element type and element contents to select 
    any element. 

    Examples: 
      iex> "<div id=\"foo\"><a id=\"bar\">hi</a></div>" |> Exquery.tree |> Exquery.Query.one({:tag, "a", [{"id", "bar"}]})
      {{:tag, "a", [{"id", "bar"}]}, [{:text, "hi", []}]}

      iex> "<div id=\"foo\"><a id=\"bar\">hi</a></div>" |> Exquery.tree |> Exquery.Query.one({:tag, "a", []})
      {{:tag, "a", [{"id", "bar"}]}, [{:text, "hi", []}]}

      iex> "<div id=\"foo\"><a id=\"bar\">hi</a></div>" |> Exquery.tree |> Exquery.Query.one({:tag, :any, [{"id", "bar"}]})
      {{:tag, "a", [{"id", "bar"}]}, [{:text, "hi", []}]}

      iex> "<div id=\"foo\"><a id=\"bar\">hi</a></div>" |> Exquery.tree |> Exquery.Query.one({:any, :any, [{"id", "bar"}]})
      {{:tag, "a", [{"id", "bar"}]}, [{:text, "hi", []}]}

      iex> "<div id=\"foo\"><a id=\"bar\">hi</a></div>" |> Exquery.tree |> Exquery.Query.one({:any, :any, [{"id", "does-not-exist"}]})
      nil


  """
  def one([], _), do: nil
  def one(tree, {kind, contents, kv} = spec) do
    el = Enum.find(tree, false, fn el -> matches?(el, spec) end)
    if !el do
      tree
      |> Enum.map(&(children_of &1))
      |> Enum.find_value(fn children -> one(children, spec) end)
    else
      el
    end
  end

end