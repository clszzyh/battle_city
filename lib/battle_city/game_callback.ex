defmodule BattleCity.GameCallback do
  @moduledoc """
  GameCallback
  """

  alias BattleCity.Config
  alias BattleCity.Context

  @callback handle_tick(Context.t()) :: Context.t()
  @callback handle_event(Context.t(), term()) :: Context.t()

  @optional_callbacks [handle_tick: 1, handle_event: 2]

  defmacro __using__(_) do
    quote do
      @behaviour unquote(__MODULE__)
      alias BattleCity.Context
    end
  end

  def module do
    Config.get(:callback_module, nil)
  end

  def maybe_apply(method, arity, args, default_ret) do
    callback_module = module()

    if callback_module && function_exported?(callback_module, method, arity) do
      apply(callback_module, method, args)
    else
      default_ret
    end
  end

  @spec tick(Context.t()) :: Context.t()
  def tick(ctx) do
    maybe_apply(:handle_tick, 1, [ctx], ctx)
  end

  @spec event(Context.t(), term()) :: Context.t()
  def event(ctx, term) do
    maybe_apply(:handle_event, 2, [ctx, term], ctx)
  end
end
