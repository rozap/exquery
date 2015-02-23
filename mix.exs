defmodule Exquery.Mixfile do
  use Mix.Project

  @version "0.0.6"

  def project do
    [
      app: :exquery,
      version: @version,
      elixir: "~> 1.0",
      description: description,
      package: package,
      deps: deps,
      docs: [
        readme: "README.md", main: "README",
        source_ref: "v#{@version}",
        source_url: "https://github.com/rozap/exquery"
      ]
   ]
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
    [
      {:earmark, "~> 0.1.13"},
      {:ex_doc, "~> 0.7"}
    ]
  end
end
