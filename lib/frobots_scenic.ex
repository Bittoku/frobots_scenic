defmodule FrobotsScenic do
  @moduledoc """
  Starter application using the Scenic framework.
  """

  def start(_type, _args) do
    # load the viewport configuration from config
    main_viewport_config = Application.get_env(:frobots_scenic, :viewport)
    # action_viewport_config = Application.get_env(:frobots_scenic, :action_viewport)

    # start the application with the viewport
    children = [
      Supervisor.child_spec({Scenic, viewports: [main_viewport_config]}, id: :main_scenic)
      # Supervisor.child_spec({Scenic, viewports: [action_viewport_config]}, id: :action_scenic)
      # {Scenic, viewports: [main_viewport_config], name: :main_scenic},
      # {Scenic, viewports: [action_viewport_config], name: :action_scenic}
    ]

    Supervisor.start_link(children, strategy: :one_for_one)
  end
end
