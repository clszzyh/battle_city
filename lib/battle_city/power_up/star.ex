defmodule BattleCity.PowerUp.Star do
  @moduledoc false

  use BattleCity.PowerUp

  @impl true
  def handle_add(%Context{} = ctx, %Tank{__module__: module} = tank) do
    tank =
      case module.handle_level_up(tank) do
        nil ->
          tank

        new_module ->
          %{tank | __module__: new_module, meta: new_module.init([])}
      end

    {ctx, tank}
  end
end
