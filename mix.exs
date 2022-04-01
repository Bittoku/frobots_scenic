defmodule FrobotsScenic.MixProject do
  use Mix.Project

  def project do
    [
      app: :frobots_scenic,
      version: "0.1.0",
      elixir: "~> 1.7",
      build_embedded: true,
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      build_path: "../../_build",
      config_path: "../../config/config.exs",
      deps_path: "../../deps",
      lockfile: "../../mix.lock"
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      mod: {FrobotsScenic, []},
      extra_applications: [:crypto, :fubars, :logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:fubars, in_umbrella: true},
      {:frobots, in_umbrella: true},
      {:scenic, "~> 0.10"},
      {:scenic_driver_glfw, "~> 0.10", targets: :host}
    ]
  end
end
