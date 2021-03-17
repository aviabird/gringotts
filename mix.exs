defmodule Gringotts.Mixfile do
  use Mix.Project

  def project do
    [
      app: :gringotts,
      version: "1.11.0",
      description: description(),
      package: [
        contributors: ["Aviabird Technologies"],
        maintainers: ["Pankaj Rawat"],
        licenses: ["MIT"],
        links: %{github: "https://github.com/aviabird/gringotts"}
      ],
      elixir: ">= 1.5.3",
      elixirc_paths: elixirc_paths(Mix.env()),
      deps: deps(),
      docs: docs()
    ]
  end

  # Configuration for the OTP application
  #
  # Type `mix help compile.app` for more information
  def application do
    [
      applications: [:httpoison, :hackney, :elixir_xml_to_map],
      extra_applications: [:decimal, :xml_builder, :hackney]
    ]
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

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
      {:httpoison, "~> 1.1"},
      {:hackney, "~> 1.9"},
      {:xml_builder, "~> 2.1"},
      {:elixir_xml_to_map, "~> 0.1"},
      {:decimal, "~> 1.5"},
      {:mock, "~> 0.3.0", only: :test},
    ]
  end

  defp description do
    """
    Gringotts is a payment processing library in Elixir integrating
    various payment gateways, and draws motivation from shopify's
    activemerchant ruby gem.
    """
  end

  defp docs do
    [
      main: "Gringotts",
      logo: "images/lg.png",
      source_url: "https://github.com/aviabird/gringotts",
      groups_for_modules: groups_for_modules()
    ]
  end

  defp groups_for_modules do
    [
      Gateways: ~r/^Gringotts.Gateways.?/
    ]
  end
end
