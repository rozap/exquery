defmodule Exquery do
  require Exquery.Helpers
  import Exquery.Helpers
  @spaces [" ", "\n", "\t", "\r"]

  defp push_state({:text, text, attrs} = state, acc) do
    case String.strip(text) do
      "" -> acc
      _ -> [state | acc]
    end
  end
  defp push_state(state, acc), do: [state | acc]



  def to_attributes("'"  <> r, :open_sq, acc, attrs),     do: to_attributes(r, [acc | attrs])
  def to_attributes("\"" <> r, :open_dq, acc, attrs),     do: to_attributes(r, [acc | attrs])

  when_space :to_attributes, [:open_sp], do: to_attributes(r, [acc | attrs])

  def to_attributes("="  <> r, mode, acc, attrs) when mode in [:key, :close_key], do: to_attributes(r, :open_sp,  acc, attrs)


  when_space :to_attributes, [:key, :close_key], do: to_attributes(r, :close_key, acc, attrs)
  when_space :to_attributes, [:open_key],        do: to_attributes(r, :open_key,  acc, attrs)



  def to_attributes(r        , :open_key, acc, attrs),    do: to_attributes(r, :key,      acc, attrs)
  def to_attributes(r        , :close_key, acc, attrs),   do: to_attributes(r, [acc| attrs])



  def to_attributes("'"  <> r, :open_sp, acc, attrs),     do: to_attributes(r, :open_sq,  acc, attrs)
  def to_attributes("\"" <> r, :open_sp, acc, attrs),     do: to_attributes(r, :open_dq,  acc, attrs)

  def to_attributes(">" <> _ = r, _, {"", ""}, attrs), do: {r, attrs}
  def to_attributes(">" <> _ = r, _, acc,      attrs), do: {r, [acc | attrs]}
  def to_attributes("", _, {"", ""}, attrs),           do: {"", attrs}
  def to_attributes("", _, acc,      attrs),           do: {"", [acc | attrs]}

  def to_attributes(<<head::binary-size(1), rest::binary>>, :key, {key, val}, attrs) do
    to_attributes(rest, :key, {key <> head, val}, attrs)
  end
  def to_attributes(<<head::binary-size(1), rest::binary>>, val_kind, {key, val}, attrs) do
    to_attributes(rest, val_kind, {key, val <> head}, attrs)
  end
  def to_attributes(r, attrs), do: to_attributes(r, :open_key, {"", ""}, attrs)


  defp attributes(r, {tag, text, attrs} = token, acc) do
    {r, attrs} = to_attributes(r, :open_key, {"", ""}, attrs)
    ff(r, {tag, text, attrs}, acc)
  end


  ff_until "-->", :comment,   do: {r, push_state(state, acc)}
  ff_until ">"  , :close_tag, do: {r, push_state(state, acc)}
  ff_until :spaces, :open_tag,  do: attributes(r, state, acc)
  ff_until :spaces, :doctype,   do: attributes(r, state, acc)
  ff_until ">"  , :open_tag,  do: {r, push_state(state, acc)}
  ff_until ">"  , :doctype,   do: {r, push_state(state, acc)}

  ff_until "<"  , :any, do: {all, push_state(state, acc)}

  ff_until :any, :any do
    {kind, contents, attrs} = state
    ff(r, {kind, contents <> head, attrs},  acc)
  end

  defp ff(the_end, state, acc) do 
    {the_end, push_state(state, acc)}
  end

  # when_tok "<--", {:comment, "", []}

  defp tok("<!--" <> r, acc), do: tokenize(ff(r,               {:comment,   "", []},  acc))
  defp tok("</"   <> r, acc), do: tokenize(ff(String.strip(r), {:close_tag, "", []},  acc))
  defp tok("<!"   <> r, acc), do: tokenize(ff(String.strip(r), {:doctype,   "", []},  acc))
  defp tok("<"    <> r, acc), do: tokenize(ff(String.strip(r), {:open_tag,  "", []},  acc))
  defp tok(<<head::binary-size(1), r::binary>>, acc) do
    tokenize(ff(r, {:text, head, []}, acc))
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
