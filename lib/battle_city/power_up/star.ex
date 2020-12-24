defmodule BattleCity.PowerUp.Star do
  @moduledoc false

  use BattleCity.PowerUp

  @impl true
  def handle_on(%Context{}, %Tank{__module__: module} = tank) do
    case module.handle_level_up(tank) do
      nil ->
        tank

      new_module ->
        %{tank | __module__: new_module, meta: new_module.init([])}
    end
  end
end
