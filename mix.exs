defmodule SignalTower.MixProject do
  use Mix.Project

  def project do
    [
      app: :signal_tower,
      version: "2.0.0",
      elixir: "~> 1.9",
      deps: deps(),
      releases: releases()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      mod: {SignalTower, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:cowboy, "~> 2.13"},
      {:poison, "~> 6.0"},
      {:prometheus_ex, "~> 4.0"},
      {:elixir_uuid, "~> 1.2"},
      {:dialyxir, "~> 1.4", only: [:dev], runtime: false},
      {:mix_test_watch, "~> 1.3", only: :dev, runtime: false}
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
