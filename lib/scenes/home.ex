defmodule Jacob.Scene.Home do
  use Scenic.Scene
  alias Scenic.Graph
  import Scenic.Primitives

  @cell_size 8
  @grid_width 500 / @cell_size
  @grid_height 500 / @cell_size

  @impl Scenic.Scene
  def init(scene, _param, _opts) do
    :timer.send_interval(150, :tick)
    pattern_path = Path.join(["patterns", "vacuum-gun.txt"])
    pattern_string = File.read!(pattern_path)
    IO.puts("Loaded pattern:\n#{pattern_string}")
    initial_board = parse_pattern(pattern_string)

    # initial_board = @diehard
    scene =
      scene
      |> assign(board: initial_board)
      |> render()

    {:ok, scene}
  end

  @impl GenServer
  def handle_info(:tick, scene) do
    new_board = next_generation(scene.assigns.board)
    scene = scene |> assign(board: new_board) |> render()
    {:noreply, scene}
  end

  defp parse_pattern(text) do
    lines = String.split(String.trim(text), "\n")
    for {line, y} <- Enum.with_index(lines), {char, x} <- Enum.with_index(String.graphemes(line)), char == "O", into: %{} do
      {{x, y}, :alive}
    end
  end

  defp next_generation(board) do
    board
      |> Map.keys()
      |> Enum.flat_map(&neighbors/1)
      |> Enum.frequencies()
      |> Enum.reduce(%{}, fn {coord, alive_count}, new_board ->
        is_alive = Map.has_key?(board, coord)
        if alive_count == 3 || (alive_count == 2 && is_alive) do
          Map.put(new_board, coord, :alive)
          # spawn_inside_bounds(new_board, coord)
        else
          new_board
        end
      end )
  end

  defp neighbors({x, y}) do
    [
      {x - 1, y - 1}, {x, y - 1}, {x + 1, y - 1},
      {x - 1, y},                     {x + 1, y},
      {x - 1, y + 1}, {x, y + 1}, {x + 1, y + 1}
    ]
  end

  defp render(scene) do
    board = scene.assigns.board

    base_graph =
      Graph.build()
      |> rect({@grid_width * @cell_size, @grid_height * @cell_size}, fill: :black)

    graph =
      Enum.reduce(board, base_graph, fn {{x, y}, state}, acc_graph ->
        color = if state == :alive, do: :green, else: :dark_gray

        acc_graph
        |> rect({@cell_size - 1, @cell_size - 1},
          fill: color,
          translate: {x * @cell_size, y * @cell_size}
        )
      end)

    push_graph(scene, graph)
  end
end
