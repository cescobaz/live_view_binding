defmodule LiveViewBinding.MixProject do
  use Mix.Project

  def project do
    [
      app: :live_view_binding,
      version: "0.1.0",
      elixir: "~> 1.14",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  # Run "mix help compile.app" to learn about applications.
  def application do
    app = [
      extra_applications: [:logger]
    ]

    if Mix.env() == :test do
      [{:mod, {LiveViewBindingTest.Application, []}} | app]
    else
      app
    end
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      # {:dep_from_hexpm, "~> 0.3.0"},
      # {:dep_from_git, git: "https://github.com/elixir-lang/my_dep.git", tag: "0.1.0"}
      {:phoenix_live_view, "~> 0.18.11"},
      {:floki, ">= 0.30.0", only: :test},
      {:jason, "~> 1.0", only: :test}
    ]
  end
end
