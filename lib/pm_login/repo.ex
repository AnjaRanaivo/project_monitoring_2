defmodule PmLogin.Repo do
  use Ecto.Repo,
    otp_app: :pm_login,
    adapter: Ecto.Adapters.Postgres
end
