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

    defp concise_el({unquote(open), contents, attrs}) do
      {unquote(a), contents, attrs}
    end
  end)
  defp concise_el({:self_closing, contents, attrs}), do: {:tag, contents, attrs}
  defp concise_el(el), do: el

  defp is_opening(tag) do
    Enum.find(@pairs, false, fn {t, _} -> t == tag end)
  end

  defp is_closing(tag) do
    Enum.find(@pairs, false, fn {_, t} -> t == tag end)
  end

  defp push_el(el, acc, el_acc) do
    [{concise_el(el), Enum.reverse(acc)} | el_acc]
  end

  defp do_to_tree([], stack, acc) do
    Enum.reverse(acc)
  end


  ##
  # This handles a lot of the common cases here
  # http://www.w3.org/TR/html5/syntax.html#optional-tags
  # The first item in the tuple is the tag name, which may lack
  # a closing tag if it is followed by any of the elements in the 
  # list of the second tuple item
  # 
  # TODO: colgroups and optional start tags? ugh..
  # 
  @optional_closings [
    {"p", ["address", "article", "aside", "blockquote",
     "div", "dl", "fieldset", "footer", "form", 
     "h1", "h2", "h3", "h4", "h5", "h6", "header", 
     "hgroup", "hr", "main", "nav", "ol", "p", "pre", 
     "section", "table", "ul"]},
    {"dd",  ["dd", "dt"]},
    {"dt",  ["dd", "dt"]},
    {"li",  ["li"]},
    {"rb",  ["rb", "rt", "rtc", "rp"]},
    {"rt",  ["rb", "rt", "rtc", "rp"]},
    {"rtc", ["rb", "rt", "rtc", "rp"]},
    {"rp",  ["rb", "rt", "rtc", "rp"]},
    {"optgroup", ["optgroup"]},
    {"option", ["option", "optgroup"]},
    {"thead", ["tbody", "tfoot"]},
    {"tbody", ["tbody", "tfoot"]},
    {"tfoot", ["tbody"]},
    {"tr", ["tr"]},
    {"td", ["td", "th"]},
    {"th", ["td", "th"]}

  ]

  Enum.each(@optional_closings, fn {subject, closings} ->
    Enum.each(closings, fn closing ->
      defp do_to_tree([{tag, unquote(closing), _} | _] = current, [{{:open_tag, unquote(subject), _} = el, el_acc} | stack], acc) when tag in [:self_closing, :open_tag] do
        do_to_tree(current, stack, push_el(el, acc, el_acc))
      end
    end)
  end)






  defp do_to_tree([{:close_tag, c, _} | rest], [{{:open_tag, c, _} = el, el_acc} | stack], acc) do
    do_to_tree(rest, stack, push_el(el, acc, el_acc))
  end

  defp do_to_tree([{:open_tag, _, _} = el | rest], stack, acc) do
    do_to_tree(rest, [{el, acc} | stack], [])
  end

  defp do_to_tree([el | rest], stack, acc) do
    do_to_tree(rest, stack, [concise_el(el) | acc])
  end

  #
  # acc
  #

  def to_tree(tokens) do
    do_to_tree(tokens, [], [])
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

    IO.puts("#{contents} | #{attr_string}")
  end

  def print(tree, spaces \\ 0) do
    Enum.each(tree, fn el ->
      print_el(el, spaces)
    end)
  end

end