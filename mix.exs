defmodule Openstex.Mixfile do
  use Mix.Project
  @version "0.4.1"
  @elixir_versions ">= 1.4.0"
  @hackney_versions ">= 1.6.0"

  def project do
    [
      app: :openstex,
      name: "Openstex",
      version: @version,
      elixir: @elixir_versions,
      build_embedded: Mix.env() == :prod,
      start_permanent: Mix.env() == :prod,
      elixirc_paths: elixirc_paths(Mix.env()),
      source_url: "https://github.com/stephenmoloney/openstex",
      description: description(),
      package: package(),
      aliases: aliases(),
      deps: deps(),
      docs: docs()
    ]
  end

  def application do
    [
      mod: [],
      extra_applications: [:crypto, :logger]
    ]
  end

  defp deps do
    [
      # deps
      {:jason, "~> 1.0"},
      {:mapail, "~> 1.0"},
      {:httpipe, "~> 0.9"},
      {:hackney, @hackney_versions},

      # dev/test deps
      {:markdown, github: "devinus/markdown", only: [:dev], runtime: false},
      {:ex_doc, "~> 0.18", only: [:dev], runtime: false},
      {:credo, "~> 0.9.0-rc8", only: [:dev, :test], runtime: false},
      {:bypass, "~> 0.8", only: [:test]},
      {:httpipe_adapters_hackney, "~> 0.11", only: [:test]},
      {:temp, "~> 0.4", only: [:test]}
    ]
  end

  defp description do
    ~s"""
    A client in elixir for making requests to openstack compliant apis.
    """
  end

  defp package do
    %{
      licenses: ["MIT"],
      maintainers: ["Stephen Moloney"],
      links: %{"GitHub" => "https://github.com/stephenmoloney/openstex"},
      files: ~w(lib mix.exs CHANGELOG* README* LICENCE*)
    }
  end

  defp docs do
    [
      main: "Openstex",
      extras: []
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  defp aliases do
    [
      format: [
        "format #{format_args(:lib)}",
        "format #{format_args(:test)}"
      ],
      prep: [
        "clean",
        "format",
        "compile",
        "credo #{credo_args()}"
      ]
    ]
  end

  defp credo_args do
    "--strict --ignore cyclomaticcomplexity,longquoteblocks,maxlinelength"
  end

  defp format_args(:lib) do
    "mix.exs lib/**/*.{ex,exs}"
  end

  defp format_args(:test) do
    "mix.exs test/**/*.{ex,exs} test/**/**/*.{ex,exs}"
  end
end
