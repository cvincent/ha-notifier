defmodule HANotifier.Application do
  require Logger
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    port = Application.fetch_env!(:ha_notifier, :port)

    children = [
      {HANotifier.Listener, port},
      HANotifier.LibnotifyNotifier
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: HANotifier.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
