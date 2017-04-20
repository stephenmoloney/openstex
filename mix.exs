defmodule Openstex.Mixfile do
  use Mix.Project
  @version "0.3.5"
  @elixir "~> 1.4 or ~> 1.5"

  def project do
    [
      app: :openstex,
      name: "Openstex",
      version: @version,
      elixir: @elixir,
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
      applications: [:crypto, :hackney, :logger, :mapail]
    ]
  end

  defp deps() do
    [
      # deps
      {:poison, "~> 1.5 or ~> 2.0 or ~> 3.0"},
      {:mapail, "~> 1.0"},
      {:httpipe, "~> 0.9"},

      # dev deps
      {:markdown, github: "devinus/markdown", only: [:dev]},
      {:ex_doc,  "~> 0.14", only: [:dev]},

      # test deps
      {:bypass, "~> 0.6", only: [:test]},
      {:httpipe_adapters_hackney, "~> 0.10", only: [:test]},
      {:temp, "~> 0.4", only: [:test]}
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
      files: ~w(lib mix.exs CHANGELOG* README* LICENCE*)
     }
  end

  defp docs() do
    [
    main: "Openstex",
    extras: []
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

end
