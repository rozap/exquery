defmodule Exquery do
  require Exquery.Helpers
  import Exquery.Helpers
  alias Exquery.Tree
  @spaces [" ", "\n", "\t", "\r", "&nbsp;"]
  #yes this doesn't handle all cases..like StYlE
  #need a better way to deal with cases
  @styles ["<style", "<STYLE"]
  @new_token {{:doc, :none}, :none, :none}

  @self_closing [
    "area",
    "base",
    "br",
    "col",
    "command",
    "embed",
    "hr",
    "img",
    "input",
    "keygen",
    "link",
    "meta",
    "param",
    "source",
    "track",
    "wbr",
    "p"
  ]

  @case_insensitive [:open_tag, :close_tag, :open_style, :close_style, :open_script, :close_script, :self_closing]


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
  ff_until "/>",        {:attrs, :any},       do: {">" <> r, push_attrs(current, acc)}
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
  defp push_tag({tag, contents, attrs}, acc) when tag in @case_insensitive do 
    contents = String.downcase(contents)
    [{tag, contents, attrs} | acc]
  end
  defp push_tag({_, _, _} = tag, acc), do: [tag | acc]

  ff_until "-->",      {:doc, :comment},   do: ff(r, @new_token, push_tag({:comment, current, attributes}, acc))


  #Reached the "<style>" ">" character, so move to css mode
  ff_until ">", {:doc, :open_style},  do: ff(r, new_token(:css), push_tag({:open_style,  current, attributes}, acc))
  ff_until ">", {:doc, :open_script}, do: ff(r, new_token(:js),  push_tag({:open_script, current, attributes}, acc))

  #For all these modes, a ">" represents a transition to a new mode
  Enum.each([:close_tag, :open_tag, :doctype, :self_closing], fn mode ->
    ff_until ">", {:doc, unquote(mode)}, do: ff(r, new_token(:none), push_tag({unquote(mode), current, attributes}, acc))
  end)

  Enum.each([:open_tag, :doctype, :open_style, :open_script, :self_closing], fn mode ->
    ff_until_in @spaces, {:doc, unquote(mode)},  do: attributes(r, {unquote(mode), current, attributes}, acc)
  end)

  Enum.each([:css_comment, :js_comment, :js_comment_sl, :js_comment_dq, :js_comment_sq], fn comment -> 
    ff_until "</", {:doc, unquote(comment)}, do: ff(r, {{:doc, unquote(comment)}, current <> "</", attributes}, acc)
    ff_until "<", {:doc, unquote(comment)},  do: ff(r, {{:doc, unquote(comment)}, current <> "<" , attributes}, acc) 
  end)


  # CSS handling. Ignore tags between comments.
  ff_until "/*", {:doc, :css},         do: ff(all, {{:doc, :css_comment}, current, attributes} ,acc)
  ff_until "*/", {:doc, :css_comment}, do: ff(all, {{:doc, :css}, current, attributes} ,acc)

  

  ff_until ">",       {:doc, :close_style}, do: ff(r, new_token(:none), push_tag({:close_style, current, attributes}, acc))
  ff_until "</style", {:doc, :css},         do: ff(r, new_token(:close_style), push_tag({:css, current, attributes}, acc))
  ff_until "<style",  {:doc, :any} do 
    {:doc, tag} = mode
    ff(r, {{:doc, :open_style}, "", []}, push_tag({tag, current, attributes}, acc))
  end

  #JS handling. Ignore tags between comments.
  ff_until "/*",   {:doc, :js},             do: ff(all, {{:doc, :js_comment},    current, attributes}, acc)
  ff_until "*/",   {:doc, :js_comment},     do: ff(all, {{:doc, :js},            current, attributes}, acc)
  ff_until "//",   {:doc, :js},             do: ff(all, {{:doc, :js_comment_sl}, current, attributes}, acc)
  ff_until "\n",   {:doc, :js_comment_sl},  do: ff(all, {{:doc, :js},            current, attributes}, acc)
  ff_until "\"",   {:doc, :js},             do: ff(r,   {{:doc, :js_comment_dq}, current <> "\"", attributes}, acc)
  ff_until "\\\"", {:doc, :js_comment_dq},  do: ff(r,   {{:doc, :js_comment_dq}, current <> "\\\"", attributes}, acc)
  ff_until "\"",   {:doc, :js_comment_dq},  do: ff(r,   {{:doc, :js}, current <> "\"", attributes}, acc)
  ff_until "\\'",  {:doc, :js_comment_sq},  do: ff(r,   {{:doc, :js_comment_sq}, current <> "\\'", attributes}, acc)
  ff_until "'",    {:doc, :js},             do: ff(r,   {{:doc, :js_comment_sq}, current <> "'", attributes}, acc)
  ff_until "'",    {:doc, :js_comment_sq},  do: ff(r,   {{:doc, :js}, current <> "'", attributes}, acc)


  ff_until "<script", {:doc, :any} do
    {:doc, tag} = mode
    ff(r, {{:doc, :open_script}, "", []}, push_tag({tag, current, attributes}, acc))
  end
  ff_until ">",        {:doc, :close_script}, do: ff(r, new_token(:none), push_tag({:close_script, current, attributes}, acc))
  ff_until "</script", {:doc, :js},           do: ff(r, new_token(:close_script), push_tag({:js, current, attributes}, acc)) 

  Enum.each(@self_closing, fn tag ->
    ff_until "<#{unquote(String.upcase(tag))}", {:doc, :none}, do: ff(r, {{:doc, :self_closing}, unquote(tag), []}, acc)
    ff_until "<#{unquote(tag)}", {:doc, :none}, do: ff(r, {{:doc, :self_closing}, unquote(tag), []}, acc)
  end)

  ff_until "<!--", {:doc, :none}, do: ff(r, {{:doc, :comment},   "", []},  acc)
  ff_until "</"  , {:doc, :none}, do: ff(r, {{:doc, :close_tag}, "", []},  acc)
  ff_until "<!"  , {:doc, :none}, do: ff(r, {{:doc, :doctype},   "", []},  acc)
  ff_until "<"   , {:doc, :none}, do: ff(r, {{:doc, :open_tag},  "", []},  acc)
  ff_until :any,   {:doc, :none}, do: ff(r, {{:doc, :text}, head, []}, acc)


  ff_until "<"  ,   {:doc, :any} do
    {:doc, tag} = mode
    ff(all, @new_token, push_tag({tag, current, attributes}, acc))
  end

  ff_until :any, {:doc, :any}, do: ff(r, {mode, current <> head, attributes},  acc)

  defp ff("", mode, acc) do 
    {{:doc, mode}, current, attributes} = mode
    push_tag({mode, current, attributes}, acc) |> Enum.reverse
  end


  @doc ~S"""
  Turns the text into a flat list of tokens. You probably want to use
  `Exquery.tree/1` if you actually want to find elements in the HTML
  tree.

  ## Examples
      iex> Exquery.tokenize("<div><input></div>")
      [{:open_tag, "div", []}, {:self_closing, "input", []}, {:close_tag, "div", []}]

      iex> Exquery.tokenize(";_;")
      [{:text, ";_;", []}]
  """
  def tokenize(text), do: ff(text, @new_token, [])


  @doc ~S"""
  Turns the text into a tree which can then be queried by the functions
  in the `Exquery.Query` module.

  A tree is a list of tuples where the first element of the tuple is an 
  HTML element, and the second element of the tuple is its children.

  An HTML is the element name (:tag, :script, :text, etc), its contents, 
  and a list of its attributes
  
  ## Examples
  
      #h1 is a child of div, and "hi" is a child of h1
      iex> Exquery.tree("<div><h1>hi</h1></div>")
      [{{:tag, "div", []}, [{{:tag, "h1", []}, [{:text, "hi", []}]}]}]

      #:text elements can't have children
      iex> Exquery.tree("something")
      [{:text, "something", []}]

      #This has no children
      iex> Exquery.tree("<div></div>")
      [{{:tag, "div", []}, []}]

  """
  def tree(text) do
    text
    |> tokenize
    |> Tree.to_tree
  end

end
