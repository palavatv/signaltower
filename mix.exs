defmodule SignalTower.MixProject do
  use Mix.Project

  def project do
    [
      app: :signal_tower,
      version: "1.1.0",
      elixir: "~> 1.9",
      deps: deps(),
      releases: releases()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      mod: {SignalTower, []},
      applications: [:logger, :cowboy, :poison, :prometheus_ex]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:cowboy, "~> 2.6.0"},
      {:poison, "~> 4.0.1"},
      {:prometheus_ex, "~> 3.0"}
    ]
  end

  defp releases do
    [
      staging: [
        include_executables_for: [:unix],
        applications: [runtime_tools: :permanent]
      ],
      production: [
        include_executables_for: [:unix],
        applications: [runtime_tools: :permanent]
      ]
    ]
  end
end
