defmodule FiveTwoOne.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      FiveTwoOne.Games.Registry,
      FiveTwoOne.Games.Supervisor,
      # Start the Telemetry supervisor
      FiveTwoOneWeb.Telemetry,
      # Start the Ecto repository
      FiveTwoOne.Repo,
      # Start the PubSub system
      {Phoenix.PubSub, name: FiveTwoOne.PubSub},
      # Start Finch
      {Finch, name: FiveTwoOne.Finch},
      FiveTwoOne.SfDataMffp,
      # Start the Endpoint (http/https)
      FiveTwoOneWeb.Endpoint
      # Start a worker by calling: FiveTwoOne.Worker.start_link(arg)
      # {FiveTwoOne.Worker, arg}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: FiveTwoOne.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    FiveTwoOneWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
