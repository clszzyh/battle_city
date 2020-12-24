defmodule BattleCity.Debugger do
  @moduledoc false
  defmacro __using__(_opts) do
    quote do
      require IEx
      # credo:disable-for-next-line
      "-" |> String.duplicate(:io.columns() |> elem(1)) |> IO.write()
      # credo:disable-for-next-line
      IO.inspect(binding(), pretty: true)
      # credo:disable-for-next-line
      "-" |> String.duplicate(:io.columns() |> elem(1)) |> IO.write()
      # credo:disable-for-next-line
      IEx.pry()
    end
  end

  def print_ctx(ctx, label, extra \\ nil)

  def print_ctx(ctx, label, id) when is_binary(id) do
    IO.puts(
      "[#{label}] #{ctx.slug}, bullets: #{Enum.count(ctx.bullets)}, counter: #{
        inspect(ctx.__counters__)
      }, tank: #{ctx |> BattleCity.Context.fetch_object(:tanks, id) |> inspect}"
    )
  end

  def print_ctx(ctx, label, extra) do
    IO.puts(
      "[#{label}] #{ctx.slug}, bullets: #{Enum.count(ctx.bullets)}, counter: #{
        inspect(ctx.__counters__)
      }, extra: #{inspect(extra)}"
    )
  end
end
