defmodule FrobotsScenic.Scene.Start do
  @moduledoc """
  Sample scene.
  """
  use Scenic.Scene
  alias Scenic.Graph
  alias Scenic.ViewPort
  import Scenic.Primitives
  import Scenic.Components
  alias Frobots

  @body_offset 60
  def header() do
    [
      text_spec("FUBARs", translate: {15, 20}),
      # this button will cause the scene to crash.
      button_spec("Fight!", id: :btn_run, theme: :danger, t: {370, 0})
    ]
  end

  ##
  # Now the specs for the various components we'll display
  def frobot_dropdowns(n) do
    frobot_types = Frobots.frobot_types()

    Enum.map(0..(n - 1), fn x ->
      dropdown_spec(
        {
          frobot_types,
          :rabbit
        },
        id: "frobot" <> Integer.to_string(x),
        translate: {100 * x, 0}
      )
    end)
  end

  # ============================================================================
  @type t :: %{
          viewport: pid(),
          graph: Scenic.Graph.t(),
          frobots: map(),
          module: module()
        }
  def init(game_module, opts) do
    viewport = opts[:viewport]

    ##
    # And build the final graph
    graph =
      Graph.build(font: :roboto, font_size: 24, theme: :dark)
      |> add_specs_to_graph(
        [
          header(),
          group_spec(frobot_dropdowns(5), t: {15, 74})
        ],
        translate: {0, @body_offset + 20}
      )

    state = %{
      viewport: viewport,
      graph: graph,
      frobots: default_frobots(),
      module: game_module
    }

    {:ok, state, push: graph}
  end

  def default_frobots() do
    %{
      "frobot0" => :rabbit,
      "frobot1" => :rabbit
    }
  end

  @spec load_frobots(map()) :: list()
  def load_frobots(frobots) do
    Enum.map(frobots, fn {name, type} ->
      # todo this needs to change once we have proper frobot unique names and not loading the template bots by default
      # this is aweful as the type is the atom version of the name.
      %{name: Atom.to_string(type), type: "Basic"}
    end)
  end

  @spec go_to_first_scene(t()) :: :ok
  defp go_to_first_scene(%{viewport: vp, frobots: frobots, module: game_module}) do
    ViewPort.set_root(vp, {game_module, load_frobots(frobots)})
  end

  defp test_start_button(%{viewport: _vp, frobots: frobots, module: _game_module}) do
    IO.puts(inspect(frobots))
  end

  # start the game
  def filter_event({:click, :btn_run}, _, state) do
    go_to_first_scene(state)
    # test_start_button(state)
    {:halt, state}
  end

  def filter_event({:value_changed, dropdown, val}, _, state) do
    state = put_in(state, [:frobots, dropdown], val)
    {:halt, state, push: state.graph}
  end
end
