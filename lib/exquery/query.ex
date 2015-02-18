defmodule Exquery.Query do
  

  defp matches?({_, _, attrs}, {:any, :any, kvs}) do
    Enum.all?(kvs, fn kv -> Enum.member?(attrs, kv) end)
  end
  defp matches?({el, children}, kv), do: matches?(el, kv)

  defp children_of({_, _, _}), do: []
  defp children_of({el, children}), do: children 


  def one([], _), do: nil
  def one(tree, {kind, contents, kv} = spec) do
    el = Enum.find(tree, false, fn el -> matches?(el, spec) end)
    if !el do
      tree
      |> Enum.map(&(children_of &1))
      |> List.flatten
      |> one(spec)
    else
      el
    end
  end

end