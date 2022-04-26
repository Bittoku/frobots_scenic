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

  @frobot_paths Frobots.frobot_paths()
  @body_offset 60
  @frobot_types Frobots.frobot_types()
  @header [
    text_spec("FUBARs", translate: {15, 20}),
    # this button will cause the scene to crash.
    button_spec("Fight!", id: :btn_run, theme: :danger, t: {370, 0})
  ]

  ##
  # Now the specs for the various components we'll display
  @dropdowns [
    dropdown_spec(
      {
        @frobot_types,
        :rabbit
      },
      # this will be some unique NFT name eventually
      id: :frobot1,
      translate: {0, 0}
    ),
    dropdown_spec(
      {
        @frobot_types,
        :rabbit
      },
      id: :frobot2,
      translate: {100, 0}
    ),
    dropdown_spec(
      {
        @frobot_types,
        :rabbit
      },
      id: :frobot3,
      translate: {200, 0}
    ),
    dropdown_spec(
      {
        @frobot_types,
        :rabbit
      },
      id: :frobot4,
      translate: {300, 0}
    ),
    dropdown_spec(
      {
        @frobot_types,
        :rabbit
      },
      id: :frobot5,
      translate: {400, 0}
    )
  ]

  ##
  # And build the final graph
  @graph Graph.build(font: :roboto, font_size: 24, theme: :dark)
         |> add_specs_to_graph(
           [
             @header,
             group_spec(@dropdowns, t: {15, 74})
           ],
           translate: {0, @body_offset + 20}
         )

  # Nav and Notes are added last so that they draw on top

  # ============================================================================
  @type t :: %{
          viewport: pid(),
          graph: Scenic.Graph.t(),
          frobots: map(),
          module: module()
        }
  def init(game_module, opts) do
    viewport = opts[:viewport]

    state = %{
      viewport: viewport,
      graph: @graph,
      frobots: %{
        frobot1: :rabbit,
        frobot2: :rabbit,
        frobot3: :rabbit,
        frobot4: :rabbit,
        frobot5: :rabbit
      },
      module: game_module
    }

    {:ok, state, push: @graph}
  end

  def default_frobots() do
    %{
      frobot1: :rabbit,
      frobot2: :rabbit,
      frobot3: :rabbit,
      frobot4: :rabbit,
      frobot5: :rabbit
    }
  end

  @spec load_frobots(map()) :: list()
  def load_frobots(frobots) do
      Enum.map(frobots, fn {name, type} ->
        #todo this needs to change once we have proper frobot unique names and not loading the template bots by default
        %{name: Atom.to_string(type), type: "Basic"}
      end)
  end

  @spec go_to_first_scene(t()) :: :ok
  defp go_to_first_scene(%{viewport: vp, frobots: frobots, module: game_module}) do
    ViewPort.set_root(vp, {game_module, load_frobots(frobots)})
  end

  # start the game
  def filter_event({:click, :btn_run}, _, state) do
    go_to_first_scene(state)
    {:halt, state}
  end

  def filter_event({:value_changed, dropdown, val}, _, state) do
    state = put_in(state, [:frobots, dropdown], val)
    {:halt, state, push: state.graph}
  end
end
