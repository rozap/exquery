defmodule Exquery do
  require Exquery.Helpers
  import Exquery.Helpers
  @spaces [" ", "\n", "\t", "\r"]

  defp push_state({{:doc, :text}, value, attrs} = state, acc) do
    case String.strip(value) do
      "" -> acc
      _ -> [{:text, value, attrs} | acc]
    end
  end
  defp push_state({{:doc, tag}, value, attrs}, acc) do 
    [{tag, value, attrs} | acc]
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
    ff(r, {tag, text, attrs}, acc)
  end


  ff_until "-->",   {:doc, :comment},   do: {r, push_state(state, acc)}
  ff_until ">"  ,   {:doc, :close_tag}, do: {r, push_state(state, acc)}
  ff_until :spaces, {:doc, :open_tag},  do: attributes(r, state, acc)
  ff_until :spaces, {:doc, :doctype},   do: attributes(r, state, acc)
  ff_until ">"  ,   {:doc, :open_tag},  do: {r, push_state(state, acc)}
  ff_until ">"  ,   {:doc, :doctype},   do: {r, push_state(state, acc)}
  ff_until "<"  ,   {:doc, :any}, do: {all, push_state(state, acc)}

  ff_until :any, {:doc, :any} do
    {kind, contents, attrs} = state
    ff(r, {kind, contents <> head, attrs},  acc)
  end

  defp ff(the_end, state, acc) do 
    {the_end, push_state(state, acc)}
  end

  # when_tok "<--", {:comment, "", []}

  defp tok("<!--" <> r, acc), do: tokenize(ff(r,               {{:doc, :comment},   "", []},  acc))
  defp tok("</"   <> r, acc), do: tokenize(ff(String.strip(r), {{:doc, :close_tag}, "", []},  acc))
  defp tok("<!"   <> r, acc), do: tokenize(ff(String.strip(r), {{:doc, :doctype},   "", []},  acc))
  defp tok("<"    <> r, acc), do: tokenize(ff(String.strip(r), {{:doc, :open_tag},  "", []},  acc))
  defp tok(<<head::binary-size(1), r::binary>>, acc) do
    tokenize(ff(r, {{:doc, :text}, head, []}, acc))
  end
  defp tok("", acc) do
    Enum.reverse(acc)
  end


  def tokenize({text, acc}) do
    tok(text, acc)
  end

  def tokenize(text) do
    tokenize({text, []})
  end
end
