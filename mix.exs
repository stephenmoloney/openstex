defmodule Openstex.Mixfile do
  use Mix.Project
  @version "0.2.0"

  def project do
    [
      app: :openstex,
      name: "Openstex",
      version: @version,
      elixir: "~> 1.2",
      build_embedded: Mix.env == :prod,
      start_permanent: Mix.env == :prod,
      elixirc_paths: elixirc_paths(Mix.env),
      source_url: "https://github.com/stephenmoloney/openstex",
      description: description(),
      package: package(),
      deps: deps(),
      docs: docs()
   ]
  end

  def application() do
    [
      mod: [],
      applications: [:calendar, :crypto, :httpoison, :logger, :mapail]
    ]
  end

  defp deps() do
    [
      # Production deps
      {:poison, "~> 2.0"},
      {:httpoison, "~> 0.8.0"},
      {:calendar, "~> 0.13.2"},
      {:mapail, github: "stephenmoloney/mapail", branch: "master"},

      # Docs deps
      {:markdown, github: "devinus/markdown", only: :dev},
      {:ex_doc,  "~> 0.11", only: :dev}
    ]
  end

  defp description() do
    ~s"""
    A client in elixir for making requests to openstack compliant apis.
    """
  end

  defp package do
    %{
      licenses: ["MIT"],
      maintainers: ["Stephen Moloney"],
      links: %{ "GitHub" => "https://github.com/stephenmoloney/openstex"},
      files: ~w(lib mix.exs README* LICENCE*)
     }
  end

  defp docs() do
    [
    main: "Openstex",
    extras: [
             "docs/ovh/cloudstorage/getting_started.md": [path: "mix_task_advanced.md", title: "Getting Started (OVH Cloudstorage)"]
            ]
    ]
  end

  defp elixirc_paths(_), do: ["lib"]

end
