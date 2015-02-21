defmodule Exquery.Mixfile do
  use Mix.Project

  def project do
    [app: :exquery,
     version: "0.0.3",
     elixir: "~> 1.0",
     description: description,
     package: package,
     deps: deps]
  end

  def application do
    [applications: [:logger]]
  end

  defp description do
    """
      A library for parsing HTML and querying elements within. Handy for web scraping or autmated testing.
    """
  end

  defp package do
    [
      files: ["lib", "README.md", "config", "LICENSE", "mix.exs"],
      contributors: ["Chris Duranti"],
      licenses: ["MIT"],
      links: %{
        "GitHub" => "https://github.com/rozap/exquery"
      }
    ]
  end

  defp deps do
    []
  end
end
