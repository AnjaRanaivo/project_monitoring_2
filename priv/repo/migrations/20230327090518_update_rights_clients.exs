defmodule PmLogin.Repo.Migrations.UpdateRightsClients do
  use Ecto.Migration

  def change do
    alter table("active_clients") do
      add :rights_clients_id, references("rights_clients")
    end
  end
end
