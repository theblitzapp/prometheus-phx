defmodule PrometheusPhx.MixProject do
  use Mix.Project

  def project do
    [
      app: :prometheus_phx,
      version: "0.1.1",
      elixir: "~> 1.8",
      build_embedded: Mix.env() == :prod,
      start_permanent: Mix.env() == :prod,
      elixirc_paths: elixirc_paths(Mix.env()),
      compilers: compilers(Mix.env()),
      deps: deps()
    ]
  end

  def application do
    [applications: [:logger, :prometheus_ex]]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  defp deps do
    [
      {:prometheus_ex, "~> 3.0"},
      {:phoenix, "~> 1.5.1", only: [:test]},
      {:phoenix_html, "~> 2.11", only: [:test]},
      {:telemetry_metrics, "~> 0.4", only: [:test]},
      {:telemetry_poller, "~> 0.4", only: [:test]},
      {:jason, "~> 1.0", only: [:test]},
      {:plug_cowboy, "~> 2.0", only: [:test]}
    ]
  end

  def compilers(:test), do: [:phoenix] ++ Mix.compilers()
  def compilers(_), do: Mix.compilers()
end
