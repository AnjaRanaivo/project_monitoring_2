defmodule PmLogin.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  def start(_type, _args) do
    uploads_priv_dir = PmLogin.uploads_priv_dir()
    File.mkdir_p!(uploads_priv_dir)
    children = [
      # Start the Ecto repository
      PmLogin.Repo,
      # Start the Telemetry supervisor
      PmLoginWeb.Telemetry,
      # Start the PubSub system
      {Phoenix.PubSub, name: PmLogin.PubSub},
      # Start the Endpoint (http/https)
      PmLoginWeb.Endpoint,
      PmLogin.DatabaseBackup,
      # Start a worker by calling: PmLogin.Worker.start_link(arg)
      # {PmLogin.Worker, arg}
      PmLogin.SpawnerSupervisor,
      PmLogin.SpawnerLauncher
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: PmLogin.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  def config_change(changed, _new, removed) do
    PmLoginWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
