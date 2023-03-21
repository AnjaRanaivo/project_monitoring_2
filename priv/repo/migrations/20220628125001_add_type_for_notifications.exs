defmodule PmLogin.Repo.Migrations.AddTypeForNotifications do
  use Ecto.Migration

  def change do
    alter table("notifications") do
      add :notifications_type_id, references("notifications_type")
    end
  end
end
