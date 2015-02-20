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



  def all([], _, acc), do: Enum.reverse(acc)
  def all(tree, {kind, contents, kv} = spec, acc) do
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
    |> all(spec, new_acc)
  end
  def all(tree, spec), do: all(tree, spec, [])


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