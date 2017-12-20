defmodule Gringotts.Mixfile do
  use Mix.Project
  
  def project do
    [
      app: :gringotts,
      version: "0.0.2",
      description: description(),
      package: [
        contributors: ["Aviabird Technologies"],
        licenses: ["MIT"],
        links: %{github: "https://github.com/aviabird/gringotts"}
      ],
      elixir: ">= 1.3.0",
      test_coverage: [
        tool: ExCoveralls
      ],
      preferred_cli_env: [
        "coveralls": :test, 
        "coveralls.detail": :test, 
        "coveralls.post": :test, 
        "coveralls.html": :test,
        "coveralls.travis": :test
      ],
      deps: deps()]
  end

  # Configuration for the OTP application
  #
  # Type `mix help compile.app` for more information
  def application do
    [
      applications: [:httpoison, :hackney, :elixir_xml_to_map],
      mod: {Gringotts.Application, []}
    ]
  end

  # Dependencies can be hex.pm packages:
  #
  #   {:mydep, "~> 0.3.0"}
  #
  # Or git/path repositories:
  #
  #   {:mydep, git: "https://github.com/elixir-lang/mydep.git", tag: "0.1"}
  #
  # Type `mix help deps` for more examples and options
  defp deps do
    [
      {:poison, "~> 3.1.0"},
      {:httpoison, "~> 0.13"},
      {:ex_doc, "~> 0.16", only: :dev, runtime: false},
      {:mock, "~> 0.3.0", only: :test},
      {:bypass, "~> 0.8", only: :test},
      {:xml_builder, "~> 0.1.1"}, 
      {:elixir_xml_to_map, "~> 0.1"},
      {:excoveralls, "~> 0.7", only: :test},
      {:credo, "~> 0.3", only: [:dev, :test]},
      {:inch_ex, only: :docs},
      {:dialyxir, "~> 0.3", only: [:dev]}
    ]
  end

  defp description do
    """
    Gringotts is a payment processing library in Elixir integrating 
    various payment gateways, this draws motivation for shopify's 
    activemerchant ruby gem.
    """
  end
end
