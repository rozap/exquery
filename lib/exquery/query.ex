defmodule Exquery.Query do
  import Exquery.Helpers

  defp matches?({idx, el}, spec) when is_integer(idx), do: matches?(el, spec)
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

  defp children_of({idx, {_el, children}}) when is_integer(idx), do: children
  defp children_of({idx, {_, _, _} = _el}) when is_integer(idx), do: []
  defp children_of({_, _, _}), do: []
  defp children_of({_el, children}), do: children 



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



  defp walk(tree, spec, matcher, continue) do
    case matcher.(tree, spec) do
      nil -> 
        tree
        |> Enum.map(&(children_of &1))
        |> Enum.find_value(fn children -> continue.(children, spec) end)
      el -> el
    end
  end

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
  def one(tree, spec) do
    walk(tree, spec, 
    fn(t, s) -> Enum.find(t, nil, fn el -> matches?(el, s) end) end, 
    fn(t, s) -> one(t, s) end)
  end


  defp pluck_before([], _, _, _), do: nil
  defp pluck_before([el | rest], spec, offset, acc) do
    if matches?(el, spec) do
      Enum.at(acc, offset - 1)
    else
      pluck_before(rest, spec, offset, [el | acc])
    end
  end
  defp pluck_before(tree, spec, offset), do: pluck_before(tree, spec, offset, [])


  @doc ~S"""
    Find the element before the specified element
    
    A tree is an HTML tree given from `Exquery.tree/1`
    A spec is an HTML elemement, which a three element tuple
    of the element type, contents, and attributes. 
    `<div id="foo"></div>` would look like `{:tag, "div", [{"id", "foo"}]}`

    You may pass `:any` in for the element type and element contents to select 
    any element. 

    An optional 3rd argument specifies the offset of the selected element. By default
    it is 1, but you may select an element `n` elements before to the specified element
    by passing an offset of `n`.

    Examples: 
      iex> "<div id=\"foo\"></div><div id=\"bar\"></div>" |> Exquery.tree |> Exquery.Query.before({:tag, "div", [{"id", "foo"}]})
      nil
      iex> "<div id=\"foo\"></div><div id=\"bar\"></div>" |> Exquery.tree |> Exquery.Query.before({:tag, "div", [{"id", "bar"}]})
      {{:tag, "div", [{"id", "foo"}]}, []}
      iex> "<div id=\"foo\"></div><div id=\"bar\"></div><div id=\"baz\"></div>" |> Exquery.tree |> Exquery.Query.before({:tag, "div", [{"id", "baz"}]}, 2)
      {{:tag, "div", [{"id", "foo"}]}, []}


  """
  def before([], _, _), do: nil
  def before(tree, spec, offset \\ 1) do
    walk(tree, spec, 
    fn(t, s) -> pluck_before(t, s, offset) end, 
    fn(t, s) -> before(t, s, offset) end)
  end


  defp pluck_next([], _, _), do: nil
  defp pluck_next([el | rest], spec, offset) do
    if matches?(el, spec) do
      Enum.at(rest, offset - 1)
    else
      pluck_next(rest, spec, offset)
    end
  end

  @doc ~S"""
    Find the element after the specified element
    
    A tree is an HTML tree given from `Exquery.tree/1`
    A spec is an HTML elemement, which a three element tuple
    of the element type, contents, and attributes. 
    `<div id="foo"></div>` would look like `{:tag, "div", [{"id", "foo"}]}`

    You may pass `:any` in for the element type and element contents to select 
    any element. 

    An optional 3rd argument specifies the offset of the selected element. By default
    it is 1, but you may select an element `n` elements next to the specified element
    by passing an offset of `n`.

    Examples: 
      iex> "<div id=\"foo\"></div><div id=\"bar\"></div>" |> Exquery.tree |> Exquery.Query.next({:tag, "div", [{"id", "foo"}]})
      {{:tag, "div", [{"id", "bar"}]}, []}
      iex> "<div id=\"foo\"></div><div id=\"bar\"></div>" |> Exquery.tree |> Exquery.Query.next({:tag, "div", [{"id", "bar"}]})
      nil
      iex> "<div id=\"foo\"></div><div id=\"bar\"></div><div id=\"baz\"></div>" |> Exquery.tree |> Exquery.Query.next({:tag, "div", [{"id", "foo"}]}, 2)
      {{:tag, "div", [{"id", "baz"}]}, []}


  """
  def next([], _, _), do: nil
  def next(tree, spec, offset \\ 1) do
    walk(tree, spec,
      fn(t, s) -> pluck_next(t, s, offset) end,
      fn(t, s) -> next(t, s, offset) end
    )
  end


  defp debug(tree, tag) do
    IO.puts "#{tag}:"
    unapply_ids(tree) |> Exquery.Tree.print
    tree
  end

  defp from_css(tree, {:direct, {spec, direct_spec}}, whole_spec) do

    subspec = case direct_spec do
      {:indirect, {em, _}} -> em
      {:direct, {em, _}} -> em
      em -> em
    end

    tree
    |> all(spec)
    |> Enum.map(
      fn subtree -> 
        subtree
        |> children_of
        |> Enum.filter(fn child -> matches?(child, subspec) end)
        |> from_css(direct_spec, whole_spec) 
      end)
    |> List.flatten
    |> Enum.uniq
  end

  #TODO: make this not as shitty....probably like O(n^n^n^n) or something
  defp from_css(tree, {:indirect, {spec, subspec}}, whole_spec) do
    Enum.reduce(tree, [], fn el, acc ->

      subtree = children_of(el)

      subspec_matches = if matches?(el, spec) do
        from_css(subtree, subspec, whole_spec)
      else
        []
      end

      subtree_matches = from_css(subtree, whole_spec, whole_spec)

      Enum.uniq(subspec_matches ++ subtree_matches) ++ acc

    end)
  end

  defp from_css(tree, spec, _), do: tree |> all(spec)




  def apply_ids([], acc, idx), do: {idx, acc |> Enum.reverse}
  def apply_ids([{el, children} | rest], acc, idx) do
    {idx, subtree} = apply_ids(children, [], idx)
    apply_ids(rest, [{idx, {el, subtree}} | acc], idx + 1)
  end
  def apply_ids([el | rest], acc, idx) do
    apply_ids(rest, [{idx, el} | acc], idx + 1)
  end
  def apply_ids(tree) do
    {_, res} = apply_ids(tree, [], 0)
    res
  end


  def unapply_ids([], acc), do: acc |> Enum.reverse
  def unapply_ids([{_, {el, children}} | rest], acc) do
    subtree = unapply_ids(children, [])
    unapply_ids(rest, [{el, subtree} | acc])
  end
  def unapply_ids([{_, el} | rest], acc), do: unapply_ids(rest, [el | acc])
  def unapply_ids(tree), do: unapply_ids(tree, [])



  @doc ~S"""
    Find the element by css id or class. More complex selections are a wip.

    Examples: 
      iex> "<div id=\"foo\"></div><div id=\"bar\"></div>" |> Exquery.tree |> Exquery.Query.css("#bar")
      [{{:tag, "div", [{"id", "bar"}]}, []}]
      iex> "<div id=\"foo\"></div><div id=\"bar\"></div>" |> Exquery.tree |> Exquery.Query.css("#baz")
      []
      iex> "<div id=\"foo\"></div><div id=\"bar\"></div><div class=\"baz\"></div>" |> Exquery.tree |> Exquery.Query.css(".baz")
      [{{:tag, "div", [{"class", "baz"}]}, []}]


  """
  def css(tree, selection) do
    spec = css_to_spec(selection)
    
    r = tree
    |> apply_ids
    |> from_css(spec, spec)
    |> unapply_ids
  end


  ## CSS transforms
  

  @group_identifiers [{"#", "id"}, {".", "class"}, {" ", :tag}]
  @level_identifiers [{">", :direct}, {" ", :indirect}]


  defp strip_toks(toks) do 
    toks
    |> Enum.map(&(String.strip &1))
    |> Enum.filter(&(&1 != ""))
  end

  def normalize_css(css) do
    ids = Enum.map(@level_identifiers, fn {i, _} -> i end)

    css
    |> String.split(">")
    |> strip_toks
    |> Enum.join(">")
    |> String.split(" ")
    |> strip_toks
    |> Enum.join(" ")
  end


  defp finish_qualifiers(qualifiers) do
    all = qualifiers |> Enum.reverse
    attrs = Keyword.drop(all, [:tag])

    case Keyword.get(all, :tag) do
      "" -> {:tag, :any, attrs}
      tag -> {:tag, tag, attrs}
    end
  end

  defp push_acc(acc, qualifiers) do
    [acc | qualifiers] |> finish_qualifiers
  end

  def css_to_spec("", "", qualifiers), do: finish_qualifiers(qualifiers)
  def css_to_spec("", acc, qualifiers), do: push_acc(acc, qualifiers)
  

  def css_to_spec(" " <> rest, acc, qualifiers) do
    {:indirect, {push_acc(acc, qualifiers), css_to_spec(rest)}}
  end

  def css_to_spec(">" <> rest, acc, qualifiers) do
    {:direct, {push_acc(acc, qualifiers), css_to_spec(rest)}}
  end


  Enum.each(@group_identifiers, fn {token, ident} ->
    def css_to_spec(unquote(token) <> rest, acc, qualifiers) do
      css_to_spec(rest, {unquote(ident), ""}, [acc | qualifiers])
    end
  end)

  def css_to_spec(<<head::binary-size(1), rest::binary>>, {ident, acc}, qualifiers) do
    css_to_spec(rest, {ident, acc <> head}, qualifiers)
  end


  def css_to_spec(css) do 
    css
    |> normalize_css
    |> css_to_spec({:tag, ""}, [])
  end


end