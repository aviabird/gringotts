defmodule Kuber.Hex.Mixfile do
  use Mix.Project
  
  def project do
    [app: :kuber_hex,
     version: "0.0.2",
     description: "Credit card processing library",
     package: [
       contributors: ["Aviabird Technologies"],
       licenses: ["MIT"],
       links: %{github: "https://github.com/github/kuber_hex"}
     ],
     elixir: ">= 1.2.0",
     deps: deps()]
  end

  # Configuration for the OTP application
  #
  # Type `mix help compile.app` for more information
  def application do
    [applications: [:httpoison, :hackney, :elixir_xml_to_map],
     mod: {Kuber.Hex.Application, []}]
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
    [{:poison, "~> 3.1.0"},
     {:httpoison, "~> 0.13"},
     {:ex_doc, "~> 0.16", only: :dev, runtime: false},
     {:mock, "~> 0.3.0", only: :test},
     {:bypass, "~> 0.8", only: :test},
     {:xml_builder, "~> 0.1.1"}, 
     {:elixir_xml_to_map, "~> 0.1"}]
  end
end
