defmodule HANotifier.MixProject do
  use Mix.Project

  def project do
    [
      app: :ha_notifier,
      version: "0.1.0",
      elixir: "~> 1.17",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger, :dbus],
      mod: {HANotifier.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:jason, "~> 1.4.4"},
      {:dbus, "~> 0.8.0"}
    ]
  end
end