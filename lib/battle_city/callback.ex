defmodule BattleCity.Callback do
  @moduledoc """
  Callback
  """

  alias BattleCity.Bullet
  alias BattleCity.Context
  alias BattleCity.PowerUp
  alias BattleCity.Tank

  @typep action :: :create | :update | :delete | :damage_environment
  @typep value :: term()
  @typep non_nil_object_struct :: PowerUp.t() | Tank.t() | Bullet.t()

  @callback handle_callback(action, non_nil_object_struct, Context.t()) :: Context.t()

  @type t :: %__MODULE__{action: action, value: value}

  @enforce_keys [:action]
  defstruct [
    :action,
    :value
  ]

  defmacro __using__(_opts) do
    quote location: :keep do
      @behaviour unquote(__MODULE__)
    end
  end

  @spec handle(t(), non_nil_object_struct, Context.t()) ::
          Context.t() | Context.callback_fn()
  def handle(a, %{__struct__: module} = o, %{__global_callbacks__: callbacks} = ctx) do
    module.handle_callback(a, o, ctx)
    |> case do
      %Context{} = ctx -> ctx
      f when is_function(f) -> %{ctx | __global_callbacks__: [f | callbacks]}
    end
  end
end
