defmodule PmLogin.Repo.Migrations.DropFieldToolGroup do
  use Ecto.Migration

  def change do
    alter table("tool_groups") do
      remove :active_client_id, :id
    end
  end
end
