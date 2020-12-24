defprotocol Html do
  @type t :: %{
          required(:type) => BattleCity.short_type(),
          required(:x) => integer(),
          required(:y) => integer(),
          optional(:kind) => atom(),
          optional(:d) => BattleCity.Position.direction()
        }
  @spec grid(term) :: t
  def grid(struct)
end

defimpl Html, for: BattleCity.Environment do
  @scale 32
  def grid(%{position: p, __module__: module}) do
    %{type: :e, kind: module.__name__(), x: p.x * @scale, y: p.y * @scale}
  end
end

defimpl Html, for: BattleCity.Tank do
  @scale 32
  def grid(%{position: p, __module__: module}) do
    %{type: :t, kind: module.__name__(), x: p.x * @scale, y: p.y * @scale, d: p.direction}
  end
end

defimpl Html, for: BattleCity.Bullet do
  @scale 32
  def grid(%{position: p}) do
    %{type: :b, x: p.x * @scale, y: p.y * @scale, d: p.direction}
  end
end
