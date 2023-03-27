defmodule PmLogin.Repo.Migrations.UpdateClientsRequestsTable do
  use Ecto.Migration

  def change do
    alter table("clients_requests") do
      add :is_urgent, :boolean, default: false
      add :tool_id, references("tools")
      add :deadline, :naive_datetime
    end
  end
end
