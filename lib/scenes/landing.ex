defmodule FrobotsScenic.Scene.Landing do
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
  @login_cache ~s|#{Frobots.user_frobot_path()}/login.cache|

  def header() do
    [
      text_spec("Username:", t: {15, 40}),
      text_spec("Password:", t: {15, 80}),
      text_field_spec("", id: :username, t: {150, 20}),
      text_field_spec("", id: :password, type: :password, t: {150, 60}),
      text_spec("Ok!", id: :login_status, hidden: true, t: {550, 80}),
      button_spec("Login", id: :btn_login, theme: :primary, t: {400, 100})
    ]
  end

  def add_specs(graph) do
    add_specs_to_graph(
      graph,
      [
        header()
      ],
      translate: {0, @body_offset + 20}
    )
  end

  # ============================================================================
  @type t :: %{
          viewport: pid(),
          graph: Scenic.Graph.t(),
          module: module(),
          username: charlist(),
          password: charlist()
        }

  def put_env(token) do
    Application.put_env(:frobots, :bearer_token, token)
  end

  def jump_to_start() do
    Process.send_after(self(), :start, 500)
  end

  def init(start_module, opts) do
    IO.inspect("LANDING VIEW")
    viewport = opts[:viewport]

    ##
    # And build the final graph
    graph =
      Graph.build(font: :roboto, font_size: 24, theme: :dark)
      |> add_specs()

    state = %{
      viewport: viewport,
      graph: graph,
      module: start_module,
      username: "",
      password: ""
    }

    case File.read(@login_cache) do
      {:ok, admin_pass} ->
        with %{"username" => username, "pass" => pass} <-
               Regex.named_captures(~r/(?<username>.+):(?<pass>.+)/, admin_pass) do
          client = Frobots.ApiClient.login_client(username, pass)

          case Frobots.ApiClient.get_token(client) do
            {:ok, token} ->
              put_env(token)
              go_to_start_scene(state)
              state

            _ ->
              state
          end
        end

      {:error, _} ->
        state
    end

    {:ok, state, push: graph}
  end

  @spec go_to_start_scene(t()) :: :ok
  def go_to_start_scene(%{viewport: vp, module: start_module}) do
    ViewPort.set_root(vp, {start_module, FrobotsScenic.Scene.Game})
  end

  def filter_event({:click, :btn_login}, _, state) do
    client = Frobots.ApiClient.login_client(state.username, state.password)

    print_error = fn code, msg, state ->
      state.graph
      |> Graph.modify(:login_status, &text(&1, ~s|status #{code}: #{msg}|, hidden: false))
    end

    case Frobots.ApiClient.get_token(client) do
      {:error, 401 = code} ->
        graph = print_error.(code, "Invalid Username/Password", state)
        {:halt, Map.put(state, :graph, graph), push: graph}

      {:error, code} ->
        graph = print_error.(code, "Unhandled Error", state)
        {:halt, Map.put(state, :graph, graph), push: graph}

      {:ok, token} ->
        File.write(@login_cache, ~s|#{state.username}:#{state.password}|)
        # launch to the start
        put_env(token)
        go_to_start_scene(state)
        {:halt, state}
    end
  end

  def filter_event({:value_changed, :password, val}, _, state) do
    state = Map.put(state, :password, val)
    {:halt, state, push: state.graph}
  end

  def filter_event({:value_changed, :username, val}, _, state) do
    state = Map.put(state, :username, val)
    {:halt, state, push: state.graph}
  end
end
