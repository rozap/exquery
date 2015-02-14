defmodule Exquery.Helpers do
  @spaces [" ", "\n", "\t", "\r"]

  defmacro when_space(func, modes, body) do
    quote do
      def unquote(func)(<<head::binary-size(1), var!(r)::binary>>, mode, var!(acc), var!(attrs)) when head in @spaces and mode in unquote(modes) do
        unquote(body[:do])
      end
    end
  end


  defmacro ff_until(:spaces, mode, body) do
    modes = List.wrap(mode)
    quote do
      defp ff(<<head::binary-size(1), var!(r)::binary>> = var!(all), {mode, _, _} = var!(state), var!(acc)) when head in @spaces and (mode in unquote(modes) or mode == :any) do
        unquote(body[:do])
      end
    end
  end

  defmacro ff_until(:any, :any, body) do
    quote do
      defp ff(<<var!(head)::binary-size(1), var!(r)::binary>> = var!(all), {_, _, _} = var!(state), var!(acc)) do
        unquote(body[:do])
      end
    end
  end

  defmacro ff_until(:any, mode, body) do
    quote do
      defp ff(<<var!(head)::binary-size(1), var!(r)::binary>> = var!(all), {unquote(mode), _, _} = var!(state), var!(acc)) do
        unquote(body[:do])
      end
    end
  end 

  defmacro ff_until(token, :any, body) do
    quote do
      defp ff(unquote(token) <> var!(r) = var!(all), {_, _, _} = var!(state), var!(acc)) do
        unquote(body[:do])
      end
    end
  end


  defmacro ff_until(token, mode, body) do
    quote do
      defp ff(unquote(token) <> var!(r) = var!(all), {unquote(mode), _, _} = var!(state), var!(acc)) do
        unquote(body[:do])
      end
    end
  end
end