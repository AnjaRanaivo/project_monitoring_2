defmodule PmLogin.Repo.Migrations.AddUuidForeachClientRequests do
  use Ecto.Migration

  def change do
    alter table("clients_requests") do
      add :uuid, :binary
    end
  end
end
