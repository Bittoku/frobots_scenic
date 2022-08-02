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
      text_spec(Frobots.user_frobot_path(), t: {550, 125}),
      text_spec("FROBOTs:", translate: {15, 20}),
      button_spec("Fight!", id: :btn_run, theme: :danger, t: {370, 0}),
      button_spec("Upload Frobots", id: :btn_upload, theme: :primary, t: {370, 50}),
      text_spec("Ok!", id: :upload_status, hidden: true, t: {550, 80}),
      button_spec("Download Frobots", id: :btn_download, theme: :primary, t: {370, 100}),
      text_spec("Ok!", id: :download_status, hidden: true, t: {550, 130})
    ]
  end

  def frobot_id(x) do
    "frobot" <> Integer.to_string(x)
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
        id: frobot_id(x),
        translate: {100 * x, 100}
      )
    end)
  end

  def num_of_frobots(num) do
    dropdown_spec(
      {
        Enum.map(2..10, fn x -> {Integer.to_string(x), x} end),
        num
      },
      id: "num",
      translate: {120, 0}
    )
  end

  def add_specs(graph, num) do
    add_specs_to_graph(
      graph,
      [
        header(),
        group_spec(frobot_dropdowns(num), t: {30, 50}),
        num_of_frobots(num)
      ],
      translate: {0, @body_offset + 20}
    )
  end

  def delete_specs(graph, num) do
    Enum.reduce(0..num, graph, fn x, graph -> Graph.delete(graph, frobot_id(x)) end)
  end

  # ============================================================================
  @type t :: %{
          viewport: pid(),
          graph: Scenic.Graph.t(),
          frobots: map(),
          module: module(),
          match_id: Integer
        }
  def init(game_module, opts) do
    IO.inspect("START VIEW")
    viewport = opts[:viewport]
    num = Keyword.get(opts, :num, 2)

    ##
    # And build the final graph
    graph =
      Graph.build(font: :roboto, font_size: 24, theme: :dark)
      |> add_specs(num)

    {:ok, match_id} = Frobots.request_match()
    IO.inspect(match_id, label: "Match_id")
    state = %{
      num: num,
      viewport: viewport,
      graph: graph,
      frobots: default_frobots(),
      module: game_module,
      match_id: match_id
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
    Enum.map(frobots, fn {_name, type} ->
      # todo this needs to change once we have proper frobot unique names and not loading the template bots by default
      # this is aweful as the type is the atom version of the name.
      %{name: Atom.to_string(type)}
    end)
  end

  @spec go_to_first_scene(t()) :: :ok
  defp go_to_first_scene(%{viewport: vp, frobots: frobots, module: game_module, match_id: match_id}) do
    ViewPort.set_root(vp, {game_module, load_frobots(frobots)})
  end

  def add_default_frobots(state, num) do
    Enum.reduce(0..(num - 1), state, fn x, state ->
      put_in(state, [:frobots, frobot_id(x)], :rabbit)
    end)
  end

  defp reset_graph(state, num) do
    # set the number of frobots to be chosen to play, return the state
    graph =
      state.graph
      |> delete_specs(state.num)
      |> add_specs(num)

    state
    |> Map.put(:graph, graph)
    |> Map.put(:num, num)
    |> add_default_frobots(num)
  end

  # start the game
  def filter_event({:click, :btn_run}, _, state) do
    go_to_first_scene(state)
    {:halt, state}
  end

  def filter_event({:click, :btn_upload}, _, state) do
    # uploads the local dir frobots to the server, and then resets the graph
    Frobots.save_player_frobots()
    state = reset_graph(state, state.num)
    graph = state.graph |> Graph.modify(:upload_status, &text(&1, "Uploaded", hidden: false))
    {:halt, Map.put(state, :graph, graph), push: graph}
  end

  def filter_event({:click, :btn_download}, _, state) do
    # downloads the frobots from the server and saves it locally
    Frobots.load_player_frobots()
    graph = state.graph |> Graph.modify(:download_status, &text(&1, "Downloaded", hidden: false))
    {:halt, Map.put(state, :graph, graph), push: graph}
  end

  def filter_event({:value_changed, "num", num}, _, state) do
    state =
      cond do
        num > 1 and num <= 10 ->
          reset_graph(state, num)

        true ->
          state
      end

    {:halt, state, push: state.graph}
  end

  def filter_event({:value_changed, id, val}, _, state) do
    state = put_in(state, [:frobots, id], val)
    {:halt, state, push: state.graph}
  end
end
