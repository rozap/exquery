defmodule Exquery do

  @spaces [" ", "\n", "\t", "\r"]

  defp push_token({:text, text, attrs} = token, acc) do
    case String.strip(text) do
      "" -> acc
      _ -> [token | acc]
    end
  end
  defp push_token(token, acc), do: [token | acc]



  def to_attributes("'"  <> r, :open_sq, acc, attrs),     do: to_attributes(r, [acc | attrs])
  def to_attributes("\"" <> r, :open_dq, acc, attrs),     do: to_attributes(r, [acc | attrs])
  def to_attributes(" "  <> r, :open_sp, acc, attrs),     do: to_attributes(r, [acc | attrs])

  def to_attributes("="  <> r, :key, acc, attrs),         do: to_attributes(r, :open_sp,  acc, attrs)
  def to_attributes(" "  <> r, :key, acc, attrs),         do: to_attributes(r, [acc | attrs])
  def to_attributes(" "  <> r, :open_key, acc, attrs),    do: to_attributes(r, :open_key, acc, attrs)
  def to_attributes(r        , :open_key, acc, attrs),    do: to_attributes(r, :key,      acc, attrs)

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
    ff({tag, text, attrs}, r, acc)
  end


  defp ff({:comment,   _, _} = token, "-->" <> r, acc), do: {r, push_token(token, acc)}
  defp ff({:close_tag, _, _} = token, ">"   <> r, acc), do: {r, push_token(token, acc)}
  defp ff({:open_tag,  _, _} = token, " "   <> r, acc), do: attributes(r, token, acc)
  defp ff({:doctype,   _, _} = token, " "   <> r, acc), do: attributes(r, token, acc)
  defp ff({:open_tag,  _, _} = token, ">"   <> r, acc), do: {r, push_token(token, acc)}
  defp ff({:doctype,   _, _} = token, ">"   <> r, acc), do: {r, push_token(token, acc)}


  defp ff(token, "<" <> _ = r, acc), do: {r, push_token(token, acc)}

  defp ff({kind, contents, attrs}, <<head::binary-size(1), rest::binary>>, acc) do
    ff({kind, contents <> head, attrs}, rest, acc)
  end

  defp ff(token, the_end, acc) do
    {the_end, push_token(token, acc)}
  end

  defp tok("<!--" <> r, acc), do: tokenize(ff({:comment,   "", []}, r, acc))
  defp tok("</"   <> r, acc), do: tokenize(ff({:close_tag, "", []}, String.strip(r), acc))
  defp tok("<!"   <> r, acc), do: tokenize(ff({:doctype,   "", []}, String.strip(r), acc))
  defp tok("<"    <> r, acc), do: tokenize(ff({:open_tag,  "", []}, String.strip(r), acc))
  defp tok(<<head::binary-size(1), r::binary>>, acc) do
    tokenize(ff({:text, head, []}, r, acc))
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
