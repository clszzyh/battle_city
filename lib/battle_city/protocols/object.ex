defprotocol Object do
  @type t :: %__MODULE__{
          type: BattleCity.short_type(),
          id: BattleCity.id(),
          enemy?: boolean() | nil
        }
  @type kv :: {t, value}
  @type value :: BattleCity.Position.direction() | nil
  @enforce_keys [:type, :id]
  defstruct [:type, :id, :enemy?]

  @spec fingerprint(term) :: {t(), value()}
  def fingerprint(struct)
end

defimpl Object, for: [BattleCity.Tank, BattleCity.Bullet] do
  @type_map %{BattleCity.Tank => :t, BattleCity.Bullet => :b}
  def fingerprint(o) do
    {%Object{
       type: @type_map[o.__struct__],
       id: o.id,
       enemy?: o.enemy?
     }, o.position.direction}
  end
end

defimpl Object, for: BattleCity.PowerUp do
  def fingerprint(powerup) do
    {%Object{type: :p, id: powerup.id}, nil}
  end
end
