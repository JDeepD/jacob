defmodule Jacob.Scene.Home do
  use Scenic.Scene
  alias Scenic.Graph
  import Scenic.Primitives

  @cell_size 20
  @grid_width 30
  @grid_height 30

  @impl Scenic.Scene
  def init(scene, _param, _opts) do
    :timer.send_interval(120, :tick)

    initial_board = %{
      {2, 1} => :alive,
      {3, 2} => :alive,
      {1, 3} => :alive,
      {2, 3} => :alive,
      {3, 3} => :alive
    }

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

  defp next_generation(board) do
    board
      |> Map.keys()
      |> Enum.flat_map(&neighbors/1)
      |> Enum.frequencies()
      |> Enum.reduce(%{}, fn {coord, alive_count}, new_board ->
        is_alive = Map.has_key?(board, coord)
        if alive_count == 3 || (alive_count == 2 && is_alive) do
          {x, y} = coord
          if x >= 0 && x < @grid_width && y >= 0 && y < @grid_height do
            Map.put(new_board, coord, :alive)
          else
            new_board
          end
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
    total_width = @grid_width * @cell_size
    total_height = @grid_height * @cell_size

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
        |> rect({total_width, total_height}, stroke: {4, :white})

    push_graph(scene, graph)
  end
end
