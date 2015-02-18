defmodule Exquery.Tree do
  
  @pairs [
    {:open_tag, :close_tag},
    {:open_script, :close_script},
    {:open_style, :close_style}
  ]


  Enum.each(@pairs, fn({open, _}) ->
    [_, kind] = open
    |> Atom.to_string 
    |> String.split("_")

    a = String.to_atom(kind)

    def concise_el({unquote(open), contents, attrs}) do
      {unquote(a), contents, attrs}
    end
  end)
  def concise_el({:self_closing, contents, attrs}), do: {:tag, contents, attrs}
  def concise_el(el), do: el

  defp is_opening(tag) do
    Enum.find(@pairs, false, fn {t, _} -> t == tag end)
  end

  defp is_closing(tag) do
    Enum.find(@pairs, false, fn {_, t} -> t == tag end)
  end

  def to_tree([], _, acc), do: Enum.reverse(acc)

  def to_tree([{:close_tag, c, _} | rest], [{{:open_tag, c, _} = el, el_acc} | stack], acc) do
    to_tree(rest, stack, [{concise_el(el), Enum.reverse(acc)} | el_acc])
  end

  def to_tree([{:open_tag, _, _} = el | rest], stack, acc) do
    to_tree(rest, [{el, acc} | stack], [])
  end

  def to_tree([el | rest], stack, acc) do
    to_tree(rest, stack, [concise_el(el) | acc])
  end

  #
  # acc
  #

  def to_tree(tokens) do
    to_tree(tokens, [], [])
  end


  defp indent(num) do
    0..num
    |> Enum.map(fn _ -> " " end)
    |> Enum.join("")
    |> IO.write
  end
  defp print_el({el, children}, spaces) do
    print_el(el, spaces)
    print(children, spaces + 4)
  end
  defp print_el({kind, contents, attrs}, spaces) do
    indent(spaces)
    attr_string = attrs
    |> Enum.map(fn {key, val} -> "#{key}: #{val}" end)
    |> Enum.join(", ")
    IO.puts("#{kind}: #{contents} | #{attr_string}")
  end

  def print(tree, spaces \\ 0) do
    Enum.each(tree, fn el ->
      print_el(el, spaces)
    end)
  end

end