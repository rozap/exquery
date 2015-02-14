defmodule Exquery do
  require Exquery.Helpers
  import Exquery.Helpers
  @spaces [" ", "\n", "\t", "\r"]
  @new_tag {{:doc, :none}, :none, :none}

  defp push_tag({:none, :none, :none}, acc), do: acc
  defp push_tag({:text, value, attrs} = tag, acc) do
    case String.strip(value) do
      "" -> acc
      _ -> [tag | acc]
    end
  end
  defp push_tag({_, _, _} = tag, acc) do 
    IO.puts "Adding #{inspect tag}"
    [tag | acc]
  end

  defp push_attrs({key, val} = current, acc) do
    case {String.strip(key), String.strip(val)} do
      {"", ""} -> acc
      _ -> [current | acc]
    end
  end

  ff_until "'",  {:attrs, :open_sq},       do: to_attributes(r, push_attrs(current, acc))
  ff_until "\"", {:attrs, :open_dq},       do: to_attributes(r, push_attrs(current, acc))
  ff_until :spaces,  {:attrs, :open_sp},   do: to_attributes(r, push_attrs(current, acc))
  ff_until "=",  {:attrs, :key},           do: ff(r,   {{:attrs, :open_sp}, current, nil}, acc)
  ff_until "=",  {:attrs, :close_key},     do: ff(r,   {{:attrs, :open_sp}, current, nil}, acc)
  ff_until :spaces,  {:attrs, :key},       do: ff(r,   {{:attrs, :close_key}, current, nil}, acc)
  ff_until :spaces,  {:attrs, :close_key}, do: ff(r,   {{:attrs, :close_key}, current, nil}, acc)
  ff_until :spaces,  {:attrs, :open_key},  do: ff(r,   {{:attrs, :open_key}, current, nil}, acc)
  ff_until :any, {:attrs, :open_key},      do: ff(all, {{:attrs, :key}, current, nil}, acc)
  ff_until :any, {:attrs, :close_key},     do: to_attributes(all, push_attrs(current, acc))
  ff_until "'" , {:attrs, :open_sp},       do: ff(r,   {{:attrs, :open_sq}, current, nil}, acc)
  ff_until "\"", {:attrs, :open_sp},       do: ff(r,   {{:attrs, :open_dq}, current, nil}, acc)
  ff_until ">", {:attrs, :any}, do: {all, push_attrs(current, acc)}

  defp ff("", {{:attrs, _}, current, _}, acc), do: {"", push_attrs(current, acc)}

  ff_until :any, {:attrs, :key} do
    {key, val} = current
    ff(r, {{:attrs, :key}, {key <> head, val}, nil}, acc)
  end

  ff_until :any, {:attrs, :any} do
    {key, val} = current
    ff(r, {mode, {key, val <> head}, nil}, acc)
  end

  def to_attributes(r, acc), do: ff(r, {{:attrs, :open_key}, {"", ""}, nil}, acc)


  defp attributes(r, {tag, text, attrs} = token, acc) do
    {r, attrs} = ff(r, {{:attrs, :open_key}, {"", ""}, nil}, attrs)
    ff(r, {{:doc, tag}, text, attrs}, acc)
  end


  ff_until "-->",   {:doc, :comment},   do: ff(r, @new_tag, push_tag({:comment, current, attributes}, acc))
  ff_until ">"  ,   {:doc, :close_tag}, do: ff(r, @new_tag, push_tag({:close_tag, current, attributes}, acc))
  ff_until :spaces, {:doc, :open_tag},  do: attributes(r, {:open_tag, current, attributes}, acc)
  ff_until :spaces, {:doc, :doctype},   do: attributes(r, {:doctype, current, attributes}, acc)
  ff_until ">"  ,   {:doc, :open_tag},  do: ff(r, @new_tag, push_tag({:open_tag, current, attributes}, acc))
  ff_until ">"  ,   {:doc, :doctype},   do: ff(r, @new_tag, push_tag({:doctype, current, attributes}, acc))

  ff_until "<!--", {:doc, :none}, do: ff(r,               {{:doc, :comment},   "", []},  acc)
  ff_until "</"  , {:doc, :none}, do: ff(String.strip(r), {{:doc, :close_tag}, "", []},  acc)
  ff_until "<!"  , {:doc, :none}, do: ff(String.strip(r), {{:doc, :doctype},   "", []},  acc)
  ff_until "<"   , {:doc, :none}, do: ff(String.strip(r), {{:doc, :open_tag},  "", []},  acc)
  ff_until :any  , {:doc, :none}, do: ff(r, {{:doc, :text}, head, []}, acc)


  ff_until "<"  ,   {:doc, :any} do
    {:doc, tag} = mode
    ff(all, @new_tag, push_tag({tag, current, attributes}, acc))
  end
  ff_until :any, {:doc, :any} do
    ff(r, {mode, current <> head, attributes},  acc)
  end

  defp ff("", mode, acc) do 
    IO.puts "END"
    {{:doc, mode}, current, attributes} = mode
    push_tag({mode, current, attributes}, acc) |> Enum.reverse
  end


  def tokenize({text, acc}) do
    IO.puts "Tokenize #{text}"
    ff(text, @new_tag, acc)
  end

  def tokenize(text) do
    tokenize({text, []})
  end
end
