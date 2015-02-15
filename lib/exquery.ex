defmodule Exquery do
  require Exquery.Helpers
  import Exquery.Helpers
  @spaces [" ", "\n", "\t", "\r"]
  #yes this doesn't handle all cases..like StYlE
  #need a better way to deal with cases
  @styles ["<style", "<STYLE"]
  @new_token {{:doc, :none}, :none, :none}

  defp new_token(mode) do
    {{:doc, mode}, "", []}
  end


  # Attribute parsing

  defp push_attrs({key, val} = current, acc) do
    case {String.strip(key), String.strip(val)} do
      {"", ""} -> acc
      _ -> [current | acc]
    end
  end

  ff_until "'",         {:attrs, :open_sq},   do: to_attributes(r, push_attrs(current, acc))
  ff_until "\"",        {:attrs, :open_dq},   do: to_attributes(r, push_attrs(current, acc))
  ff_until_in @spaces,  {:attrs, :open_sp},   do: to_attributes(r, push_attrs(current, acc))
  ff_until "=",         {:attrs, :key},       do: ff(r,   {{:attrs, :open_sp}, current, nil}, acc)
  ff_until "=",         {:attrs, :close_key}, do: ff(r,   {{:attrs, :open_sp}, current, nil}, acc)
  ff_until_in @spaces,  {:attrs, :key},       do: ff(r,   {{:attrs, :close_key}, current, nil}, acc)
  ff_until_in @spaces,  {:attrs, :close_key}, do: ff(r,   {{:attrs, :close_key}, current, nil}, acc)
  ff_until_in @spaces,  {:attrs, :open_key},  do: ff(r,   {{:attrs, :open_key}, current, nil}, acc)
  ff_until :any,        {:attrs, :open_key},  do: ff(all, {{:attrs, :key}, current, nil}, acc)
  ff_until :any,        {:attrs, :close_key}, do: to_attributes(all, push_attrs(current, acc))
  ff_until "'" ,        {:attrs, :open_sp},   do: ff(r,   {{:attrs, :open_sq}, current, nil}, acc)
  ff_until "\"",        {:attrs, :open_sp},   do: ff(r,   {{:attrs, :open_dq}, current, nil}, acc)
  ff_until ">",         {:attrs, :any},       do: {all, push_attrs(current, acc)}

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

  ## Document parsing

  defp push_tag({:none, "", []}, acc), do: acc
  defp push_tag({:text, value, attrs} = tag, acc) do
    case String.strip(value) do
      "" -> acc
      _ -> [tag | acc]
    end
  end
  defp push_tag({_, _, _} = tag, acc), do: [tag | acc]

  ff_until "-->",      {:doc, :comment},   do: ff(r, @new_token, push_tag({:comment, current, attributes}, acc))


  #Reached the "<style>" ">" character, so move to css mode
  ff_until ">", {:doc, :open_style}, do: ff(r, new_token(:css), push_tag({:open_style, current, attributes}, acc))

  #For all these modes, a ">" represents a transition to a new mode
  Enum.each([:close_tag, :open_tag, :doctype], fn mode ->
    ff_until ">", {:doc, unquote(mode)}, do: ff(r, new_token(:none), push_tag({unquote(mode), current, attributes}, acc))
  end)

  Enum.each([:open_tag, :doctype, :open_style], fn mode ->
    ff_until_in @spaces, {:doc, unquote(mode)},  do: attributes(r, {unquote(mode), current, attributes}, acc)
  end)


  # CSS handling. Ignore tags between comments.
  ff_until "/*",      {:doc, :css},         do: ff(all, {{:doc, :css_comment}, current, attributes} ,acc)
  ff_until "*/",      {:doc, :css_comment}, do: ff(all, {{:doc, :css}, current, attributes} ,acc)
  ff_until "</",      {:doc, :css_comment}, do: ff(r,   {{:doc, :css_comment}, current <> "</", attributes}, acc)
  ff_until ">",       {:doc, :close_style}, do: ff(r, new_token(:none), push_tag({:close_style, current, attributes}, acc))
  ff_until "</style", {:doc, :css},         do: ff(r, new_token(:close_style), push_tag({:css, current, attributes}, acc)) 
  ff_until "<style",  {:doc, :any} do 
    {:doc, tag} = mode
    ff(r, {{:doc, :open_style}, "", []}, push_tag({tag, current, attributes}, acc))
  end


  ff_until "<!--", {:doc, :none}, do: ff(r,               {{:doc, :comment},   "", []},  acc)
  ff_until "</"  , {:doc, :none}, do: ff(String.strip(r), {{:doc, :close_tag}, "", []},  acc)
  ff_until "<!"  , {:doc, :none}, do: ff(String.strip(r), {{:doc, :doctype},   "", []},  acc)
  ff_until "<"   , {:doc, :none}, do: ff(String.strip(r), {{:doc, :open_tag},  "", []},  acc)

  # ff_until :any, {:doc, :css}, do: ff(r, {{:doc, :css}, head, []}, acc)
  ff_until :any, {:doc, :none},  do: ff(r, {{:doc, :text}, head, []}, acc)



  ff_until "<"  ,   {:doc, :any} do
    {:doc, tag} = mode
    ff(all, @new_token, push_tag({tag, current, attributes}, acc))
  end

  ff_until :any, {:doc, :any}, do: ff(r, {mode, current <> head, attributes},  acc)

  defp ff("", mode, acc) do 
    {{:doc, mode}, current, attributes} = mode
    push_tag({mode, current, attributes}, acc) |> Enum.reverse
  end


  def tokenize({text, acc}), do: ff(text, @new_token, acc)
  def tokenize(text), do: tokenize({text, []})

end
