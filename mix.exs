defmodule SignalTower.Mixfile do
  use Mix.Project

  def project do
    [
      app: :signal_tower,
      version: "1.0.0",
      elixir: "~> 1.3",
      deps: deps()
    ]
  end

  # Configuration for the OTP application
  #
  # Type `mix help compile.app` for more information
  def application do
    [
      mod: { SignalTower, [] },
      applications: [:logger, :cowboy, :poison]
    ]
  end

  # Dependencies can be Hex packages:
  #
  #   {:mydep, "~> 0.3.0"}
  #
  # Or git/path repositories:
  #
  #   {:mydep, git: "https://github.com/elixir-lang/mydep.git", tag: "0.1.0"}
  #
  # Type `mix help deps` for more examples and options
  defp deps do
    [
      {:cowboy, "~> 1.1.2"},
      {:poison, "~> 3.0.0"},
      {:distillery, "~> 1.3.5"}
    ]
  end
end
