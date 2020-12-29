defmodule BattleCity.Position do
  @moduledoc """
  Position
  """

  @type direction :: :up | :down | :left | :right

  import Integer, only: [is_even: 1]

  @size 12
  @border 4

  @atom 2
  @width @border * 2
  @xmin 0
  @xmax @size * @atom
  @ymin 0
  @ymax @size * @atom
  @xmid round((@xmin + @xmax) * 0.5)
  @x_player_1 round(@xmid - @atom - 0.5 * @atom)

  @rxmin @xmin * @width
  @rxmax @xmax * @width
  @rymin @ymin * @width
  @rymax @ymax * @width

  @x_range @xmin..@xmax
  @y_range @ymin..@ymax
  # @diretions [:up, :down, :left, :right]

  @type speed :: 1..10
  @type x :: unquote(@xmin)..unquote(@xmax)
  @type y :: unquote(@ymin)..unquote(@ymax)
  @type rx :: unquote(@rxmin)..unquote(@rxmax)
  @type ry :: unquote(@rymin)..unquote(@rymax)
  @type coordinate :: {x, y}
  @type width :: 0..unquote(@atom)
  @type height :: 0..unquote(@atom)

  @typep x_or_y :: x | y
  @typep rx_or_ry :: rx | ry

  @type path :: [coordinate]

  @type t :: %__MODULE__{
          direction: direction(),
          x: x(),
          y: y(),
          rx: rx(),
          ry: ry(),
          rt: rx_or_ry(),
          t: x_or_y(),
          path: path()
        }

  @keys [:direction, :x, :y, :rx, :ry]
  @enforce_keys [:direction, :x, :y, :rx, :ry]
  defstruct @keys ++ [:rt, :t, path: []]

  @objects for x <- @x_range,
               rem(x, 2) == 0,
               y <- @y_range,
               rem(y, 2) == 0,
               do: {{x, y}, %{}},
               into: %{}

  defguard is_on_border(p)
           when is_struct(p, __MODULE__) and
                  ((p.rx == @rxmin and p.direction == :left) or
                     (p.rx == @rxmax and p.direction == :right) or
                     (p.ry == @rymin and p.direction == :up) or
                     (p.ry == @rymax and p.direction == :down))

  defguard is_on_border_xy(p)
           when is_struct(p, __MODULE__) and
                  ((p.x == @xmin and p.direction == :left) or
                     (p.x == @xmax and p.direction == :right) or
                     (p.y == @ymin and p.direction == :up) or
                     (p.y == @ymax and p.direction == :down))

  def objects, do: @objects
  def size, do: @size
  def atom, do: @atom
  def speed, do: 1
  def bullet_speed, do: @atom
  def width, do: @width
  def quadrant, do: @size + 1
  def real_quadrant, do: quadrant() * @atom * @width
  def real_width, do: @width * @atom

  @spec init(map) :: t()
  def init(map \\ %{})
  def init(%{x: x} = map) when is_atom(x), do: init(%{map | x: fetch_x(x)})
  def init(%{y: y} = map) when is_atom(y), do: init(%{map | y: fetch_y(y)})

  def init(%{x: x, y: y} = map) do
    map =
      map
      |> Map.merge(%{rx: x * @width, ry: y * @width})
      |> Map.take(@keys)

    struct!(__MODULE__, map) |> normalize()
  end

  defp fetch_x(:x_player_1), do: @x_player_1
  defp fetch_x(:x_random_enemy), do: Enum.random([@xmin, @xmid, @xmax])
  defp fetch_x(:x_random), do: Enum.random(@x_range)
  defp fetch_y(:y_player_1), do: @ymax
  defp fetch_y(:y_random_enemy), do: @ymin
  defp fetch_y(:y_random), do: Enum.random(@y_range)

  @spec destination(t(), speed) :: t()
  def destination(%{direction: direction, x: x, y: y} = p, speed) do
    rt = target(p, speed)
    t = normalize_number(direction, div_even(rt + direction_border(direction)))

    if direction in [:up, :down] do
      %{p | ry: rt, rt: rt, t: t, path: for(i <- y..t, rem(i, 2) == 0, do: {x, i})}
    else
      %{p | rx: rt, rt: rt, t: t, path: for(i <- x..t, rem(i, 2) == 0, do: {i, y})}
    end
  end

  @doc """
    iex> #{__MODULE__}.div_even(#{@width * 3 + 0.1})
    4
    iex> #{__MODULE__}.div_even(#{@width * 3 - 0.1})
    2
    iex> #{__MODULE__}.div_even(#{@width * 4 + 0.1})
    4
    iex> #{__MODULE__}.div_even(#{@width * 5 + 0.1})
    6
    iex> #{__MODULE__}.div_even(#{@width * 5 - 0.1})
    4
  """
  @spec div_even(float) :: x_or_y
  def div_even(rt), do: round(rt / @width / @atom) * @atom

  defp direction_border(:up), do: -0.1
  defp direction_border(:down), do: 0.1
  defp direction_border(:right), do: 0.1
  defp direction_border(:left), do: -0.1

  @spec normalize(t()) :: t()
  def normalize(%__MODULE__{x: x, y: y, direction: direction} = p) do
    %{p | x: normalize_number(direction, x, :x), y: normalize_number(direction, y, :y)}
  end

  @doc """
    iex> #{__MODULE__}.normalize_number(:up, 2, :x)
    2
    iex> #{__MODULE__}.normalize_number(:up, 3)
    4
    iex> #{__MODULE__}.normalize_number(:down, 3)
    2
  """
  @spec normalize_number(direction(), x_or_y(), :x | :y | nil) :: x_or_y()
  def normalize_number(direction, n, x_or_y \\ nil)
  def normalize_number(_, n, _) when is_even(n), do: n
  def normalize_number(:right, n, :x), do: n + 1
  def normalize_number(:right, n, nil), do: n + 1
  def normalize_number(:up, n, :y), do: n + 1
  def normalize_number(:up, n, nil), do: n + 1
  def normalize_number(_, n, _), do: n - 1

  @doc """
    iex> #{__MODULE__}.target(%{direction: :right, rx: 0}, 2)
    2
    iex> #{__MODULE__}.target(%{direction: :left, rx: 1}, 2)
    0
    iex> #{__MODULE__}.target(%{direction: :up, ry: 3}, 2)
    1
  """
  @spec target(t(), speed) :: rx_or_ry
  def target(%{direction: :right, rx: rx}, speed) when rx + speed <= @rxmax, do: rx + speed
  def target(%{direction: :right}, _), do: @rxmax
  def target(%{direction: :left, rx: rx}, speed) when rx - speed >= 0, do: rx - speed
  def target(%{direction: :left}, _), do: 0
  def target(%{direction: :up, ry: ry}, speed) when ry - speed >= 0, do: ry - speed
  def target(%{direction: :up}, _), do: 0
  def target(%{direction: :down, ry: ry}, speed) when ry + speed <= @rymax, do: ry + speed
  def target(%{direction: :down}, _), do: @rymax

  @spec target_path(t(), direction) :: path
  def target_path(%{x: x, y: y}, :left),
    do: for(i <- x..@xmin, i != x, rem(i, 2) == 0, do: {i, y})

  def target_path(%{x: x, y: y}, :right),
    do: for(i <- x..@xmax, i != x, rem(i, 2) == 0, do: {i, y})

  def target_path(%{x: x, y: y}, :up),
    do: for(i <- y..@ymin, i != y, rem(i, 2) == 0, do: {x, i})

  def target_path(%{x: x, y: y}, :down),
    do: for(i <- y..@ymax, i != y, rem(i, 2) == 0, do: {x, i})
end
