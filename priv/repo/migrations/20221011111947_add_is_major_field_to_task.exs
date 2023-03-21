defmodule PmLogin.Repo.Migrations.AddIsMajorFieldToTask do
  use Ecto.Migration

  def change do
    alter table("tasks") do
      add :is_major, :boolean, default: false
    end
  end
end
