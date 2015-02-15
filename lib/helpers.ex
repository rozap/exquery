defmodule Exquery.Helpers do
  @spaces [" ", "\n", "\t", "\r"]

  def log(tok, mode) do
    # IO.puts "match #{inspect tok} in #{inspect mode}"
  end

  defmacro ff_until_in(tokens, match_mode, body) do
    {mode_type, match_state} = match_mode
    IO.inspect match_mode
    quote do
      defp ff(<<head::binary-size(1), var!(r)::binary>> = var!(all) = all, {{unquote(mode_type), mode_state} = var!(mode), var!(current), var!(attributes)} = var!(state), var!(acc)) when (head in unquote(tokens)) and (unquote(match_state) == mode_state or unquote(match_state) == :any) do
        # u = String.at(all, 0)
        # log(u, unquote(mode))
        unquote(body[:do])
      end
    end
  end

  defmacro ff_until(:any, {mode_type, :any} = mode, body) do
    quote do
      defp ff(<<var!(head)::binary-size(1), var!(r)::binary>> = var!(all) = all, {{unquote(mode_type), _} = var!(mode), var!(current), var!(attributes)} = var!(state), var!(acc)) do
        u = String.at(all, 0)
        log(u, unquote(mode))
        unquote(body[:do])
      end
    end
  end

  defmacro ff_until(:any, mode, body) do
    quote do
      defp ff(<<var!(head)::binary-size(1), var!(r)::binary>> = var!(all) = all, {unquote(mode), var!(current), var!(attributes)} = var!(state), var!(acc)) do
        u = String.at(all, 0)
        log(u, unquote(mode))
        unquote(body[:do])
      end
    end
  end 

  defmacro ff_until(token, {mode_type, :any} = mode, body) do
    quote do
      defp ff(unquote(token) <> var!(r) = var!(all), {{unquote(mode_type), _} = var!(mode), var!(current), var!(attributes)} = var!(state), var!(acc)) do
        log(unquote(token), unquote(mode))
        unquote(body[:do])
      end
    end
  end


  defmacro ff_until(token, mode, body) do
    quote do
      defp ff(unquote(token) <> var!(r) = var!(all), {unquote(mode), var!(current), var!(attributes)} = var!(state), var!(acc)) do
        log(unquote(token), unquote(mode))
        unquote(body[:do])
      end
    end
  end
end