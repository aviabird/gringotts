defmodule Gringotts.Mixfile do
  use Mix.Project

  def project do
    [
      app: :gringotts,
      version: "1.1.1-rc",
      description: description(),
      package: [
        contributors: ["Aviabird Technologies"],
        maintainers: ["Pankaj Rawat"],
        licenses: ["MIT"],
        links: %{github: "https://github.com/aviabird/gringotts"}
      ],
      elixir: ">= 1.5.3",
      test_coverage: [
        tool: ExCoveralls
      ],
      elixirc_paths: elixirc_paths(Mix.env()),
      preferred_cli_env: [
        coveralls: :test,
        "coveralls.detail": :test,
        "coveralls.json": :test,
        "coveralls.html": :test,
        vcr: :test,
        "vcr.delete": :test,
        "vcr.check": :test,
        "vcr.show": :test
      ],
      deps: deps(),
      docs: docs()
    ]
  end

  # Configuration for the OTP application
  #
  # Type `mix help compile.app` for more information
  def application do
    [
      applications: [:httpoison, :hackney, :elixir_xml_to_map, :timex]
    ]
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(:dev), do: ["lib", "test/support/fake_money.ex"]
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
      {:poison, "~> 3.1.0"},
      {:httpoison, "~> 1.1"},
      {:xml_builder, "~> 2.1"},
      {:elixir_xml_to_map, "~> 0.1"},

      # money related
      {:decimal, "~> 1.5"},

      # docs and tests
      {:ex_doc, "~> 0.18", only: :dev, runtime: false},
      {:mock, "~> 0.3.0", only: :test},
      {:bypass, "~> 0.8", only: :test},
      {:excoveralls, "~> 0.8", only: :test},
      {:exvcr, "~> 0.10", only: :test},

      # various analyses tools
      {:credo, "~> 0.9", only: [:dev, :test]},
      {:inch_ex, "~> 0.5", only: :docs},
      {:dialyxir, "~> 0.3", only: :dev},
      {:timex, "~> 3.2"}
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
