defmodule PmLogin.Repo.Migrations.AddFieldFinishedToClientsRequests do
  use Ecto.Migration

  def change do
    alter table("clients_requests") do
      add :finished, :boolean
    end
  end
end
