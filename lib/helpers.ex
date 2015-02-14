defmodule Exquery.Helpers do
  @spaces [" ", "\n", "\t", "\r"]

  def log(tok, mode) do
    # IO.puts "match #{inspect tok} in #{inspect mode}"
  end

  defmacro ff_until(:spaces, mode, body) do
    modes = List.wrap(mode)
    quote do
      defp ff(<<head::binary-size(1), var!(r)::binary>> = var!(all) = all, {mode, var!(current), var!(attributes)} = var!(state), var!(acc)) when head in @spaces and (mode in unquote(modes) or mode == :any) do
        u = String.at(all, 0)
        log(u, unquote(mode))
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