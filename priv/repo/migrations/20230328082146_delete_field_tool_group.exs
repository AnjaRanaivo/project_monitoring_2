defmodule PmLogin.Repo.Migrations.DeleteFieldToolGroup do
  use Ecto.Migration

  def change do
    drop constraint(:tool_groups, "tool_groups_active_client_id_fkey")
  end
end
